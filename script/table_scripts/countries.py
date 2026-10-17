#!/usr/bin/env python3
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 rows=job.rows('SELECT id,id AS country_id,country_name,iso2,iso3 FROM countries ORDER BY country_name')
 def each(j,r):
  current=j.con.execute('SELECT iso2,iso3,iso_numeric,calling_code,capital,currency_code FROM countries WHERE id=?',(r['id'],)).fetchone()
  if all(v not in (None,'') for v in current):return 0
  qid=country_qid(j,r['country_name'])
  if not qid:j.store.unresolved('countries',r['id'],'iso2','NO_SAFE_MATCH','Country entity could not be independently matched');return 0
  e=j.client.entity(qid);url='https://www.wikidata.org/wiki/'+qid
  n=0
  rules={'iso2':('P297',r'[A-Z]{2}'),'iso3':('P298',r'[A-Z]{3}'),'iso_numeric':('P299',r'\d{3}'),'calling_code':('P474',r'\+\d[0-9 +()-]*')}
  for col,(prop,pat) in rules.items():
   vals=[v for v in values(e,prop) if isinstance(v,str) and re.fullmatch(pat,v)]
   if len(vals)==1:n+=j.store.write('countries',r['id'],col,vals[0],url,f'Wikidata {prop} property')
  # Capital and currency must be mapped from Q-ids to a single label, not invented.
  for col,prop in [('capital','P36'),('currency_code','P38')]:
   qs=ids(e,prop)
   if len(qs)!=1:continue
   x=j.client.entity(qs[0])
   if col=='capital' and x:n+=j.store.write('countries',r['id'],col,label(x),url+'#P36','Single Wikidata capital P36')
   if col=='currency_code' and x:
    cv=first_string(x,'P498')
    if cv and re.fullmatch('[A-Z]{3}',cv):n+=j.store.write('countries',r['id'],col,cv,url+'#P38','Currency P38 with ISO 4217 P498')
  return n
 return job.process(rows,each)
if __name__=='__main__':run_stage('countries',work,online=True)
