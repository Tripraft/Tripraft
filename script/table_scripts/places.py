#!/usr/bin/env python3
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 rows=job.rows('''SELECT p.id,p.place_name,p.wikidata_id,p.latitude,p.longitude,p.official_website,
                       ci.city_name,s.state_name,s.country_id,c.country_name
                   FROM places p JOIN cities ci ON ci.id=p.city_id
                   JOIN states s ON s.id=ci.state_id JOIN countries c ON c.id=s.country_id
                   ORDER BY c.country_name,s.state_name,ci.city_name,p.place_name''')
 contexts={}
 def each(j,r):
  existing=j.con.execute('SELECT wikidata_id,name_english,latitude,longitude,ai_summary,address,official_website FROM places WHERE id=?',(r['id'],)).fetchone()
  if all(v not in (None,'') for v in existing):return 0
  if r['wikidata_id']:
   e=j.client.entity(r['wikidata_id'])
   if not e or similarity(r['place_name'],label(e))<.48:
    j.store.unresolved('places',r['id'],'wikidata_id','EXISTING_QID_UNCONFIRMED');return 0
   why='existing QID; no repeated search'
  else:
   return 0  # Initial Wikimedia run already attempted this place; no duplicate broad place search.
  cid=r['country_id']
  qid=e['id'];url='https://www.wikidata.org/wiki/'+qid;n=0
  owner=j.con.execute('SELECT id FROM places WHERE wikidata_id=? AND id<>?',(qid,r['id'])).fetchone()
  if owner:j.store.unresolved('places',r['id'],'wikidata_id','DUPLICATE_QID',f'Assigned already to {owner[0]}');return 0
  n+=j.store.write('places',r['id'],'wikidata_id',qid,url,why)
  english=label(e)
  if english and similarity(r['place_name'],english)>.65:n+=j.store.write('places',r['id'],'name_english',english,url,'Wikidata English label')
  loc=coords(e)
  if loc:
   if r['latitude'] is not None and r['longitude'] is not None and km(r['latitude'],r['longitude'],*loc)>3:
    j.store.unresolved('places',r['id'],'latitude','COORDINATE_CONFLICT',f'Existing location differs >3 km from Wikidata {loc}')
   else:
    n+=j.store.write('places',r['id'],'latitude',round(loc[0],7),url,'Wikidata P625 coordinates')
    n+=j.store.write('places',r['id'],'longitude',round(loc[1],7),url,'Wikidata P625 coordinates')
  des=description(e)
  if des and similarity(r['place_name'],english)>.65:
   n+=j.store.write('places',r['id'],'ai_summary',f'{english} — {des.rstrip(".")}.',url,'Concise Wikidata CC0 description, NOT a verified visitor guide',status='partial')
  # Wikidata P6375 full street address is a language-tagged object.
  addr=next((x.get('text') for x in values(e,'P6375') if isinstance(x,dict) and x.get('text') and x.get('language') in ('en',)),None)
  if addr:n+=j.store.write('places',r['id'],'address',addr,url,'Wikidata P6375 English street address, not live postal verification',status='partial')
  site=first_string(e,'P856')
  if site and site.startswith('https://'):
   # A property assertion is a candidate, not an independently validated working website.
   n+=j.store.write('places',r['id'],'official_website',site,url,'Wikidata P856 candidate; page availability and ownership NOT independently confirmed',status='partial')
   j.store.unresolved('places',r['id'],'official_website','P856_NEEDS_LIVE_VALIDATION',site)
  # Don't fake cost, ratings, tips, hours, booking, sunset time, access status.
  for col in ('suggested_duration','best_time_to_visit','place_tip','advanced_booking','cost','address','access_status'):
   if j.con.execute(f'SELECT {col} FROM places WHERE id=?',(r['id'],)).fetchone()[0] in ('',None):
    j.store.unresolved('places',r['id'],col,'NEEDS_OFFICIAL_SOURCE','Not provided by Wikidata evidence; requires official visitor information')
  return n
 return job.process(rows,each)
if __name__=='__main__':run_stage('places',work,online=True)
