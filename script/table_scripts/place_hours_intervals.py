#!/usr/bin/env python3
"""Canonical hours: ONLY parse simple schedules from existing verified OSM element IDs."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *
from osm_known import existing_osm,parse_hours

def work(job):
 rows=job.rows('''SELECT p.id,p.osm_id,p.place_name,s.country_id FROM places p
                   JOIN cities ci ON ci.id=p.city_id JOIN states s ON s.id=ci.state_id
                   WHERE p.osm_id IS NOT NULL ORDER BY s.country_id,p.id''')
 def each(j,r):
  result=existing_osm(j,r['osm_id'])
  if not result:return 0
  data,url=result;hours=data.get('tags',{}).get('opening_hours')
  parsed=parse_hours(hours)
  if not parsed:
   j.store.unresolved('place_hours_intervals',r['id'],'opens_local','OSM_HOURS_MISSING_OR_COMPLEX',str(hours));return 0
  sid=j.store.src(url,'OSM existing element','OpenStreetMap contributors',3)
  n=0
  for day,op,cl,mid in parsed:
   existing=j.con.execute('SELECT id FROM place_hours_intervals WHERE place_id=? AND weekday=? AND opens_local=? AND closes_local=? AND valid_from IS NULL',(r['id'],day,op,cl)).fetchone()
   if existing:continue
   j.con.execute('INSERT INTO place_hours_intervals(place_id,weekday,opens_local,closes_local,spans_midnight,source_id,verified_at) VALUES(?,?,?,?,?,?,?)',(r['id'],day,op,cl,mid,sid,TODAY()))
   n+=1
  return n
 return job.process(rows,each)
if __name__=='__main__':run_stage('place_hours_intervals',work,online=True)
