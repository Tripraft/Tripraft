#!/usr/bin/env python3
"""TripRaft single-file, standard-library-only evidence-first enrichment.

Reads data/catalog/tripraft_places.db by default, automatically creates an enriched
COPY (data/catalog/tripraft_places.enriched.db). Original DB remains unchanged.
Uses free Wikidata, Wikipedia and Wikimedia Commons APIs at conservative rates;
NO commercial API required, NO guaranteed comprehensive data or 100% verification.

Examples (run from project root, Python 3.10+):
    python tripraft_enrich.py countries
    python tripraft_enrich.py start --country Algeria --contact your@email.com
    python tripraft_enrich.py start --all --contact your@email.com
    python tripraft_enrich.py status
    python tripraft_enrich.py logs --lines 50
    python tripraft_enrich.py pause
    python tripraft_enrich.py resume
    python tripraft_enrich.py run --country Albania --contact your@email.com --limit 5

It tracks findings in the enriched DB, .progress.json and .events.jsonl. A
Wikidata P18 photo is associated with the matched entity; Commons category
images are NEEDS_REVIEW until manually checked for visual identity.
Avoid simultaneous writers to the same output database.
"""
from __future__ import annotations
import argparse
import csv
import contextlib
import datetime as dt
import hashlib
import html
import json
import logging
import math
import os
import random
import re
import shutil
import sqlite3
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

LOG = logging.getLogger('tripraft')
WIKIDATA = 'https://www.wikidata.org/w/api.php'
COMMONS = 'https://commons.wikimedia.org/w/api.php'
WIKIPEDIA = 'https://en.wikipedia.org/w/api.php'
QID = re.compile(r'^Q[1-9]\d*$')
IMG_EXT = re.compile(r'\.(jpe?g|png|webp|tiff?)$', re.I)
BANNED_LICENSE = re.compile(r'\bNC\b|\bND\b|NON.?COMMERCIAL|NO.?DERIV', re.I)
ALLOWED_LICENSE = re.compile(r'^(CC0|PUBLIC DOMAIN|PD[- ]|CC BY(?:-SA)?(?:[ -]?\d(?:\.\d)?)?|CC-BY(?:-SA)?(?:-[\d.]+)?)', re.I)
BANNED_FILE = re.compile(r'\b(map|plan|diagram|logo|icon|poster|flag|coat of arms|seal|drawing|painting|advertisement|portrait|model|postcard|chart)\b', re.I)
TODAY = lambda: dt.datetime.now(dt.timezone.utc).isoformat(timespec='seconds')

class TemporaryAPIError(Exception): pass
class PermanentAPIError(Exception): pass


def norm(s):
    s = unicodedata.normalize('NFKD', str(s or '')).casefold()
    s = ''.join(c for c in s if not unicodedata.combining(c))
    return re.sub(r'\s+', ' ', re.sub(r'[^a-z0-9]+', ' ', s)).strip()


def similarity(a, b):
    from difflib import SequenceMatcher
    a, b = norm(a), norm(b)
    return SequenceMatcher(None, a, b).ratio() if a and b else 0.0


def haversine(a,b,c,d):
    rad = list(map(math.radians, (a,b,c,d)))
    x = 2 * math.asin(min(1, math.sqrt(math.sin((rad[2]-rad[0])/2)**2 + math.cos(rad[0])*math.cos(rad[2])*math.sin((rad[3]-rad[1])/2)**2)))
    return 6371 * x


def clean_html(s):
    s = re.sub(r'(?is)<(script|style).*?</\1>', ' ', str(s or ''))
    return re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]*>', ' ', s))).strip()[:1000]


def wiki_claim(entity, prop):
    vals = []
    for claim in entity.get('claims',{}).get(prop,[]):
        if claim.get('rank') == 'deprecated': continue
        snak = claim.get('mainsnak',{})
        if snak.get('snaktype') != 'value': continue
        value = snak.get('datavalue',{}).get('value')
        if value is not None: vals.append(value)
    return vals


def entity_ids(entity,prop):
    return [v['id'] for v in wiki_claim(entity,prop) if isinstance(v,dict) and QID.fullmatch(str(v.get('id','')))]


def claim_str(entity,prop):
    return [v for v in wiki_claim(entity,prop) if isinstance(v,str)]


def claim_coord(entity):
    for v in wiki_claim(entity,'P625'):
        if isinstance(v,dict) and v.get('globe','').endswith('Q2'):
            try:
                lat,lon=float(v['latitude']),float(v['longitude'])
                if -90 <= lat <= 90 and -180 <= lon <= 180: return (lat,lon)
            except (ValueError, TypeError, KeyError): pass
    return None


def entity_label(e):
    return e.get('labels',{}).get('en',{}).get('value') or next((v.get('value') for v in e.get('labels',{}).values()),'')


def entity_description(e):
    return e.get('descriptions',{}).get('en',{}).get('value','')


class WikiClient:
    """Shared global throttle, on-disk cache, bounded retries and circuit breaker."""
    def __init__(self, cache_dir, contact, timeout=18, retries=3, interval=1.5, ttl_days=14, transport=None, sleeper=None):
        if not contact or ('@' not in contact and not contact.startswith('https://')):
            raise ValueError('--contact must be a reachable email or https URL for the Wikimedia User-Agent')
        self.cache = Path(cache_dir);self.cache.mkdir(parents=True,exist_ok=True)
        self.timeout=float(timeout); self.retries=int(retries); self.interval=float(interval)
        self.ttl_days=int(ttl_days); self.last_request=0.0
        self.transport = transport or self._open; self.sleep = sleeper or time.sleep
        self.ua=f'TripRaftResearchBot/1.0 ({contact}) Python-urllib/3'
        self.network_errors=0; self.network_calls=0; self.cache_hits=0
        self.blocked_until=0.0

    def _open(self, url, headers, timeout):
        req=urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req,timeout=timeout) as res:
            return res.status, dict(res.headers.items()), res.read(4_000_001)

    def get(self, endpoint, params):
        p={'format':'json','formatversion':'2','maxlag':'5', **params}
        url=endpoint+'?'+urllib.parse.urlencode(p, doseq=True)
        digest=hashlib.sha256(url.encode()).hexdigest()
        path=self.cache/(digest+'.json')
        if path.exists() and time.time()-path.stat().st_mtime < self.ttl_days*86400:
            try:
                doc=json.loads(path.read_text(encoding='utf8'))
                self.cache_hits+=1
                return doc
            except (OSError,ValueError): pass
        if time.monotonic() < self.blocked_until:
            raise TemporaryAPIError('API circuit breaker open after previous throttling')
        for attempt in range(self.retries+1):
            delta=time.monotonic()-self.last_request
            if delta < self.interval: self.sleep(self.interval-delta)
            self.last_request=time.monotonic()
            self.network_calls+=1
            try:
                code,headers,payload=self.transport(url,{'User-Agent':self.ua,'Accept':'application/json'},self.timeout)
                if code != 200: raise urllib.error.HTTPError(url,code,'request failed',headers,None)
                if len(payload)>4_000_000: raise PermanentAPIError('API response exceeds 4 MB')
                doc=json.loads(payload)
                if not isinstance(doc,dict): raise PermanentAPIError('Invalid API response')
                if 'error' in doc:
                    err=doc['error']; msg=str(err.get('info',err))
                    if err.get('code') in ('maxlag','ratelimited','readonly','readonlytext'):raise TemporaryAPIError(msg)
                    raise PermanentAPIError(msg)
                tmp=path.with_suffix('.tmp')
                tmp.write_text(json.dumps(doc,ensure_ascii=False),encoding='utf8')
                tmp.replace(path)
                return doc
            except urllib.error.HTTPError as err:
                if err.code in (401,403,404):
                    self.network_errors+=1
                    raise PermanentAPIError(f'HTTP {err.code}, access denied/not found; no retry') from err
                if err.code not in (408,425,429,500,502,503,504):
                    raise PermanentAPIError(f'HTTP {err.code}') from err
                retry_after=err.headers.get('Retry-After') if err.headers else None
                try: delay=min(180.,max(float(retry_after),0.)) if retry_after else None
                except (ValueError,TypeError): delay=None
                issue=f'HTTP {err.code}'
                if err.code == 429: self.blocked_until=time.monotonic()+min(60.,delay or 10.)
            except (urllib.error.URLError,TimeoutError,ConnectionError,OSError,TemporaryAPIError,ValueError) as err:
                issue=str(err)
                delay=None
            if attempt>=self.retries:
                self.network_errors+=1
                raise TemporaryAPIError(f'{issue}; failed after {attempt+1} attempts')
            pause=delay if delay is not None else min(90.,2**attempt*2 + random.uniform(0,0.5))
            LOG.warning('Transient API issue (%s), retry %d/%d after %.1fs',issue,attempt+1,self.retries,pause)
            self.sleep(pause)
            self.blocked_until=0.0  # only after respecting backoff
        raise AssertionError('unreachable')

    def search(self, term, limit=7):
        return self.get(WIKIDATA, {'action':'wbsearchentities','search':term,'language':'en','type':'item','limit':limit}).get('search',[])

    def entity(self,qid):
        if not QID.fullmatch(str(qid)): return None
        v=self.get(WIKIDATA,{'action':'wbgetentities','ids':qid,'languages':'en','props':'labels|descriptions|claims|sitelinks'})
        e=v.get('entities',{}).get(qid)
        return e if e and not e.get('missing') else None

    def images(self, files, thumb_width=520):
        files=list(dict.fromkeys(x for x in files if x))[:25]
        if not files:return []
        files=['File:'+re.sub(r'^(File:|Image:)', '',x, flags=re.I).replace('_',' ') for x in files]
        data=self.get(COMMONS, {'action':'query','prop':'imageinfo','titles':'|'.join(files),
             'iiprop':'url|size|extmetadata','iiurlwidth':thumb_width})
        return [p for p in data.get('query',{}).get('pages',[]) if p.get('imageinfo')]

    def category_files(self, category, limit=20):
        category=re.sub(r'^Category:', '',category,flags=re.I).strip()
        doc=self.get(COMMONS, {'action':'query','list':'categorymembers','cmtitle':'Category:'+category,
                      'cmtype':'file','cmnamespace':6,'cmlimit':min(limit,50)})
        return [p['title'] for p in doc.get('query',{}).get('categorymembers',[]) if p.get('ns')==6]

    def english_wikipedia(self, title):
        if not title:return None
        doc=self.get(WIKIPEDIA,{'action':'query','titles':title,'redirects':'1','prop':'extracts|pageprops',
                                'exintro':'1','explaintext':'1','exsentences':'3'})
        return next((p for p in doc.get('query',{}).get('pages',[]) if not p.get('missing')),None)


