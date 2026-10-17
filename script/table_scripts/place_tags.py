#!/usr/bin/env python3
"""Associate place with its preexisting or approved category tag; derived, not externally verified."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *
from tags import ALLOWED

def work(job):
 rows=job.rows('''SELECT p.id,p.category,p.place_name,s.country_id FROM places p JOIN cities ci ON ci.id=p.city_id
                   JOIN states s ON s.id=ci.state_id ORDER BY s.country_id,p.id''')
 def each(j,r):
  name=norm(r['category'])
  if name not in ALLOWED:return 0
  tag=j.con.execute('SELECT id FROM tags WHERE lower(tag_name)=? LIMIT 1',(name,)).fetchone()
  if not tag:return 0
  exists=j.con.execute('SELECT 1 FROM place_tags WHERE place_id=? AND tag_id=?',(r['id'],tag[0])).fetchone()
  if exists:return 0
  j.con.execute('INSERT OR IGNORE INTO place_tags(place_id,tag_id) VALUES(?,?)',(r['id'],tag[0]));return 1
 return job.process(rows,each)
if __name__=='__main__':run_stage('place_tags',work)
