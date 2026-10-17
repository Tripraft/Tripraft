#!/usr/bin/env python3
"""Backfill photo attribution rows only when an existing Commons source/license permits it."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 rows=job.rows('''SELECT p.id,p.photo_title,p.photo_author,p.photo_license,p.photo_source_url,p.place_id,s.country_id
                   FROM photos p JOIN places pl ON pl.id=p.place_id JOIN cities ci ON ci.id=pl.city_id
                   JOIN states s ON s.id=ci.state_id
                   WHERE p.photo_source_url LIKE 'https://commons.wikimedia.org/%' AND p.photo_license IS NOT NULL
                   ORDER BY s.country_id,p.id''')
 def each(j,r):
  if j.con.execute('SELECT 1 FROM photo_attributions WHERE photo_id=?',(r['id'],)).fetchone():return 0
  if not r['photo_source_url'] or not r['photo_license']:return 0
  credit=' / '.join(x for x in (r['photo_author'],r['photo_license'],r['photo_source_url']) if x)
  j.con.execute('INSERT OR IGNORE INTO photo_attributions(photo_id,commons_file_page,attribution_text,notes) VALUES(?,?,?,?)',
    (r['id'],r['photo_source_url'],credit,'License URL unavailable; human review of Commons page still recommended'))
  return 1
 return job.process(rows,each)
if __name__=='__main__':run_stage('photo_attributions',work,online=False)