# Embedded read-only snapshot of all 307 action policies from TripRaft CSV.
# No additional CSV or configuration file is required at runtime.
EMBEDDED_ACTIONS = {('airports', 'id'): 'PRESERVE_ID_RELATION', ('airports', 'country_id'): 'PRESERVE_ID_RELATION', ('airports', 'state_id'): 'PRESERVE_ID_RELATION', ('airports', 'city_id'): 'PRESERVE_ID_RELATION', ('airports', 'official_name'): 'RESEARCH_VERIFY', ('airports', 'alternate_name'): 'CONDITIONAL', ('airports', 'internal_code'): 'SYSTEM_GENERATED', ('airports', 'iata_code'): 'RESEARCH_VERIFY', ('airports', 'icao_code'): 'RESEARCH_VERIFY', ('airports', 'local_airport_code'): 'CONDITIONAL', ('airports', 'latitude'): 'RESEARCH_VERIFY', ('airports', 'longitude'): 'RESEARCH_VERIFY', ('airports', 'elevation_m'): 'RESEARCH_VERIFY', ('airports', 'timezone'): 'RESEARCH_VERIFY', ('airports', 'official_website'): 'RESEARCH_VERIFY', ('airports', 'airport_type'): 'RESEARCH_VERIFY', ('airports', 'operational_status'): 'RESEARCH_VERIFY', ('airports', 'last_verified_at'): 'SYSTEM_GENERATED', ('airports', 'deleted_at'): 'SYSTEM_GENERATED', ('batch_artifacts', 'id'): 'SYSTEM_GENERATED', ('batch_artifacts', 'batch_id'): 'SYSTEM_GENERATED', ('batch_artifacts', 'artifact_type'): 'SYSTEM_GENERATED', ('batch_artifacts', 'artifact_filename'): 'SYSTEM_GENERATED', ('batch_artifacts', 'sha256'): 'SYSTEM_GENERATED', ('batch_artifacts', 'created_at'): 'SYSTEM_GENERATED', ('batch_registry', 'batch_id'): 'SYSTEM_GENERATED', ('batch_registry', 'country_id'): 'PRESERVE_ID_RELATION', ('batch_registry', 'source_filename'): 'SYSTEM_GENERATED', ('batch_registry', 'output_filename'): 'SYSTEM_GENERATED', ('batch_registry', 'input_sha256'): 'SYSTEM_GENERATED', ('batch_registry', 'processing_status'): 'SYSTEM_GENERATED', ('batch_registry', 'places_total'): 'SYSTEM_GENERATED', ('batch_registry', 'places_with_verified_summary'): 'SYSTEM_GENERATED', ('batch_registry', 'verified_photo_count'): 'SYSTEM_GENERATED', ('batch_registry', 'started_at'): 'SYSTEM_GENERATED', ('batch_registry', 'completed_at'): 'SYSTEM_GENERATED', ('batch_registry', 'notes'): 'SYSTEM_GENERATED', ('cities', 'id'): 'PRESERVE_ID_RELATION', ('cities', 'state_id'): 'PRESERVE_ID_RELATION', ('cities', 'city_name'): 'PRESERVE_NAME', ('cities', 'latitude'): 'RESEARCH_VERIFY', ('cities', 'longitude'): 'RESEARCH_VERIFY', ('cities', 'created_at'): 'SYSTEM_GENERATED', ('cities', 'tier'): 'REVIEW_BEFORE_USE', ('cities', 'locality_type'): 'RESEARCH_VERIFY', ('cities', 'timezone'): 'RESEARCH_VERIFY', ('cities', 'updated_at'): 'SYSTEM_GENERATED', ('cities', 'retired_at'): 'CONDITIONAL', ('code_reservation_events', 'id'): 'SYSTEM_GENERATED', ('code_reservation_events', 'internal_code'): 'PRESERVE_ID_RELATION', ('code_reservation_events', 'prior_status'): 'SYSTEM_GENERATED', ('code_reservation_events', 'next_status'): 'SYSTEM_GENERATED', ('code_reservation_events', 'batch_id'): 'SYSTEM_GENERATED', ('code_reservation_events', 'changed_at'): 'SYSTEM_GENERATED', ('code_reservation_events', 'notes'): 'SYSTEM_GENERATED', ('countries', 'id'): 'PRESERVE_ID_RELATION', ('countries', 'country_name'): 'PRESERVE_NAME', ('countries', 'created_at'): 'SYSTEM_GENERATED', ('countries', 'iso2'): 'RESEARCH_VERIFY', ('countries', 'iso3'): 'RESEARCH_VERIFY', ('countries', 'iso_numeric'): 'RESEARCH_VERIFY', ('countries', 'currency_code'): 'RESEARCH_VERIFY', ('countries', 'calling_code'): 'RESEARCH_VERIFY', ('countries', 'capital'): 'RESEARCH_VERIFY', ('countries', 'region'): 'VERIFIED_DERIVATION', ('countries', 'updated_at'): 'SYSTEM_GENERATED', ('countries', 'retired_at'): 'CONDITIONAL', ('data_change_log', 'id'): 'SYSTEM_GENERATED', ('data_change_log', 'batch_id'): 'SYSTEM_GENERATED', ('data_change_log', 'table_name'): 'SYSTEM_GENERATED', ('data_change_log', 'record_id'): 'PRESERVE_ID_RELATION', ('data_change_log', 'column_name'): 'SYSTEM_GENERATED', ('data_change_log', 'old_value'): 'SYSTEM_GENERATED', ('data_change_log', 'new_value'): 'VERIFIED_DERIVATION', ('data_change_log', 'change_type'): 'SYSTEM_GENERATED', ('data_change_log', 'source_id'): 'VERIFIED_DERIVATION', ('data_change_log', 'changed_at'): 'SYSTEM_GENERATED', ('data_change_log', 'notes'): 'SYSTEM_GENERATED', ('data_sources', 'id'): 'SYSTEM_GENERATED', ('data_sources', 'url'): 'RESEARCH_VERIFY', ('data_sources', 'source_title'): 'RESEARCH_VERIFY', ('data_sources', 'publisher'): 'RESEARCH_VERIFY', ('data_sources', 'authority_tier'): 'VERIFIED_DERIVATION', ('data_sources', 'published_at'): 'CONDITIONAL', ('data_sources', 'accessed_at'): 'SYSTEM_GENERATED', ('entity_aliases', 'id'): 'SYSTEM_GENERATED', ('entity_aliases', 'internal_code'): 'REVIEW_BEFORE_USE', ('entity_aliases', 'alias_name'): 'CONDITIONAL', ('entity_aliases', 'language_code'): 'VERIFIED_DERIVATION', ('entity_aliases', 'source_url'): 'RESEARCH_VERIFY', ('entity_codes', 'internal_code'): 'SYSTEM_GENERATED', ('entity_codes', 'entity_type'): 'SYSTEM_GENERATED', ('entity_codes', 'entity_table'): 'SYSTEM_GENERATED', ('entity_codes', 'entity_id'): 'PRESERVE_ID_RELATION', ('entity_codes', 'country_iso2'): 'VERIFIED_DERIVATION', ('entity_codes', 'parent_internal_code'): 'SYSTEM_GENERATED', ('entity_codes', 'allocation_status'): 'SYSTEM_GENERATED', ('entity_codes', 'source_filename'): 'SYSTEM_GENERATED', ('entity_codes', 'notes'): 'SYSTEM_GENERATED', ('festivals', 'id'): 'SYSTEM_GENERATED', ('festivals', 'place_id'): 'PRESERVE_ID_RELATION', ('festivals', 'city_id'): 'PRESERVE_ID_RELATION', ('festivals', 'festival_name'): 'CONDITIONAL', ('festivals', 'month_label'): 'CONDITIONAL', ('festivals', 'notes'): 'CONDITIONAL', ('festivals', 'source'): 'VERIFIED_DERIVATION', ('festivals', 'created_at'): 'SYSTEM_GENERATED', ('field_verifications', 'id'): 'SYSTEM_GENERATED', ('field_verifications', 'batch_id'): 'SYSTEM_GENERATED', ('field_verifications', 'entity_type'): 'SYSTEM_GENERATED', ('field_verifications', 'entity_id'): 'PRESERVE_ID_RELATION', ('field_verifications', 'entity_internal_code'): 'VERIFIED_DERIVATION', ('field_verifications', 'source_table'): 'SYSTEM_GENERATED', ('field_verifications', 'column_name'): 'SYSTEM_GENERATED', ('field_verifications', 'accepted_value'): 'VERIFIED_DERIVATION', ('field_verifications', 'source_id'): 'VERIFIED_DERIVATION', ('field_verifications', 'verification_status'): 'SYSTEM_GENERATED', ('field_verifications', 'verified_at'): 'SYSTEM_GENERATED', ('field_verifications', 'notes'): 'SYSTEM_GENERATED', ('opening_hour_exceptions', 'id'): 'SYSTEM_GENERATED', ('opening_hour_exceptions', 'place_id'): 'PRESERVE_ID_RELATION', ('opening_hour_exceptions', 'date_from'): 'RESEARCH_VERIFY', ('opening_hour_exceptions', 'date_to'): 'RESEARCH_VERIFY', ('opening_hour_exceptions', 'weekday'): 'CONDITIONAL', ('opening_hour_exceptions', 'hours_text'): 'RESEARCH_VERIFY', ('opening_hour_exceptions', 'source_id'): 'VERIFIED_DERIVATION', ('opening_hour_exceptions', 'verified_at'): 'SYSTEM_GENERATED', ('opening_hours', 'id'): 'SYSTEM_GENERATED', ('opening_hours', 'place_id'): 'PRESERVE_ID_RELATION', ('opening_hours', 'monday'): 'LEGACY_READ_ONLY', ('opening_hours', 'tuesday'): 'LEGACY_READ_ONLY', ('opening_hours', 'wednesday'): 'LEGACY_READ_ONLY', ('opening_hours', 'thursday'): 'LEGACY_READ_ONLY', ('opening_hours', 'friday'): 'LEGACY_READ_ONLY', ('opening_hours', 'saturday'): 'LEGACY_READ_ONLY', ('opening_hours', 'sunday'): 'LEGACY_READ_ONLY', ('opening_hours', 'notes'): 'LEGACY_READ_ONLY', ('photo_attributions', 'photo_id'): 'PRESERVE_ID_RELATION', ('photo_attributions', 'commons_file_page'): 'CONDITIONAL', ('photo_attributions', 'license_url'): 'RESEARCH_VERIFY', ('photo_attributions', 'attribution_text'): 'VERIFIED_DERIVATION', ('photo_attributions', 'verified_at'): 'SYSTEM_GENERATED', ('photo_attributions', 'notes'): 'CONDITIONAL', ('photos', 'id'): 'SYSTEM_GENERATED', ('photos', 'place_id'): 'PRESERVE_ID_RELATION', ('photos', 'photo_title'): 'RESEARCH_VERIFY', ('photos', 'usage_terms'): 'RESEARCH_VERIFY', ('photos', 'thumbnail_url'): 'RESEARCH_VERIFY', ('photos', 'photo_url'): 'RESEARCH_VERIFY', ('photos', 'photo_author'): 'RESEARCH_VERIFY', ('photos', 'photo_license'): 'RESEARCH_VERIFY', ('photos', 'photo_source_url'): 'RESEARCH_VERIFY', ('photos', 'photo_status'): 'SYSTEM_GENERATED', ('photos', 'is_primary'): 'SYSTEM_GENERATED', ('photos', 'sort_order'): 'SYSTEM_GENERATED', ('photos', 'commons_file_name'): 'CONDITIONAL', ('photos', 'image_width'): 'RESEARCH_VERIFY', ('photos', 'image_height'): 'RESEARCH_VERIFY', ('place_access_events', 'id'): 'SYSTEM_GENERATED', ('place_access_events', 'place_id'): 'PRESERVE_ID_RELATION', ('place_access_events', 'status'): 'RESEARCH_VERIFY', ('place_access_events', 'starts_at'): 'CONDITIONAL', ('place_access_events', 'ends_at'): 'CONDITIONAL', ('place_access_events', 'notes'): 'RESEARCH_VERIFY', ('place_access_events', 'source_id'): 'VERIFIED_DERIVATION', ('place_access_events', 'verified_at'): 'SYSTEM_GENERATED', ('place_embeddings', 'place_id'): 'PRESERVE_ID_RELATION', ('place_embeddings', 'embedding'): 'APPLICATION_RUNTIME_ONLY', ('place_embeddings', 'dims'): 'SYSTEM_GENERATED', ('place_embeddings', 'model'): 'SYSTEM_GENERATED', ('place_embeddings', 'updated_at'): 'SYSTEM_GENERATED', ('place_hours_intervals', 'id'): 'SYSTEM_GENERATED', ('place_hours_intervals', 'place_id'): 'PRESERVE_ID_RELATION', ('place_hours_intervals', 'weekday'): 'VERIFIED_DERIVATION', ('place_hours_intervals', 'opens_local'): 'RESEARCH_VERIFY', ('place_hours_intervals', 'closes_local'): 'RESEARCH_VERIFY', ('place_hours_intervals', 'spans_midnight'): 'VERIFIED_DERIVATION', ('place_hours_intervals', 'valid_from'): 'CONDITIONAL', ('place_hours_intervals', 'valid_through'): 'CONDITIONAL', ('place_hours_intervals', 'source_id'): 'VERIFIED_DERIVATION', ('place_hours_intervals', 'verified_at'): 'SYSTEM_GENERATED', ('place_ratings_provenance', 'id'): 'SYSTEM_GENERATED', ('place_ratings_provenance', 'place_id'): 'PRESERVE_ID_RELATION', ('place_ratings_provenance', 'rating_type'): 'REVIEW_BEFORE_USE', ('place_ratings_provenance', 'rating'): 'REVIEW_BEFORE_USE', ('place_ratings_provenance', 'scale_min'): 'VERIFIED_DERIVATION', ('place_ratings_provenance', 'scale_max'): 'VERIFIED_DERIVATION', ('place_ratings_provenance', 'algorithm_version'): 'SYSTEM_GENERATED', ('place_ratings_provenance', 'provider'): 'CONDITIONAL', ('place_ratings_provenance', 'review_count'): 'CONDITIONAL', ('place_ratings_provenance', 'source_id'): 'VERIFIED_DERIVATION', ('place_ratings_provenance', 'calculated_at'): 'SYSTEM_GENERATED', ('place_search_fts', 'place_name'): 'SYSTEM_GENERATED', ('place_search_fts', 'name_english'): 'SYSTEM_GENERATED', ('place_search_fts', 'ai_summary'): 'SYSTEM_GENERATED', ('place_search_fts', 'place_tip'): 'SYSTEM_GENERATED', ('place_search_fts', 'category'): 'SYSTEM_GENERATED', ('place_search_fts_config', 'k'): 'SYSTEM_GENERATED', ('place_search_fts_config', 'v'): 'SYSTEM_GENERATED', ('place_search_fts_data', 'id'): 'SYSTEM_GENERATED', ('place_search_fts_data', 'block'): 'SYSTEM_GENERATED', ('place_search_fts_docsize', 'id'): 'SYSTEM_GENERATED', ('place_search_fts_docsize', 'sz'): 'SYSTEM_GENERATED', ('place_search_fts_idx', 'segid'): 'SYSTEM_GENERATED', ('place_search_fts_idx', 'term'): 'SYSTEM_GENERATED', ('place_search_fts_idx', 'pgno'): 'SYSTEM_GENERATED', ('place_tags', 'place_id'): 'PRESERVE_ID_RELATION', ('place_tags', 'tag_id'): 'VERIFIED_DERIVATION', ('places', 'id'): 'PRESERVE_ID_RELATION', ('places', 'city_id'): 'PRESERVE_ID_RELATION', ('places', 'place_name'): 'PRESERVE_NAME', ('places', 'name_english'): 'RESEARCH_VERIFY', ('places', 'ai_summary'): 'VERIFIED_DERIVATION', ('places', 'suggested_duration'): 'RESEARCH_VERIFY', ('places', 'best_time_to_visit'): 'RESEARCH_VERIFY', ('places', 'place_tip'): 'VERIFIED_DERIVATION', ('places', 'advanced_booking'): 'RESEARCH_VERIFY', ('places', 'state_name'): 'VERIFIED_DERIVATION', ('places', 'sunrise_view'): 'CONDITIONAL', ('places', 'sunset_view'): 'CONDITIONAL', ('places', 'sunrise_time'): 'REVIEW_BEFORE_USE', ('places', 'sunset_time'): 'REVIEW_BEFORE_USE', ('places', 'cost'): 'VERIFIED_DERIVATION', ('places', 'rating_tourist_priority'): 'REVIEW_BEFORE_USE', ('places', 'rating_traveler_experience'): 'REVIEW_BEFORE_USE', ('places', 'latitude'): 'RESEARCH_VERIFY', ('places', 'longitude'): 'RESEARCH_VERIFY', ('places', 'address'): 'RESEARCH_VERIFY', ('places', 'official_website'): 'RESEARCH_VERIFY', ('places', 'rank_score'): 'REVIEW_BEFORE_USE', ('places', 'created_at'): 'SYSTEM_GENERATED', ('places', 'google_place_id'): 'NOT_ALLOWED', ('places', 'category'): 'RESEARCH_VERIFY', ('places', 'cuisine'): 'CONDITIONAL', ('places', 'price_band'): 'VERIFIED_DERIVATION', ('places', 'veg_flag'): 'CONDITIONAL', ('places', 'source'): 'VERIFIED_DERIVATION', ('places', 'updated_at'): 'SYSTEM_GENERATED', ('places', 'verification_status'): 'SYSTEM_GENERATED', ('places', 'verification_notes'): 'SYSTEM_GENERATED', ('places', 'verified_at'): 'SYSTEM_GENERATED', ('places', 'wikidata_id'): 'RESEARCH_VERIFY', ('places', 'osm_id'): 'RESEARCH_VERIFY', ('places', 'locality_type'): 'RESEARCH_VERIFY', ('places', 'access_status'): 'RESEARCH_VERIFY', ('places', 'deleted_at'): 'SYSTEM_GENERATED', ('provider_references', 'id'): 'SYSTEM_GENERATED', ('provider_references', 'entity_type'): 'SYSTEM_GENERATED', ('provider_references', 'entity_internal_code'): 'PRESERVE_ID_RELATION', ('provider_references', 'provider'): 'RESEARCH_VERIFY', ('provider_references', 'provider_entity_id'): 'RESEARCH_VERIFY', ('provider_references', 'license_notes'): 'RESEARCH_VERIFY', ('provider_references', 'last_verified_at'): 'SYSTEM_GENERATED', ('search_log', 'id'): 'SYSTEM_GENERATED', ('search_log', 'query_text'): 'APPLICATION_RUNTIME_ONLY', ('search_log', 'filters_json'): 'APPLICATION_RUNTIME_ONLY', ('search_log', 'result_count'): 'APPLICATION_RUNTIME_ONLY', ('search_log', 'clicked_place_id'): 'APPLICATION_RUNTIME_ONLY', ('search_log', 'session_id'): 'APPLICATION_RUNTIME_ONLY', ('search_log', 'expires_at'): 'SYSTEM_GENERATED', ('search_log', 'created_at'): 'APPLICATION_RUNTIME_ONLY', ('states', 'id'): 'PRESERVE_ID_RELATION', ('states', 'country_id'): 'PRESERVE_ID_RELATION', ('states', 'state_name'): 'PRESERVE_NAME', ('states', 'created_at'): 'SYSTEM_GENERATED', ('states', 'iso3166_2'): 'RESEARCH_VERIFY', ('states', 'division_type'): 'RESEARCH_VERIFY', ('states', 'updated_at'): 'SYSTEM_GENERATED', ('states', 'retired_at'): 'CONDITIONAL', ('tags', 'id'): 'SYSTEM_GENERATED', ('tags', 'tag_name'): 'VERIFIED_DERIVATION', ('ticket_price_revisions', 'id'): 'SYSTEM_GENERATED', ('ticket_price_revisions', 'place_id'): 'PRESERVE_ID_RELATION', ('ticket_price_revisions', 'visitor_type'): 'RESEARCH_VERIFY', ('ticket_price_revisions', 'amount_minor'): 'VERIFIED_DERIVATION', ('ticket_price_revisions', 'currency_code'): 'RESEARCH_VERIFY', ('ticket_price_revisions', 'original_text'): 'RESEARCH_VERIFY', ('ticket_price_revisions', 'effective_from'): 'CONDITIONAL', ('ticket_price_revisions', 'effective_to'): 'CONDITIONAL', ('ticket_price_revisions', 'source_id'): 'VERIFIED_DERIVATION', ('ticket_price_revisions', 'verified_at'): 'SYSTEM_GENERATED', ('ticket_prices', 'id'): 'SYSTEM_GENERATED', ('ticket_prices', 'place_id'): 'PRESERVE_ID_RELATION', ('ticket_prices', 'visitor_type'): 'LEGACY_READ_ONLY', ('ticket_prices', 'amount'): 'LEGACY_READ_ONLY', ('ticket_prices', 'currency_code'): 'LEGACY_READ_ONLY', ('ticket_prices', 'price_text'): 'LEGACY_READ_ONLY', ('ticket_prices', 'effective_from'): 'LEGACY_READ_ONLY', ('ticket_prices', 'source_id'): 'LEGACY_READ_ONLY', ('ticket_prices', 'verified_at'): 'LEGACY_READ_ONLY', ('unresolved_fields', 'id'): 'SYSTEM_GENERATED', ('unresolved_fields', 'batch_id'): 'SYSTEM_GENERATED', ('unresolved_fields', 'source_table'): 'SYSTEM_GENERATED', ('unresolved_fields', 'record_id'): 'PRESERVE_ID_RELATION', ('unresolved_fields', 'column_name'): 'SYSTEM_GENERATED', ('unresolved_fields', 'reason_code'): 'SYSTEM_GENERATED', ('unresolved_fields', 'details'): 'SYSTEM_GENERATED', ('verification_evidence', 'id'): 'SYSTEM_GENERATED', ('verification_evidence', 'field_verification_id'): 'PRESERVE_ID_RELATION', ('verification_evidence', 'source_id'): 'VERIFIED_DERIVATION', ('verification_evidence', 'evidence_excerpt'): 'RESEARCH_VERIFY', ('verification_evidence', 'field_value'): 'VERIFIED_DERIVATION', ('verification_evidence', 'observed_at'): 'SYSTEM_GENERATED', ('verification_evidence', 'effective_at'): 'CONDITIONAL', ('v_top_search_queries', 'query_text'): 'SYSTEM_GENERATED', ('v_top_search_queries', 'searches'): 'SYSTEM_GENERATED', ('v_top_search_queries', 'clicks'): 'SYSTEM_GENERATED'}

