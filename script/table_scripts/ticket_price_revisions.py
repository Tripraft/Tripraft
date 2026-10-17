#!/usr/bin/env python3
"""Canonical prices: import ONLY independently source-linked textual price observations.
Cannot verify new live prices merely from Wikidata or legacy ticket_prices.
"""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 rows=job.rows('''SELECT p.id,p.place_name,s.country_id FROM places p
                   JOIN cities ci ON ci.id=p.city_id JOIN states s ON s.id=ci.state_id ORDER BY s.country_id,p.id''')
 def each(j,r):
  # Requires a source-linked, verified factual price field; generic seed cost isn't proof.
  src=j.con.execute('''SELECT fv.accepted_value,fv.source_id FROM field_verifications fv
      JOIN data_sources ds ON ds.id=fv.source_id WHERE fv.source_table='places' AND fv.entity_id=?
      AND fv.column_name='cost' AND fv.verification_status='verified'
      AND ds.authority_tier=1 AND fv.accepted_value IS NOT NULL ORDER BY fv.id DESC LIMIT 1''',(r['id'],)).fetchone()
  if not src:
   j.store.unresolved('ticket_price_revisions',r['id'],'original_text','NO_VERIFIED_OFFICIAL_PRICE','No official evidenced price observation');return 0
  value=src['accepted_value']
  if not value or len(value)>500:return 0
  if j.con.execute('SELECT 1 FROM ticket_price_revisions WHERE place_id=? AND visitor_type=? AND original_text=? AND source_id=?',(r['id'],'general',value,src['source_id'])).fetchone():return 0
  j.con.execute('INSERT INTO ticket_price_revisions(place_id,visitor_type,original_text,source_id,verified_at) VALUES(?,?,?,?,?)',(r['id'],'general',value,src['source_id'],TODAY()))
  return 1
 return job.process(rows,each)
if __name__=='__main__':run_stage('ticket_price_revisions',work)
