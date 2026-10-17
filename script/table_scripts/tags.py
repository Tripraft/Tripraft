#!/usr/bin/env python3
"""Create a controlled tag for a place category only where category is meaningful; source is seed."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *
ALLOWED={'museum','heritage','park','beach','nature','landmark','attraction','restaurant','religious site','archaeological site','castle','fortress','gallery','waterfall','national park','garden','hiking','viewpoint','temple','mosque','church','market','monument','zoo','aquarium','historic site','historic urban area'}

def work(job):
 rows=job.rows('''SELECT p.id,p.category AS category,p.place_name,s.country_id FROM places p JOIN cities ci ON ci.id=p.city_id
                   JOIN states s ON s.id=ci.state_id ORDER BY s.country_id,p.id''')
 def each(j,r):
  name=norm(r['category'])
  if name not in ALLOWED:return 0
  pretty=name.title()
  if j.con.execute('SELECT 1 FROM tags WHERE lower(tag_name)=? COLLATE NOCASE',(pretty.lower(),)).fetchone():return 0
  j.con.execute('INSERT OR IGNORE INTO tags(tag_name) VALUES(?)',(pretty,));return 1
 return job.process(rows,each)
if __name__=='__main__':run_stage('tags',work)