class Policy:
    def __init__(self):
        self.actions=EMBEDDED_ACTIONS
    def writable(self,table,col):
        return self.actions.get((table,col)) in {'RESEARCH_VERIFY','VERIFIED_DERIVATION','CONDITIONAL'}


def source(conn,url,title,publisher,tier=3):
    if not url.startswith('https://'): raise ValueError('Only https evidence source URLs')
    row=conn.execute('SELECT id FROM data_sources WHERE url=?',(url,)).fetchone()
    if row:return row[0]
    cur=conn.execute('INSERT INTO data_sources(url,source_title,publisher,authority_tier,accessed_at) VALUES(?,?,?,?,?)',
             (url,title,publisher,tier,TODAY()))
    return cur.lastrowid


def verification(conn,batch,table,record,col,value,srcid,excerpt='',notes='',status='verified'):
    cur=conn.execute('''INSERT INTO field_verifications
     (batch_id,entity_type,entity_id,source_table,column_name,accepted_value,source_id,verification_status,verified_at,notes)
     VALUES(?,?,?,?,?,?,?,?,?,?)''',
     (batch,table[:-1].upper(),record,table,col,str(value),srcid,status,TODAY(),notes))
    if srcid:
        conn.execute('''INSERT INTO verification_evidence(field_verification_id,source_id,evidence_excerpt,field_value,observed_at)
             VALUES(?,?,?,?,?)''',(cur.lastrowid,srcid,str(excerpt)[:300],str(value),TODAY()))


