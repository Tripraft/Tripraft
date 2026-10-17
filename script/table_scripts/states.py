#!/usr/bin/env python3
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 rows=job.rows('''SELECT s.id,s.country_id,s.state_name,c.country_name,c.iso2
                   FROM states s JOIN countries c ON c.id=s.country_id ORDER BY c.country_name,s.state_name''')
 contexts={}
 def each(j,r):
  cid=r['country_id']
  if cid not in contexts:contexts[cid]=country_qid(j,r['country_name'])
  cq=contexts[cid]
  if not cq:j.store.unresolved('states',r['id'],'iso3166_2','UNMATCHED_COUNTRY');return 0
  e,why=resolve_entity(j,r['state_name'],country=cq,kind='state')
  if not e:return j.store.unresolved('states',r['id'],'iso3166_2','NO_SAFE_MATCH',why) or 0
  # Strong geographic cross-check: ISO subdivision code must belong to this country.
  code=first_string(e,'P300')
  if code and r['iso2'] and code.startswith(r['iso2']+'-'):
   return int(j.store.write('states',r['id'],'iso3166_2',code,'https://www.wikidata.org/wiki/'+e['id'],'ISO 3166-2 property P300; matched country prefix'))
  j.store.unresolved('states',r['id'],'iso3166_2','NO_VERIFIABLE_CODE','Matched item lacks same-country ISO 3166-2 code');return 0
 return job.process(rows,each)
if __name__=='__main__':run_stage('states',work,online=True)
