"""Very limited OpenStreetMap element lookups for EXISTING osm_id values only.
Does not geocode, search, batch query public Nominatim, or scrape arbitrary sites.
Respect OSM attribution and bulk access policy; do not start parallel OSM workers.
"""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import re,json,time,hashlib
from pathlib import Path
from urllib import request,error
from core import SourceError

def existing_osm(job,osm_id):
 m=re.fullmatch(r'(node|way|relation)/(\d+)',str(osm_id or ''))
 if not m:return None
 typ,num=m.groups();url=f'https://api.openstreetmap.org/api/0.6/{typ}/{num}.json'
 cache=Path(str(job.db)+'.osm_cache');cache.mkdir(exist_ok=True)
 file=cache/(hashlib.sha256(url.encode()).hexdigest()+'.json')
 if file.exists() and time.time()-file.stat().st_mtime<7*86400:
  return json.loads(file.read_text(encoding='utf8'))['elements'][0],url
 req=request.Request(url,headers={'User-Agent':f'TripRaftTableEnricher/1.0 ({job.o.contact})','Accept':'application/json'})
 for i in range(job.o.retries+1):
  try:
   time.sleep(max(1.5,job.o.interval))
   with request.urlopen(req,timeout=job.o.timeout) as res:doc=json.loads(res.read(500_000))
   elements=doc.get('elements') or []
   if not elements:raise SourceError('OSM element not found')
   file.write_text(json.dumps(doc),encoding='utf8')
   return elements[0],url
  except error.HTTPError as exc:
   if exc.code in (403,404,410):raise SourceError('OSM HTTP '+str(exc.code))
   if i==job.o.retries:raise SourceError('OSM HTTP '+str(exc.code))
   retry=exc.headers.get('Retry-After') if exc.headers else None
   try:sleep=min(120,float(retry))
   except (ValueError,TypeError):sleep=min(90,5*2**i)
   time.sleep(sleep)
  except (error.URLError,TimeoutError,ConnectionError,OSError) as exc:
   if i==job.o.retries:raise SourceError('OSM request error: '+str(exc))
   time.sleep(min(90,5*2**i))
 return None

def parse_hours(raw):
 """Only uncomplicated OSM patterns; 0=Monday ... 6=Sunday. Unparsed rules remain unresolved."""
 if not raw or any(x in raw for x in ('PH','SH','sunrise','sunset','off','open','24/7','week','week ','weekend','+','[',']')):return None
 week=['Mo','Tu','We','Th','Fr','Sa','Su'];out=[]
 for part in raw.split(';'):
  m=re.fullmatch(r'\s*(Mo|Tu|We|Th|Fr|Sa|Su)(?:-(Mo|Tu|We|Th|Fr|Sa|Su))?(?:,\s*(Mo|Tu|We|Th|Fr|Sa|Su))*\s+((?:[01]\d|2[0-3]):[0-5]\d)-((?:[01]\d|2[0-3]):[0-5]\d)\s*',part)
  if not m:return None
  # Refuse comma clauses we can't unambiguously tokenize.
  daytext=part.split()[0]
  if ',' in daytext:return None
  left=week.index(m.group(1));right=week.index(m.group(2)) if m.group(2) else left
  days=list(range(left,right+1)) if left<=right else list(range(left,7))+list(range(0,right+1))
  op,cl=m.group(4),m.group(5)
  for d in days:out.append((d,op,cl,int(cl<op)))
 return out