def unresolved(conn,batch,table,rec,col,reason,detail):
    conn.execute('''INSERT INTO unresolved_fields(batch_id,source_table,record_id,column_name,reason_code,details)
       VALUES(?,?,?,?,?,?) ON CONFLICT(batch_id,source_table,record_id,column_name)
       DO UPDATE SET reason_code=excluded.reason_code,details=excluded.details''',
       (batch,table,rec,col,reason,str(detail)[:500]))


def update_if_empty(conn,pol,batch,table,rec,col,val,srcid,url='',why='',quality='verified'):
    if val is None or val=='':return False
    if not pol.writable(table,col): return False
    old=conn.execute(f'SELECT {col} FROM {table} WHERE id=?',(rec,)).fetchone()
    if old is None:return False
    if old[0] not in (None,''):
        if str(old[0])!=str(val):
            unresolved(conn,batch,table,rec,col,'EXISTING_VALUE_CONFLICT',f'Existing {str(old[0])[:130]!r}; candidate {str(val)[:130]!r}; {url}')
        return False
    conn.execute(f'UPDATE {table} SET {col}=? WHERE id=?',(val,rec))
    verification(conn,batch,table,rec,col,val,srcid,why or url,quality,status='verified' if quality=='verified' else 'partial')
    return True


def map_country(conn,name):
    return conn.execute('SELECT id FROM countries WHERE lower(country_name)=lower(?)',(name.strip(),)).fetchone()


def list_countries(conn,requested,first_n,countries_file,all_countries=False):
    names=[]
    if requested:names += [x.strip() for x in requested.split(',') if x.strip()]
    if countries_file:
        names += [x.strip() for x in Path(countries_file).read_text(encoding='utf8').splitlines() if x.strip() and not x.startswith('#')]
    if first_n:
        names += [x[0] for x in conn.execute('SELECT country_name FROM countries ORDER BY country_name LIMIT ?',(first_n,))]
    if all_countries:
        names += [x[0] for x in conn.execute('SELECT country_name FROM countries ORDER BY country_name')]
    if not names: raise ValueError('Choose --all-countries, --country, --countries-file or --first-n-countries')
    out=[]
    for name in dict.fromkeys(names):
        v=map_country(conn,name)
        if not v:raise ValueError(f'Country not found: {name}')
        out.append((v[0],name))
    return out


def place_rows(conn,country_id,limit=None,offset=0):
    q='''SELECT p.id,p.place_name,p.latitude,p.longitude,p.wikidata_id,p.city_id,p.official_website,
           ci.city_name,s.state_name,s.id AS state_id,c.country_name
      FROM places p JOIN cities ci ON p.city_id=ci.id
      JOIN states s ON ci.state_id=s.id JOIN countries c ON s.country_id=c.id
      WHERE c.id=? AND p.deleted_at IS NULL ORDER BY ci.city_name,p.place_name,p.id'''
    rows=conn.execute(q,(country_id,)).fetchall()
    return rows[offset:][:limit] if limit is not None else rows[offset:]


def choose_match(client, row):
    """Conservative: existing QID or unambiguous search match with place GPS and/or name+country.

    No match is accepted solely because an API returned the first search result.
    """
    qid=row['wikidata_id']
    if qid and QID.fullmatch(qid):
        entity=client.entity(qid)
        if not entity:return None,'Existing QID missing from Wikidata'
        sim=max(similarity(row['place_name'],entity_label(entity)),
                similarity(row['place_name'], entity.get('sitelinks',{}).get('enwiki',{}).get('title','')))
        geo=claim_coord(entity)
        dist=haversine(row['latitude'],row['longitude'],*geo) if geo and row['latitude'] is not None and row['longitude'] is not None else None
        if sim < .48 and (dist is None or dist > 5): return None,'Existing QID conflicts with name/location'
        if dist is not None and dist > 35:return None,f'Existing QID coordinates differ by {dist:.1f} km'
        return entity,'existing_qid'
    # Search results for city-qualified queries may omit the actual site; retry with name alone.
    terms=[row['place_name']+' '+row['city_name'],row['place_name']]
    results=[]
    for term in terms:
        results.extend(client.search(term,limit=8))
    results=list({x.get('id'):x for x in results if x.get('id')}.values())
    if not results:return None,'No Wikidata search result'
    candidates=[]
    seed_gps = row['latitude'] is not None and row['longitude'] is not None
    for r in results[:12]:
        q=r.get('id','')
        if not QID.fullmatch(q):continue
        label=r.get('label',''); ali=r.get('match',{}).get('text','')
        sim=max(similarity(row['place_name'],label),similarity(row['place_name'],ali))
        if sim < (.66 if seed_gps else .90):continue
        # Avoid wasting API calls if available search metadata already contradicts city.
        entity=client.entity(q)
        if not entity:continue
        coord=claim_coord(entity)
        dist=haversine(row['latitude'],row['longitude'],*coord) if seed_gps and coord else None
        if seed_gps:
            if dist is None or dist > 6:continue
            score=sim+.10*(dist<1)+.03*(dist<3)
            candidates.append((score,entity,f'search_and_geolocation ({dist:.2f}km)'))
            continue
        # Many seed rows do not have coordinates. They can still be matched
        # conservatively with a near-exact name, city AND country corroboration.
        description=norm(entity_description(entity))
        city=norm(row['city_name']);country=norm(row['country_name'])
        city_ok=bool(city and re.search(r'(?<!\w)'+re.escape(city)+r'(?!\w)',description))
        country_ok=bool(country and re.search(r'(?<!\w)'+re.escape(country)+r'(?!\w)',description))
        if not city_ok:
            # Administrative parent P131 may directly identify the city.
            for parent_qid in entity_ids(entity,'P131')[:2]:
                parent=client.entity(parent_qid)
                if parent and norm(entity_label(parent))==city:
                    city_ok=True;break
        if not country_ok:
            # P17 is an explicit Wikidata country assertion. Compare the
            # country entity label; do not infer country from a URL domain.
            for country_qid in entity_ids(entity,'P17')[:2]:
                country_entity=client.entity(country_qid)
                if country_entity and norm(entity_label(country_entity))==country:
                    country_ok=True;break
        if not (city_ok and country_ok):continue
        score=sim+.05
        candidates.append((score,entity,'near_exact_name_city_country'))
    candidates.sort(key=lambda x:x[0],reverse=True)
    if not candidates:
        return None,'No sufficiently grounded Wikidata match (requires seed GPS, or near-exact name plus city and country evidence)'
    if len(candidates)>1 and candidates[0][0]-candidates[1][0] < .11:
        return None,'Ambiguous Wikidata identity; multiple similarly plausible candidates'
    return candidates[0][1],candidates[0][2]


def commons_file_candidates(entity,client,max_images):
    picks=[]
    for v in claim_str(entity,'P18'):
        if IMG_EXT.search(v) and not BANNED_FILE.search(v.replace('_',' ')):
            picks.append((v,'wikidata_P18'))
    cat=entity.get('sitelinks',{}).get('commonswiki',{}).get('title','')
    if cat.startswith('Category:'):cat=cat[len('Category:'):]
    else:cat=next(iter(claim_str(entity,'P373')),'')
    if cat and max_images>len(picks):
        for f in client.category_files(cat,min(3*max_images,35)):
            bare=re.sub(r'^File:','',f,flags=re.I)
            if IMG_EXT.search(bare) and not BANNED_FILE.search(bare.replace('_',' ')):
                picks.append((bare,'commons_category'))
    seen=set(); output=[]
    for file,kind in picks:
        key=file.replace('_',' ').lower().removeprefix('file:')
        if key in seen:continue
        seen.add(key);output.append((file,kind))
    return output[:max_images*2]


def image_license(info):
    em=info.get('extmetadata',{})
    def meta(k):return clean_html(em.get(k,{}).get('value',''))
    lic=meta('LicenseShortName'); url=meta('LicenseUrl')
    if not lic or BANNED_LICENSE.search(lic) or not ALLOWED_LICENSE.match(lic):return None
    if 'BY' in lic.upper() and not meta('Artist') and not meta('Attribution'):
        return None
    return {
        'license':lic, 'license_url':url, 'author':meta('Artist') or meta('Attribution'),
        'credit':meta('Attribution') or meta('Artist'), 'usage_terms':lic,
    }


