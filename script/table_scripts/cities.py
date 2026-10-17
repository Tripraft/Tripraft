#!/usr/bin/env python3
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 rows=job.rows('''SELECT ci.id,ci.city_name,ci.latitude,ci.longitude,s.state_name,s.country_id,c.country_name
                   FROM cities ci JOIN states s ON s.id=ci.state_id JOIN countries c ON c.id=s.country_id
                   ORDER BY c.country_name,s.state_name,ci.city_name''')
 contexts={}
 def each(j,r):
  cid=r['country_id']
  if cid not in contexts:contexts[cid]=country_qid(j,r['country_name'])
  cq=contexts[cid]
  if not cq:j.store.unresolved('cities',r['id'],'latitude','COUNTRY_UNMATCHED');return 0
  e,why=resolve_entity(j,r['city_name'],country=cq,kind='city')
  if not e:j.store.unresolved('cities',r['id'],'latitude','NO_SAFE_MATCH',why);return 0
  xy=coords(e)
  if not xy:return 0
  url='https://www.wikidata.org/wiki/'+e['id'];n=0
  # Never overwrite location discrepancies; do not fill one coordinate if its existing mate conflicts.
  if r['latitude'] is not None and r['longitude'] is not None and km(r['latitude'],r['longitude'],*xy)>35:
   j.store.unresolved('cities',r['id'],'latitude','COORDINATE_CONFLICT',f'Wikidata: {xy}');return 0
  n+=j.store.write('cities',r['id'],'latitude',round(xy[0],7),url,'Wikidata P625, name and country matched')
  n+=j.store.write('cities',r['id'],'longitude',round(xy[1],7),url,'Wikidata P625, name and country matched')
  return n
 return job.process(rows,each)
if __name__=='__main__':run_stage('cities',work,online=True)