def store_photos(conn,pol,client,batch,placeid,entity,max_images):
    additions=0
    candidates=commons_file_candidates(entity,client,max_images)
    if not candidates:return 0
    kind_map={x.replace('_',' ').lower().removeprefix('file:'):k for x,k in candidates}
    # Batch imageinfo instead of one API call per photo.
    for page in client.images([f for f,k in candidates]):
        title=page.get('title',''); key=title.replace('_',' ').lower().removeprefix('file:')
        kind=kind_map.get(key)
        if not kind:continue
        infos=page.get('imageinfo',[])
        if not infos:continue
        v=infos[0]
        lice=image_license(v)
        if not lice:continue
        photo=v.get('url',''); thumb=v.get('thumburl') or photo
        if not(photo.startswith('https://') and thumb.startswith('https://')):continue
        width,height=v.get('width'),v.get('height')
        if not isinstance(width,int) or not isinstance(height,int) or min(width,height)<=0:continue
        file_page=page.get('canonicalurl') or 'https://commons.wikimedia.org/wiki/'+urllib.parse.quote(title.replace(' ','_'),safe=':/()')
        if conn.execute('SELECT 1 FROM photos WHERE place_id=? AND (commons_file_name=? OR photo_source_url=?)',(placeid,title,file_page)).fetchone():continue
        count=conn.execute('SELECT COUNT(*) FROM photos WHERE place_id=? AND photo_status IN (\'verified\',\'needs_review\')',(placeid,)).fetchone()[0]
        if count >= max_images:break
        status='verified' if kind=='wikidata_P18' else 'needs_review'
        primary = int(status=='verified' and not conn.execute('SELECT 1 FROM photos WHERE place_id=? AND is_primary=1',(placeid,)).fetchone())
        cur=conn.execute('''INSERT INTO photos(place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,
            photo_license,photo_source_url,photo_status,is_primary,sort_order,commons_file_name,image_width,image_height)
            VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',
            (placeid,title[5:].rsplit('.',1)[0].replace('_',' '),lice['usage_terms'],thumb,photo,lice['author'],
             lice['license'],file_page,status,primary,count+1,title,width,height))
        pid=cur.lastrowid
        attr='; '.join(x for x in (lice['credit'],lice['license'],file_page) if x)
        conn.execute('''INSERT INTO photo_attributions(photo_id,commons_file_page,license_url,attribution_text,notes)
                     VALUES(?,?,?,?,?)''',(pid,file_page,lice['license_url'] or None,attr,
                      'Category image requires visual identity review' if status=='needs_review' else 'Wikidata P18 identity association'))
        sourceid=source(conn,file_page,title,'Wikimedia Commons',2)
        verification(conn,batch,'photos',pid,'photo_url',photo,sourceid,
                     'Commons imageinfo URL; license: '+lice['license'],kind,status='verified' if status=='verified' else 'partial')
        verification(conn,batch,'photos',pid,'thumbnail_url',thumb,sourceid,
                     'Commons generated image thumbnail',kind,status='verified' if status=='verified' else 'partial')
        additions+=1
    return additions


def text_summary(entity,row):
    description=entity_description(entity).strip(' .')
    if not description:return None
    # Wikidata English descriptions are CC0. The template must not imply site access details.
    label=entity_label(entity)
    if similarity(label,row['place_name']) < .65:return None
    return (f'{label} — {description}.')[:600]


def audit_missing_place_facts(conn,pol,batch,placeid):
    # Audit fields the Wikimedia-only stage did not establish. This is NOT
    # evidence that a fact is unavailable on official websites.
    wanted=[col for (table,col),action in pol.actions.items()
        if table=='places' and action=='RESEARCH_VERIFY' and col not in ('wikidata_id',)]
    wanted+=['ai_summary','place_tip']
    data=conn.execute('SELECT '+','.join(wanted)+' FROM places WHERE id=?',(placeid,)).fetchone()
    for col in wanted:
        if data[col] not in (None,''):continue
        exists=conn.execute('''SELECT 1 FROM unresolved_fields WHERE batch_id=? AND source_table='places'
                                AND record_id=? AND column_name=?''',(batch,placeid,col)).fetchone()
        if not exists:
            unresolved(conn,batch,'places',placeid,col,'NOT_VERIFIED_BY_WIKIMEDIA',
                       'Requires an authoritative non-Wikimedia source or manual review; not guessed')


def enrich_place(conn,pol,client,batch,row,max_images=5):
    stats={'place_id':row['id'],'name':row['place_name'],'fields_added':0,'photos_added':0,'result':'partial'}
    try:
        entity,how=choose_match(client,row)
    except (TemporaryAPIError,PermanentAPIError) as err:
        unresolved(conn,batch,'places',row['id'],'wikidata_id','SOURCE_UNAVAILABLE',str(err));audit_missing_place_facts(conn,pol,batch,row['id']);stats['result']='source_unavailable';return stats
    if not entity:
        unresolved(conn,batch,'places',row['id'],'wikidata_id','NO_SAFE_MATCH',how);audit_missing_place_facts(conn,pol,batch,row['id']);stats['result']='no_match';return stats
    qid=entity['id']
    owner=conn.execute('SELECT id FROM places WHERE wikidata_id=? AND id<>?',(qid,row['id'])).fetchone()
    if owner:
        unresolved(conn,batch,'places',row['id'],'wikidata_id','WIKIDATA_ID_ALREADY_ASSIGNED',
                   f'QID {qid} belongs to existing place {owner[0]}; review duplicate identity')
        audit_missing_place_facts(conn,pol,batch,row['id'])
        stats['result']='no_match'
        return stats
    wiki_url='https://www.wikidata.org/wiki/'+qid
    src=source(conn,wiki_url,'Wikidata '+qid,'Wikidata',2)
    # Wikipedia is a separate API/source check, not a license to treat the article as
    # an original official website or to silently copy CC BY-SA prose.
    wiki_title=entity.get('sitelinks',{}).get('enwiki',{}).get('title')
    if wiki_title:
        try:
            article=client.english_wikipedia(wiki_title)
            if article and article.get('pageprops',{}).get('wikibase_item')==qid:
                article_url='https://en.wikipedia.org/wiki/'+urllib.parse.quote(wiki_title.replace(' ','_'))
                a_src=source(conn,article_url,wiki_title,'English Wikipedia',3)
                verification(conn,batch,'places',row['id'],'wikidata_id',qid,a_src,
                    'Wikipedia pageprops.wikibase_item matches Wikidata QID',
                    'Cross-link identity corroboration; Wikipedia shares Wikidata and is not independent geographic verification',
                    status='partial')
        except (TemporaryAPIError,PermanentAPIError) as err:
            unresolved(conn,batch,'places',row['id'],'ai_summary','WIKIPEDIA_LOOKUP_FAILED',str(err))
    def write(col,value,explain):
        if update_if_empty(conn,pol,batch,'places',row['id'],col,value,src,wiki_url,explain,quality='partial'):stats['fields_added']+=1
    # Never replace existing IDs/coordinates: log conflicts instead.
    write('wikidata_id',qid,how)
    coords=claim_coord(entity)
    if coords:
        # no false exact coordinates for a large region/site when old coords may be a nearby centroid.
        if row['latitude'] is not None and row['longitude'] is not None and haversine(row['latitude'],row['longitude'],*coords)>3:
            unresolved(conn,batch,'places',row['id'],'latitude','COORDINATE_CONFLICT',
                       f'Seed GPS differs >3km from Wikidata {qid}')
        else:
            write('latitude',round(coords[0],7),'Wikidata P625 coordinates')
            write('longitude',round(coords[1],7),'Wikidata P625 coordinates')
    write('name_english',entity_label(entity),'Wikidata English label')
    summary=text_summary(entity,row)
    if summary:write('ai_summary',summary,'Wikidata CC0 English description, template; not an AI-written detailed guide')
    website=next((x for x in claim_str(entity,'P856') if x.startswith('https://')),None)
    if website:
        # P856 = asserted official website; not live link tested. Record as provisional, do not use to confer verified status.
        unresolved(conn,batch,'places',row['id'],'official_website','LINK_NEEDS_VALIDATION',
                   'Wikidata P856 candidate (not independently checked): '+website)
    try:
        stats['photos_added']=store_photos(conn,pol,client,batch,row['id'],entity,max_images)
    except (TemporaryAPIError,PermanentAPIError,sqlite3.Error) as err:
        unresolved(conn,batch,'photos',row['id'],'photo_url','PHOTO_LOOKUP_FAILED',str(err))
    # No false 'verified' completion: critical visitor facts are still pending.
    missing=[]
    dbrow=conn.execute('SELECT official_website,access_status,suggested_duration FROM places WHERE id=?',(row['id'],)).fetchone()
    for col in ('official_website','access_status','suggested_duration'):
        if not dbrow[col]:missing.append(col)
    for col in missing:
        if not conn.execute('SELECT 1 FROM unresolved_fields WHERE batch_id=? AND source_table=? AND record_id=? AND column_name=?',(batch,'places',row['id'],col)).fetchone():
            unresolved(conn,batch,'places',row['id'],col,'NEEDS_OFFICIAL_SOURCE','Wikidata/Commons alone does not verify current visitor details')
    if stats['fields_added'] or stats['photos_added']:
        conn.execute('''UPDATE places SET updated_at=?,verification_status='partial',
          verification_notes=? WHERE id=? AND verification_status IN ('partial','unverified','needs_review')''',
          (TODAY(),f'Automated Wikimedia enrichment {batch}: Wikidata identity evidence; visitor facts require official confirmation.',row['id']))
    audit_missing_place_facts(conn,pol,batch,row['id'])
    stats['result']='enriched' if stats['fields_added'] or stats['photos_added'] else 'no_new_values'
    return stats


def country_enrich(conn,pol,client,batch,country_id,name):
    try:
        results=client.search(name,limit=7)
        exact=[x for x in results if norm(x.get('label'))==norm(name)]
        if len(exact)!=1:return 0
        e=client.entity(exact[0]['id'])
        if not e:return 0
        url='https://www.wikidata.org/wiki/'+e['id']
        src=source(conn,url,'Wikidata '+e['id'],'Wikidata',2)
        added=0
        mapping={'iso2':'P297','iso3':'P298','iso_numeric':'P299','calling_code':'P474'}
        for col,prop in mapping.items():
            vals=claim_str(e,prop)
            if len(vals)!=1:continue
            val=vals[0]
            if col=='iso2' and not re.fullmatch('[A-Z]{2}',val):continue
            if col=='iso3' and not re.fullmatch('[A-Z]{3}',val):continue
            if col=='iso_numeric' and not re.fullmatch(r'\d{3}',val):continue
            if col=='calling_code' and not val.startswith('+'):continue
            if update_if_empty(conn,pol,batch,'countries',country_id,col,val,src,url,'Wikidata '+prop):added+=1
        return added
    except (TemporaryAPIError,PermanentAPIError) as exc:
        unresolved(conn,batch,'countries',country_id,'iso2','SOURCE_UNAVAILABLE',str(exc))
        return 0


def batch_id_for(name):
    # New unique batch every command invocation; resume works at data / photo level.
    return 'FREE-WIKI-'+dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%f')+'-'+str(os.getpid())


def initialize_copy(inputdb,output,resume):
    ip,op=Path(inputdb).resolve(),Path(output).resolve()
    if not ip.exists():raise FileNotFoundError(ip)
    if ip==op:raise ValueError('Input and output must be different: canonical DB must never be changed')
    if op.exists():
        if not resume: raise FileExistsError(f'{op} exists; use --resume or choose a new --output')
        return
    op.parent.mkdir(parents=True,exist_ok=True)
    with contextlib.closing(sqlite3.connect(f'file:{urllib.parse.quote(str(ip))}?mode=ro',uri=True)) as src, contextlib.closing(sqlite3.connect(str(op))) as dst:
        src.backup(dst)
        dst.commit()


def ensure_schema(conn,pol):
    dbtables={r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    necessary=['countries','states','cities','places','photos','photo_attributions','data_sources',
               'field_verifications','verification_evidence','unresolved_fields','batch_registry']
    if missing := (set(necessary)-dbtables):raise ValueError('Database missing tables: '+','.join(sorted(missing)))
    if conn.execute('PRAGMA integrity_check').fetchone()[0]!='ok':raise ValueError('Input DB integrity check failed')
    for t,c in [('places','wikidata_id'),('photos','commons_file_name')]:
        if c not in {r[1] for r in conn.execute(f'PRAGMA table_info({t})')}:raise ValueError(f'Missing {t}.{c}')



def place_discoveries(conn, batch, placeid):
    '''Read back accepted evidence and unresolved decisions for ONE attempted place.

    Called after the enrichment transaction and before optional dry-run rollback.
    The output describes this invocation's evidence, not preexisting records.
    '''
    fields = [dict(r) for r in conn.execute('''SELECT v.column_name AS field, v.accepted_value AS value,
                  v.verification_status AS verification, d.url AS source_url, d.publisher AS publisher,
                  v.notes AS notes
            FROM field_verifications v LEFT JOIN data_sources d ON d.id=v.source_id
            WHERE v.batch_id=? AND v.source_table='places' AND v.entity_id=?
            ORDER BY v.id''', (batch, placeid))]
    # A separate verification row is created for each newly stored photo URL.
    photos = [dict(r) for r in conn.execute('''SELECT p.id AS photo_id, p.photo_title AS title,
                  p.photo_status AS verification, p.is_primary AS primary_photo,
                  p.photo_url, p.thumbnail_url, p.photo_source_url AS source_url,
                  p.photo_author AS author, p.photo_license AS license,
                  a.license_url, a.attribution_text
            FROM field_verifications v JOIN photos p ON p.id=v.entity_id
            LEFT JOIN photo_attributions a ON a.photo_id=p.id
            WHERE v.batch_id=? AND v.source_table='photos' AND v.column_name='photo_url'
              AND p.place_id=? ORDER BY p.id''', (batch, placeid))]
    unresolved = [dict(r) for r in conn.execute('''SELECT source_table AS source_table,
                  column_name AS field, reason_code AS reason, details
            FROM unresolved_fields
            WHERE batch_id=? AND record_id=? AND source_table IN ('places','photos')
            ORDER BY source_table, column_name''', (batch, placeid))]
    return {'fields': fields, 'photos': photos, 'unresolved': unresolved}


def progress_checkpoint(path, progress):
    '''Write a readable, atomically replaced progress snapshot after each place.''' 
    path = Path(path)
    tmp = path.with_name(path.name + '.tmp')
    tmp.write_text(json.dumps(progress, ensure_ascii=False, indent=2), encoding='utf-8')
    tmp.replace(path)


def event_write(stream, kind, batch, **extra):
    entry={'timestamp':TODAY(), 'event':kind, 'batch_id':batch, **extra}
    stream.write(json.dumps(entry,ensure_ascii=False,default=str) + '\n')
    stream.flush()


def brief(s, max_length=190):
    text=str(s or '').replace('\n',' ').replace('\r',' ')
    return text[:max_length-1]+'…' if len(text)>max_length else text


def print_findings(item, details, show_findings=False, show_unresolved=False):
    '''Terminal details never claim an unverified value is verified.''' 
    if show_findings:
        for f in details['fields']:
            LOG.info('    FIELD %-23s %-8s %s', f['field'],f['verification'],brief(f['value']))
            if f['source_url']: LOG.info('          SOURCE %s',f['source_url'])
        for ph in details['photos']:
            LOG.info('    PHOTO %s (%s; %s) %s',ph['photo_id'],ph['verification'],ph['license'],brief(ph['title']))
            LOG.info('          THUMB %s',ph['thumbnail_url'])
            LOG.info('          SOURCE %s',ph['source_url'])
    if show_unresolved:
        for u in details['unresolved']:
            LOG.info('    UNRESOLVED %s.%s: %s — %s',u['source_table'],u['field'],u['reason'],brief(u['details']))

def ensure_resume_table(conn, events_path):
    """Durable per-place resume state, committed with each successful enrichment.

    A completed attempt (including NO_SAFE_MATCH) is not repeated on resume.
    Temporary source failures and failed DB writes remain retryable.
    """
    conn.execute("""CREATE TABLE IF NOT EXISTS enrichment_run_checkpoints (
         place_id INTEGER PRIMARY KEY REFERENCES places(id) ON DELETE CASCADE,
         country_id INTEGER NOT NULL REFERENCES countries(id),
         stage TEXT NOT NULL CHECK(stage IN ('done','retryable')),
         result TEXT NOT NULL,
         fields_added INTEGER NOT NULL DEFAULT 0,
         photos_added INTEGER NOT NULL DEFAULT 0,
         attempts INTEGER NOT NULL DEFAULT 1,
         last_batch_id TEXT,
         finished_at TEXT NOT NULL
    )""")
    conn.execute('CREATE INDEX IF NOT EXISTS ix_enrichment_checkpoint_country ON enrichment_run_checkpoints(country_id,stage)')
    # Upgrade previous versions that committed a place but did not store checkpoints.
    # The previous runner wrote place_result events AFTER a successful SQLite commit.
    migrated = 0
    count = conn.execute('SELECT COUNT(*) FROM enrichment_run_checkpoints').fetchone()[0]
    if count == 0 and Path(events_path).exists():
        with Path(events_path).open(encoding='utf8') as stream:
            for line in stream:
                try: entry = json.loads(line)
                except (ValueError,TypeError): continue
                if entry.get('event') != 'place_result' or entry.get('preview'): continue
                if entry.get('result') == 'source_unavailable': continue
                pid = entry.get('place_id')
                if not isinstance(pid,int): continue
                r = conn.execute('''SELECT c.id FROM places p JOIN cities ci ON ci.id=p.city_id
                     JOIN states s ON s.id=ci.state_id JOIN countries c ON c.id=s.country_id
                     WHERE p.id=?''',(pid,)).fetchone()
                if not r: continue
                conn.execute('''INSERT OR IGNORE INTO enrichment_run_checkpoints
                    (place_id,country_id,stage,result,fields_added,photos_added,last_batch_id,finished_at)
                    VALUES(?,?,?,?,?,?,?,?)''',
                    (pid,r[0],'done',str(entry.get('result','no_new_values')),
                     int(entry.get('fields_added') or 0),int(entry.get('photos_added') or 0),
                     entry.get('batch_id'),entry.get('timestamp') or TODAY()))
                migrated += 1
    conn.commit()
    return migrated


def record_place_checkpoint(conn, row, country_id, batch_id, result, fields, photos):
    stage='retryable' if result in ('source_unavailable','error') else 'done'
    conn.execute('''INSERT INTO enrichment_run_checkpoints
        (place_id,country_id,stage,result,fields_added,photos_added,attempts,last_batch_id,finished_at)
        VALUES(?,?,?,?,?,?,1,?,?)
        ON CONFLICT(place_id) DO UPDATE SET
        country_id=excluded.country_id,stage=excluded.stage,result=excluded.result,
        fields_added=enrichment_run_checkpoints.fields_added+excluded.fields_added,
        photos_added=enrichment_run_checkpoints.photos_added+excluded.photos_added,
        attempts=enrichment_run_checkpoints.attempts+1,
        last_batch_id=excluded.last_batch_id,finished_at=excluded.finished_at''',
        (row['id'],country_id,stage,result,fields,photos,batch_id,TODAY()))
    return stage


def run(opts,transport=None,sleeper=None):
    if opts.max_photos<1 or opts.max_photos>20:raise ValueError('--max-photos must be 1..20')
    if opts.limit is not None and opts.limit < 1:raise ValueError('--limit must be positive')
    if opts.output is None:raise ValueError('--output is required')
    pol=Policy()
    initialize_copy(opts.db,opts.output,opts.resume)
    conn=sqlite3.connect(opts.output)
    conn.row_factory=sqlite3.Row; conn.execute('PRAGMA foreign_keys=ON');conn.execute('PRAGMA busy_timeout=20000')
    try:
        ensure_schema(conn,pol)
        countries=list_countries(conn,opts.country,opts.first_n_countries,opts.countries_file,getattr(opts,'all_countries',False))
        selection=[(cid,name,place_rows(conn,cid,opts.limit,opts.offset)) for cid,name in countries]
        total_places=sum(len(rows) for _,_,rows in selection)
        client=WikiClient(opts.cache_dir,opts.contact,opts.timeout,opts.retries,opts.min_interval,transport=transport,sleeper=sleeper)
        batch=batch_id_for('tripraft')
        report={'batch_id':batch,'countries':{},'network_calls':0,'network_errors':0,'cache_hits':0}
        progress_path=Path(str(opts.output)+'.progress.json')
        events_path=Path(str(opts.output)+'.events.jsonl')
        stop_path=Path(getattr(opts,'stop_file',None) or str(opts.output)+'.stop')
        events_path.parent.mkdir(parents=True, exist_ok=True)
        migrated=ensure_resume_table(conn,events_path) if not opts.dry_run else 0
        # Use completed state from SQLite, not the old progress JSON; each checkpoint and
        # place change are committed in the same transaction, so a crash is safe.
        checkpoint_data=({r['place_id']:dict(r) for r in conn.execute('SELECT * FROM enrichment_run_checkpoints')}
                         if not opts.dry_run else {})
        done_ids={r['place_id'] for r in checkpoint_data.values() if r['stage']=='done'} if not opts.dry_run else set()
        valid_ids={r['id'] for _,_,rows in selection for r in rows}
        done_in_scope=done_ids & valid_ids
        retryable_in_scope={pid for pid,v in checkpoint_data.items() if v['stage']=='retryable' and pid in valid_ids}
        show_findings=getattr(opts,'show_findings',False)
        show_unresolved=getattr(opts,'show_unresolved',False)
        recheck=getattr(opts,'recheck_completed',False)
        failures=0; started_at=TODAY(); newly_attempted=0; skipped=0; paused=False
        progress={'batch_id':batch,'started_at':started_at,'updated_at':started_at,'status':'running',
             'dry_run':opts.dry_run,'total_countries':len(selection),'countries_finished':0,
             'total_places':total_places,'places_processed':0,'places_completed':len(done_in_scope),
             'places_retryable':len(retryable_in_scope),'places_remaining':total_places-len(done_in_scope),
             'places_skipped':0,'places_attempted_this_run':0,'percent_complete':0.0,
             'current_country':None,'current_state':None,'current_city':None,
             'current_place':None,'current_place_id':None,
             'network_calls':0,'network_errors':0,'cache_hits':0,'errors':0,'countries':{}}
        for cid,name,rows in selection:
            completed=[r for r in rows if r['id'] in done_in_scope]
            retryable=[r for r in rows if r['id'] in retryable_in_scope]
            progress['countries'][name]={'total':len(rows),'processed':len(completed),
                'retryable':len(retryable),'remaining':len(rows)-len(completed),
                'fields_added':sum(checkpoint_data.get(r['id'],{}).get('fields_added',0) for r in rows),
                'photos_added':sum(checkpoint_data.get(r['id'],{}).get('photos_added',0) for r in rows),
                'errors':0,'status':'finished' if len(completed)==len(rows) else 'pending'}
        def checkpoint_progress():
            progress['places_processed']=len(done_in_scope)+len(retryable_in_scope)
            progress['places_completed']=len(done_in_scope)
            progress['places_retryable']=len(retryable_in_scope)
            progress['places_remaining']=total_places-len(done_in_scope)
            progress['places_skipped']=skipped
            progress['places_attempted_this_run']=newly_attempted
            progress['countries_finished']=sum(v['status']=='finished' for v in progress['countries'].values())
            progress['percent_complete']=round(100*len(done_in_scope)/total_places,2) if total_places else 100
            progress['network_calls']=client.network_calls
            progress['network_errors']=client.network_errors
            progress['cache_hits']=client.cache_hits
            progress['errors']=failures
            progress['updated_at']=TODAY()
            progress_checkpoint(progress_path,progress)
        try:
            with events_path.open('a',encoding='utf-8',buffering=1) as events:
                event_write(events,'run_started',batch,total_countries=len(selection),total_places=total_places,
                        resumed_complete=len(done_in_scope),migrated_checkpoints=migrated,
                        dry_run=opts.dry_run,input_db=str(opts.db),output_db=str(opts.output))
                checkpoint_progress()
                LOG.info('RUN — %d countries, %d places, %d already completed; progress %s',
                         len(selection),total_places,len(done_in_scope),progress_path)
                for cid,name,rows in selection:
                    if stop_path.exists():paused=True;break
                    cr={'places_selected':len(rows),'processed':0,'skipped':0,'enriched':0,'photos_added':0,
                        'fields_added':0,'results':{},'errors':[]}
                    report['countries'][name]=cr
                    pc=progress['countries'][name]
                    if pc['remaining']==0 and not recheck:
                        cr['skipped']=len(rows);skipped+=len(rows)
                        LOG.info('SKIP COUNTRY %s: all %d places already completed',name,len(rows))
                        checkpoint_progress()
                        continue
                    progress['current_country']=name;pc['status']='running'
                    LOG.info('COUNTRY %s: %d places (%d completed, %d left)',name,len(rows),
                        pc['processed'],pc['remaining'])
                    event_write(events,'country_started',batch,country=name,country_id=cid,total=len(rows),
                                remaining=pc['remaining'])
                    bid=batch+'-'+str(cid)
                    if not opts.dry_run:
                        conn.execute('''INSERT INTO batch_registry(batch_id,country_id,source_filename,processing_status,places_total,started_at,notes)
                        VALUES(?,?,?,?,?,?,?)''',(bid,cid,str(opts.db),'PROCESSING',len(rows),TODAY(),
                         'Resumable Wikimedia enrichment; never full-verified automatically'))
                        conn.commit()
                    if opts.enrich_countries and not stop_path.exists():
                        try:
                            conn.execute('SAVEPOINT countrymeta')
                            added=country_enrich(conn,pol,client,bid,cid,name)
                            cr['fields_added']+=added
                            if opts.dry_run:conn.execute('ROLLBACK TO SAVEPOINT countrymeta')
                            conn.execute('RELEASE SAVEPOINT countrymeta')
                            if not opts.dry_run:conn.commit()
                            event_write(events,'country_metadata',batch,country=name,fields_added=added,preview=opts.dry_run)
                        except sqlite3.Error as exc:
                            conn.rollback();cr['errors'].append(str(exc))
                            event_write(events,'country_metadata_error',batch,country=name,error=str(exc))
                    for row in rows:
                        if stop_path.exists():paused=True;break
                        pid=row['id']
                        if pid in done_in_scope and not recheck and not opts.dry_run:
                            skipped+=1;cr['skipped']+=1
                            continue
                        progress.update(current_state=row['state_name'],current_city=row['city_name'],
                            current_place=row['place_name'],current_place_id=pid)
                        LOG.info('RESEARCH %s > %s > %s > %s (ID %d; %d/%d completed)',
                            name,row['state_name'],row['city_name'],row['place_name'],pid,len(done_in_scope),total_places)
                        try:
                            conn.execute('SAVEPOINT placecheck')
                            item=enrich_place(conn,pol,client,bid,row,opts.max_photos)
                            details=place_discoveries(conn,bid,pid)
                            stage='done' if item['result']!='source_unavailable' else 'retryable'
                            if not opts.dry_run:
                                stage=record_place_checkpoint(conn,row,cid,bid,item['result'],item['fields_added'],item['photos_added'])
                            else:
                                conn.execute('ROLLBACK TO SAVEPOINT placecheck')
                            conn.execute('RELEASE SAVEPOINT placecheck')
                            if not opts.dry_run:conn.commit()
                            cr['processed']+=1
                            cr['results'][item['result']]=cr['results'].get(item['result'],0)+1
                            cr['enriched']+=item['result']=='enriched'
                            cr['photos_added']+=item['photos_added']
                            cr['fields_added']+=item['fields_added']
                            if stage=='done':
                                done_in_scope.add(pid);retryable_in_scope.discard(pid)
                                pc['processed']+=int(pid not in done_ids)
                            else:
                                retryable_in_scope.add(pid)
                            pc['retryable']=len([r for r in rows if r['id'] in retryable_in_scope])
                            pc['remaining']=len(rows)-len([r for r in rows if r['id'] in done_in_scope])
                            pc['fields_added']+=item['fields_added'];pc['photos_added']+=item['photos_added']
                            LOG.info('RESULT %s: %s, +%d fields +%d photos, %d unresolved',
                                     row['place_name'],item['result'],item['fields_added'],item['photos_added'],len(details['unresolved']))
                            print_findings(item,details,show_findings,show_unresolved)
                            event_write(events,'place_result',batch,country=name,state=row['state_name'],city=row['city_name'],
                              place_id=pid,place_name=row['place_name'],result=item['result'],stage=stage,
                              fields_added=item['fields_added'],photos_added=item['photos_added'],
                              findings=details,preview=opts.dry_run)
                        except (sqlite3.Error,ValueError,KeyError,TypeError) as exc:
                            conn.rollback();failures+=1
                            msg=f'Place {pid} {row["place_name"]}: {type(exc).__name__}: {exc}'
                            LOG.error(msg);cr['errors'].append(msg);pc['errors']+=1
                            if not opts.dry_run:
                                record_place_checkpoint(conn,row,cid,bid,'error',0,0);conn.commit()
                                retryable_in_scope.add(pid)
                            event_write(events,'place_error',batch,country=name,place_id=pid,error=msg)
                        finally:
                            newly_attempted+=1
                            checkpoint_progress()
                            LOG.info('PROGRESS %.2f%% | completed %d/%d | retryable %d | skipped %d | API requests %d',
                                     progress['percent_complete'],len(done_in_scope),total_places,
                                     len(retryable_in_scope),skipped,client.network_calls)
                    if not opts.dry_run:
                        conn.execute('''UPDATE batch_registry SET processing_status=?,completed_at=?,verified_photo_count=?,notes=? WHERE batch_id=?''',
                            ('NEEDS_REVIEW' if paused or cr['errors'] or pc['remaining'] else 'PASS',TODAY(),cr['photos_added'],
                             f"Wikimedia-only; new attempts {cr['processed']}; remaining {pc['remaining']}; NOT full verification",bid))
                        conn.commit()
                    pc['status']='finished' if pc['remaining']==0 else ('paused' if paused else 'needs_retry')
                    checkpoint_progress()
                    event_write(events,'country_finished' if not paused else 'country_paused',batch,country=name,summary=cr)
                    if paused:break
                report.update(network_calls=client.network_calls,network_errors=client.network_errors,cache_hits=client.cache_hits,
                  finished_at=TODAY(),dry_run=opts.dry_run,paused=paused,
                  resumed_completed_at_start=len(done_ids & valid_ids),places_completed=len(done_in_scope),
                  places_remaining=total_places-len(done_in_scope),places_attempted_this_run=newly_attempted,
                  places_skipped=skipped,success=not paused and failures==0 and client.network_errors==0 and len(done_in_scope)==total_places)
                check=conn.execute('PRAGMA integrity_check').fetchone()[0]
                foreign=conn.execute('PRAGMA foreign_key_check').fetchmany(3)
                report.update(db_integrity=check,foreign_key_violations=[list(row) for row in foreign])
                report['success']=report['success'] and check=='ok' and not foreign
                filename=Path(opts.report or str(opts.output)+'.report.json')
                filename.parent.mkdir(parents=True,exist_ok=True)
                filename.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
                progress['status']='paused' if paused else ('finished' if report['success'] else 'finished_with_errors')
                progress.update(current_place=None,current_place_id=None,current_country=None,current_state=None,current_city=None)
                progress['report_file']=str(filename)
                checkpoint_progress()
                event_write(events,'run_paused' if paused else 'run_finished',batch,success=report['success'],
                    report_file=str(filename),network_errors=client.network_errors,db_integrity=check)
                LOG.info('Saved %s: completed %d/%d; pending %d; attempts this run %d; skipped %d',
                         progress['status'],len(done_in_scope),total_places,total_places-len(done_in_scope),newly_attempted,skipped)
                return report
        finally:
            pass
    finally:
        conn.close()

# ============================================================================
# SINGLE-FILE COMMAND LINE + WINDOWS/MAC/LINUX BACKGROUND WORKER MANAGEMENT
# ============================================================================
import subprocess
import ctypes
from collections import deque

DEFAULT_DB = Path('data') / 'catalog' / 'tripraft_places.db'
DEFAULT_OUTPUT = Path('data') / 'catalog' / 'tripraft_places.enriched.db'


def pathset(output):
    output=str(Path(output).resolve())
    return {k: output+suffix for k,suffix in {
        'db':'', 'progress':'.progress.json', 'events':'.events.jsonl',
        'report':'.report.json','stop':'.stop','log':'.worker.log',
        'job':'.job.json'}.items()}


def atomic_json(path, value):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    tmp=Path(str(path)+'.tmp')
    tmp.write_text(json.dumps(value,indent=2,ensure_ascii=False),encoding='utf8')
    tmp.replace(path)


def read_json(path):
    try:return json.loads(Path(path).read_text(encoding='utf8'))
    except (OSError,ValueError):return {}


def is_alive(pid):
    if not isinstance(pid,int) or pid<=0:return False
    if os.name=='nt':
        # Windows GetExitCodeProcess handles still-active process code 259.
        handle=ctypes.windll.kernel32.OpenProcess(0x1000,False,pid)
        if not handle:return False
        try:
            result=ctypes.c_ulong()
            ok=ctypes.windll.kernel32.GetExitCodeProcess(handle,ctypes.byref(result))
            return bool(ok) and result.value==259
        finally:ctypes.windll.kernel32.CloseHandle(handle)
    try:os.kill(pid,0);return True
    except ProcessLookupError:return False
    except PermissionError:return True


def list_db_countries(db):
    if not Path(db).is_file():raise FileNotFoundError(f'Input database not found: {db}')
    with sqlite3.connect(str(db)) as conn:
        return conn.execute('''SELECT c.country_name, COUNT(p.id)
          FROM countries c LEFT JOIN states s ON s.country_id=c.id
          LEFT JOIN cities ci ON ci.state_id=s.id
          LEFT JOIN places p ON p.city_id=ci.id AND p.deleted_at IS NULL
          GROUP BY c.id ORDER BY c.country_name COLLATE NOCASE''').fetchall()


def add_selector(p,required=True):
    sel=p.add_mutually_exclusive_group(required=required)
    sel.add_argument('--country',help='Country name or comma-separated names; matched to database')
    sel.add_argument('--all',action='store_true',help='All countries in database')
    sel.add_argument('--first',type=int,metavar='N',help='First N alphabetically')
    return p


def add_worker_args(p):
    add_selector(p)
    p.add_argument('--contact',default=os.getenv('TRIPRAFT_WIKI_CONTACT',''),
       help='Operator email or https URL required by Wikimedia; may instead set TRIPRAFT_WIKI_CONTACT')
    p.add_argument('--db',default=str(DEFAULT_DB))
    p.add_argument('--output',default=str(DEFAULT_OUTPUT))
    p.add_argument('--max-photos',type=int,default=10,help='Max Commons photos per place (1–20)')
    p.add_argument('--limit',type=int,default=None,help='Limit places per country for testing')
    p.add_argument('--offset',type=int,default=0)
    p.add_argument('--timeout',type=float,default=18)
    p.add_argument('--retries',type=int,default=3)
    p.add_argument('--min-interval',type=float,default=1.5)
    p.add_argument('--recheck-completed',action='store_true')
    p.add_argument('--verbose',action='store_true')
    return p


def selection_from_args(a):
    if a.all:return ['--all']
    if a.country:return ['--country',a.country]
    if a.first and a.first>0:return ['--first',str(a.first)]
    raise ValueError('Supply --country, --all or --first N')


def validate_run(a):
    if not Path(a.db).is_file():raise FileNotFoundError(f'Expected SQLite DB at {a.db}. Run from project root or pass --db.')
    if not a.contact or ('@' not in a.contact and not a.contact.startswith('https://')):
        raise ValueError('Provide --contact YOUR_EMAIL or environment TRIPRAFT_WIKI_CONTACT')
    if not 1<=a.max_photos<=20:raise ValueError('--max-photos must be 1..20')
    if a.min_interval<1:raise ValueError('--min-interval must be >= 1 second for polite API use')
    if a.timeout<=0 or a.retries<0 or a.retries>7:raise ValueError('Invalid timeout/retries')
    if a.limit is not None and a.limit < 1:raise ValueError('Limit must be positive')
    if a.offset<0:raise ValueError('Offset must be >= 0')
    if Path(a.db).resolve()==Path(a.output).resolve():raise ValueError('Output must be separate from original SQLite DB')
    countries=list_db_countries(a.db)
    valid={name.casefold() for name,_ in countries}
    if a.country:
        for name in a.country.split(','):
            if name.strip().casefold() not in valid:raise ValueError('Country not found in SQLite: '+name)
    return countries


def opts_for_core(a):
    from types import SimpleNamespace
    base=Path(a.output).resolve()
    return SimpleNamespace(db=str(Path(a.db).resolve()),output=str(base),policies=None,
        country=a.country,all_countries=a.all,
        first_n_countries=a.first,countries_file=None,
        contact=a.contact,cache_dir=str(base.parent/'.tripraft_wiki_cache'),
        limit=a.limit,offset=a.offset,max_photos=a.max_photos,
        timeout=a.timeout,retries=a.retries,min_interval=a.min_interval,
        dry_run=False,resume=True,enrich_countries=True,
        stop_file=str(base)+'.stop',recheck_completed=a.recheck_completed,
        show_findings=True,show_unresolved=False,report=str(base)+'.report.json')


def launch_background(a):
    validate_run(a)
    p=pathset(a.output)
    current=read_json(p['job'])
    if is_alive(current.get('pid')):
        raise RuntimeError(f"Worker already running with PID {current['pid']}; use status/pause")
    # Prevent accidental false 'resume' after a new DB is swapped in.
    if Path(p['db']).exists():
        old_source=current.get('source_db')
        if old_source and Path(old_source).resolve()!=Path(a.db).resolve():
            raise ValueError('Existing output is associated with a different input DB. Pass a different --output.')
    Path(p['stop']).unlink(missing_ok=True)
    core=[sys.executable,'-u',str(Path(__file__).resolve()),'run',
        '--db',str(Path(a.db).resolve()),'--output',p['db'],
        '--contact',a.contact,'--max-photos',str(a.max_photos),
        '--timeout',str(a.timeout),'--retries',str(a.retries),
        '--min-interval',str(a.min_interval),*selection_from_args(a)]
    if a.limit is not None:core+=['--limit',str(a.limit)]
    if a.offset:core+=['--offset',str(a.offset)]
    if a.recheck_completed:core+=['--recheck-completed']
    if a.verbose:core+=['--verbose']
    Path(p['log']).parent.mkdir(parents=True,exist_ok=True)
    flags={'stdin':subprocess.DEVNULL,'cwd':str(Path.cwd())}
    if os.name=='nt':flags['creationflags']=subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_NO_WINDOW
    else:flags['start_new_session']=True
    with open(p['log'],'a',encoding='utf8',buffering=1) as log:
        log.write('\n=== TripRaft worker started '+TODAY()+' ===\n');log.flush()
        proc=subprocess.Popen(core,stdout=log,stderr=subprocess.STDOUT,**flags)
    job={'pid':proc.pid,'started_at':TODAY(),'source_db':str(Path(a.db).resolve()),
          'output':p['db'],'params':{k:getattr(a,k) for k in
          ('db','output','country','all','first','contact','max_photos','limit','offset',
           'timeout','retries','min_interval','recheck_completed','verbose')}}
    atomic_json(p['job'],job)
    print('Started background PID:',proc.pid)
    print('Output database:',p['db'])
    print('Progress: python '+Path(__file__).name+' status')
    print('Log file:',p['log'])


def show_status(output):
    p=pathset(output);job=read_json(p['job']);v=read_json(p['progress'])
    alive=is_alive(job.get('pid'))
    print('Worker:', 'RUNNING' if alive else ('INTERRUPTED / RESUMABLE' if v.get('status')=='running' else v.get('status','NOT STARTED').upper()))
    if job:print('PID:',job.get('pid'))
    if v:
        print(f"Countries: {v.get('countries_finished',0)}/{v.get('total_countries',0)}")
        print(f"Places complete: {v.get('places_completed',0)}/{v.get('total_places',0)} ({v.get('percent_complete',0)}%)")
        print('Still pending:',v.get('places_remaining','?'),' | Retryable:',v.get('places_retryable',0))
        print('Current:', ' > '.join(str(v.get(k) or '-') for k in
                         ('current_country','current_state','current_city','current_place')))
        print('Requests:',v.get('network_calls',0),' | API failures:',v.get('network_errors',0))
        print('Detailed findings:',p['events'])
    print('Worker log:',p['log'])


def main():
    p=argparse.ArgumentParser(description='TripRaft single-file free Wikimedia enricher. Python 3.10+; no pip packages.')
    sub=p.add_subparsers(dest='command',required=True)
    pc=sub.add_parser('countries',help='List countries and place counts in your DB')
    pc.add_argument('--db',default=str(DEFAULT_DB))
    pr=add_worker_args(sub.add_parser('run',help='Run in this terminal, resume from SQLite checkpoints'))
    ps=add_worker_args(sub.add_parser('start',help='Start detached background job'))
    for cmd in ('status','pause','resume','logs'):
        a=sub.add_parser(cmd)
        a.add_argument('--output',default=str(DEFAULT_OUTPUT))
        if cmd=='logs':a.add_argument('--lines',type=int,default=30)
    a=p.parse_args()
    if a.command=='countries':
        rows=list_db_countries(a.db)
        for name,n in rows:print(f'{name:38s} {n:6d} places')
        print(f'\nTotal: {len(rows)} countries, {sum(n for _,n in rows)} places')
    elif a.command=='run':
        validate_run(a)
        paths=pathset(a.output)
        # run does not clear a pause request; resume/launch explicitly clears it.
        logging.basicConfig(level=logging.DEBUG if a.verbose else logging.INFO,format='%(asctime)s %(levelname)s %(message)s')
        result=run(opts_for_core(a))
        print(f"Complete={result.get('places_completed')} Pending={result.get('places_remaining')} | DB={paths['db']}")
    elif a.command=='start': launch_background(a)
    elif a.command=='status':show_status(a.output)
    elif a.command=='pause':
        ps=pathset(a.output);job=read_json(ps['job'])
        if not is_alive(job.get('pid')): print('Not running. Existing saved checkpoints are reusable.')
        else:
            Path(ps['stop']).write_text('Requested graceful pause\n',encoding='utf8')
            print('Pause requested. Worker stops safely between places.')
    elif a.command=='resume':
        ps=pathset(a.output);job=read_json(ps['job'])
        if not job:raise ValueError('No previous job. Use start first.')
        args=argparse.Namespace(**job['params'])
        launch_background(args)
    elif a.command=='logs':
        ps=pathset(a.output)
        try:
            with open(ps['log'],encoding='utf8',errors='replace') as f:
                print(''.join(deque(f,maxlen=max(1,min(500,a.lines)))))
        except FileNotFoundError:print('No log yet')

if __name__=='__main__':
    try: main()
    except (ValueError,FileNotFoundError,FileExistsError,RuntimeError,sqlite3.Error) as exc:
        print(f'ERROR: {type(exc).__name__}: {exc}',file=sys.stderr)
        sys.exit(2)
