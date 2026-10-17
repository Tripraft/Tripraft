#!/usr/bin/env python3
"""Shared TripRaft helpers: audited, throttled, evidence-first table enrichment.
Python 3.10+, standard library only. Runs offline for --coverage and --list-tables.
This project is not a substitute for manual official-site verification.
"""
from __future__ import annotations
import argparse, datetime as dt, difflib, hashlib, html, json, math, os, random, re, shutil, sqlite3, sys, time, unicodedata
from pathlib import Path
from urllib import parse, request, error

WD='https://www.wikidata.org/w/api.php'
WP='https://en.wikipedia.org/w/api.php'
COMMONS='https://commons.wikimedia.org/w/api.php'
TODAY=lambda:dt.datetime.now(dt.timezone.utc).isoformat(timespec='seconds')
SAFE_STAGE={'countries','states','cities','places','photos','photo_attributions','tags','place_tags','place_hours_intervals','ticket_price_revisions','festivals','opening_hour_exceptions','place_access_events','airports'}
APP_MANAGED={'search_log','place_embeddings','provider_references','place_ratings_provenance','entity_codes','entity_aliases','code_reservation_events','batch_artifacts','batch_registry','data_sources','field_verifications','verification_evidence','unresolved_fields','data_change_log','opening_hours','ticket_prices','place_search_fts','v_top_search_queries'}

def norm(s):
 s=unicodedata.normalize('NFKD',str(s or '')).casefold();s=''.join(x for x in s if not unicodedata.combining(x))
 return re.sub(r'\s+',' ',re.sub('[^a-z0-9]+',' ',s)).strip()

def similarity(a,b):
 a,b=norm(a),norm(b)
 return difflib.SequenceMatcher(None,a,b).ratio() if a and b else 0

def values(e,p):
 out=[]
 for c in (e or {}).get('claims',{}).get(p,[]):
  if c.get('rank')=='deprecated':continue
  s=c.get('mainsnak',{})
  if s.get('snaktype')!='value':continue
  v=s.get('datavalue',{}).get('value')
  if v is not None:out.append(v)
 return out

def first_string(e,p):
 return next((v for v in values(e,p) if isinstance(v,str)),None)

def ids(e,p):
 return [v['id'] for v in values(e,p) if isinstance(v,dict) and re.fullmatch('Q[1-9][0-9]*',str(v.get('id','')))]

def coords(e):
 for v in values(e,'P625'):
  if isinstance(v,dict) and v.get('globe','').endswith('Q2'):
   try:
    a,b=float(v['latitude']),float(v['longitude'])
    if -90<=a<=90 and -180<=b<=180:return a,b
   except (TypeError,ValueError,KeyError):pass
 return None

def label(e):return e.get('labels',{}).get('en',{}).get('value') or next((x.get('value','') for x in e.get('labels',{}).values()),'')
def description(e):return e.get('descriptions',{}).get('en',{}).get('value','').strip()
def km(a,b,c,d):
 p1,p2=math.radians(a),math.radians(c);dl=math.radians(d-b)
 x=math.sin((p2-p1)/2)**2+math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
 return 12742*math.asin(min(1,math.sqrt(x)))

class SourceError(RuntimeError): pass
class Client:
 def __init__(self,contact,cache,interval=1.5,timeout=20,retries=3,ttl=14):
  if not (contact and ('@' in contact or contact.startswith('https://'))):raise ValueError('Use --contact email@example.com for Wikimedia API User-Agent')
  self.ua=f'TripRaftTableEnricher/1.0 ({contact}) Python-urllib'
  self.cache=Path(cache);self.cache.mkdir(parents=True,exist_ok=True)
  self.interval=max(.5,float(interval));self.timeout=float(timeout);self.retries=int(retries);self.ttl=int(ttl)*86400
  self.last=0;self.requests=0;self.cache_hits=0;self.errors=0
 def get(self,base,**params):
  url=base+'?'+parse.urlencode(dict(format='json',formatversion=2,**params),doseq=True)
  key=hashlib.sha256(url.encode()).hexdigest();file=self.cache/(key+'.json')
  if file.is_file() and time.time()-file.stat().st_mtime<self.ttl:
   try:self.cache_hits+=1;return json.loads(file.read_text(encoding='utf8'))
   except (OSError,ValueError):pass
  for attempt in range(self.retries+1):
   d=time.monotonic()-self.last
   if d<self.interval:time.sleep(self.interval-d)
   self.last=time.monotonic();self.requests+=1
   try:
    req=request.Request(url,headers={'User-Agent':self.ua,'Accept':'application/json'})
    with request.urlopen(req,timeout=self.timeout) as f:raw=f.read(4_000_001)
    if len(raw)>4_000_000:raise SourceError('Oversized response')
    doc=json.loads(raw)
    if doc.get('error'):
     code=doc['error'].get('code','')
     if code in ('maxlag','readonly','ratelimited'):raise error.HTTPError(url,503,code,{},None)
     raise SourceError(str(doc['error']))
    tmp=file.with_suffix('.tmp');tmp.write_text(json.dumps(doc,ensure_ascii=False),encoding='utf8');tmp.replace(file)
    return doc
   except error.HTTPError as exc:
    if exc.code in (400,401,403,404):raise SourceError(f'HTTP {exc.code} (not retryable)') from exc
    if exc.code not in (408,425,429,500,502,503,504):raise SourceError(f'HTTP {exc.code}') from exc
    ra=exc.headers.get('Retry-After') if exc.headers else None
    try:delay=min(180,max(0,float(ra)))
    except (TypeError,ValueError):delay=None
    err=f'HTTP {exc.code}'
   except (error.URLError,TimeoutError,ConnectionError,OSError) as exc:
    delay=None;err=str(exc)
   if attempt==self.retries:self.errors+=1;raise SourceError(err)
   sleep=delay if delay is not None else min(90,2**attempt*2+random.random())
   print(f'  API retry {attempt+1}/{self.retries} after {sleep:.1f}s: {err}',flush=True)
   time.sleep(sleep)
  raise SourceError('exhausted attempts')
 def search(self,s,n=7):return self.get(WD,action='wbsearchentities',search=s,language='en',type='item',limit=n).get('search',[])
 def entity(self,q):
  if not re.fullmatch('Q[1-9][0-9]*',str(q)):return None
  return self.get(WD,action='wbgetentities',ids=q,props='labels|descriptions|claims|sitelinks',languages='en').get('entities',{}).get(q)
 def page(self,title):
  if not title:return None
  obj=self.get(WP,action='query',titles=title,redirects=1,prop='extracts|pageprops',exintro=1,explaintext=1,exsentences=3)
  return next((x for x in obj.get('query',{}).get('pages',[]) if not x.get('missing')),None)
 def fileinfo(self,names,width=640):
  if not names:return []
  names=['File:'+re.sub(r'^(File:|Image:)','',n,flags=re.I) for n in names][:30]
  obj=self.get(COMMONS,action='query',prop='imageinfo',titles='|'.join(names),iiprop='url|size|extmetadata',iiurlwidth=width)
  return [p for p in obj.get('query',{}).get('pages',[]) if p.get('imageinfo')]
 def categoryfiles(self,cat,n=30):
  obj=self.get(COMMONS,action='query',list='categorymembers',cmtitle='Category:'+re.sub('^Category:','',cat,flags=re.I),cmtype='file',cmlimit=min(50,n),cmnamespace=6)
  return [p['title'] for p in obj.get('query',{}).get('categorymembers',[]) if p.get('ns')==6]

class Store:
 def __init__(self,db):
  self.path=Path(db);self.con=sqlite3.connect(self.path,timeout=30)
  self.con.row_factory=sqlite3.Row;self.con.execute('PRAGMA foreign_keys=ON');self.con.execute('PRAGMA busy_timeout=30000')
 def close(self):self.con.close()
 def src(self,url,title='',publisher='Wikidata',tier=2):
  if not url:return None
  self.con.execute('INSERT OR IGNORE INTO data_sources(url,source_title,publisher,authority_tier) VALUES(?,?,?,?)',(url,title,publisher,tier))
  return self.con.execute('SELECT id FROM data_sources WHERE url=?',(url,)).fetchone()[0]
 def write(self,table,rid,col,val,url,why='',status='partial',replace=False,publisher='Wikidata'):
  if val is None or val=='':return False
  if table not in ('countries','states','cities','places','airports'):raise ValueError('unsupported write table')
  # Strict whitelist rather than arbitrary SQL identifiers.
  allowed={'countries':{'iso2','iso3','iso_numeric','currency_code','calling_code','capital','region'},'states':{'iso3166_2','division_type'},'cities':{'latitude','longitude','locality_type'},'places':{'wikidata_id','name_english','latitude','longitude','ai_summary','official_website','category','address','osm_id','locality_type','state_name'},'airports':{'iata_code','icao_code','latitude','longitude','official_website'}}
  if col not in allowed[table]:raise ValueError('column not allowed '+table+'.'+col)
  row=self.con.execute(f'SELECT {col} FROM {table} WHERE id=?',(rid,)).fetchone()
  if row is None:return False
  old=row[0]
  if old not in ('',None):
   if str(old)!=str(val):self.unresolved(table,rid,col,'CONFLICT_EXISTING',f'existing={str(old)[:180]}; candidate={str(val)[:180]}')
   # Never overwrite existing research; --force only revisits checkpoints.
   return False
  sid=self.src(url,publisher=publisher)
  self.con.execute(f'UPDATE {table} SET {col}=?,updated_at=? WHERE id=?',(val,TODAY(),rid))
  self.con.execute('INSERT INTO data_change_log(batch_id,table_name,record_id,column_name,old_value,new_value,change_type,source_id,notes) VALUES(?,?,?,?,?,?,?,?,?)',
   (self.batch,table,rid,col,None if old is None else str(old),str(val),'CORRECTED' if old else 'NULL_FILLED',sid,why[:400]))
  v=self.con.execute('INSERT INTO field_verifications(batch_id,entity_type,entity_id,source_table,column_name,accepted_value,source_id,verification_status,notes) VALUES(?,?,?,?,?,?,?,?,?)',
   (self.batch,{'countries':'COUNTRY','states':'STATE','cities':'CITY','places':'PLACE','airports':'AIRPORT'}[table],rid,table,col,str(val),sid,status,why[:500]))
  if sid:self.con.execute('INSERT OR IGNORE INTO verification_evidence(field_verification_id,source_id,evidence_excerpt,field_value,observed_at) VALUES(?,?,?,?,?)',(v.lastrowid,sid,why[:400],str(val),TODAY()))
  return True
 def unresolved(self,table,rid,col,reason,details=''):
  self.con.execute('INSERT INTO unresolved_fields(batch_id,source_table,record_id,column_name,reason_code,details) VALUES(?,?,?,?,?,?) ON CONFLICT(batch_id,source_table,record_id,column_name) DO UPDATE SET reason_code=excluded.reason_code,details=excluded.details',
   (self.batch,table,rid,col,reason,str(details)[:1000]))

class Job:
 def __init__(self,opts,stage):
  self.o=opts;self.stage=stage
  self.db=select_db(opts)
  self.store=Store(self.db);self.con=self.store.con
  self.check=sqlite3.connect(str(self.db)+'.checkpoints.sqlite3',timeout=30)
  self.check.execute('CREATE TABLE IF NOT EXISTS completed(stage TEXT NOT NULL,record_id INTEGER NOT NULL,outcome TEXT NOT NULL,updated_at TEXT NOT NULL,PRIMARY KEY(stage,record_id))')
  self.check.commit()
  self.store.batch=f'TABLE-{stage}-{dt.datetime.now(dt.timezone.utc):%Y%m%dT%H%M%SZ}'
  self.client=Client(opts.contact,Path(str(self.db)+'.wiki_cache'),interval=opts.interval,timeout=opts.timeout,retries=opts.retries) if opts.contact else None
  self.events=Path(str(self.db)+'.events.jsonl')
  self.countries=self.resolve_countries()
 def resolve_countries(self):
  if self.o.country:
   rows=self.con.execute('SELECT id,country_name FROM countries WHERE country_name=? COLLATE NOCASE',(self.o.country,)).fetchall()
   if not rows:raise ValueError('Country not found: '+self.o.country)
   return [x['id'] for x in rows]
  if self.o.all:return None
  return None
 def rows(self,query):
  data=list(self.con.execute(query))
  if self.countries is not None:data=[x for x in data if x['country_id'] in self.countries]
  return data
 def event(self,kind,**kv):
  doc={'at':TODAY(),'stage':self.stage,'event':kind,**kv}
  with self.events.open('a',encoding='utf8') as f:f.write(json.dumps(doc,ensure_ascii=False,default=str)+'\n')
 def process(self,rows,handler):
  rows=list(rows);total=len(rows);done=0;skip=0;failed=0;stopped=False
  completed={id_:outcome for id_,outcome in self.check.execute('SELECT record_id,outcome FROM completed WHERE stage=?',(self.stage,))}
  stopfile=Path(str(self.db)+'.stop')
  progress=Path(str(self.db)+'.progress.json')
  def snapshot(name='',last=''):
   data=dict(stage=self.stage,total=total,processed=done,skipped=skip,failed=failed,last_record=name,last_outcome=last,updated_at=TODAY(),api_requests=self.client.requests if self.client else 0)
   temp=progress.with_suffix('.tmp');temp.write_text(json.dumps(data,indent=2),encoding='utf8');temp.replace(progress)
  snapshot()
  print(f'[{self.stage}] {total} candidate rows; output={self.db}',flush=True)
  for row in rows:
   if stopfile.exists():
    stopped=True
    print('Stop requested: saved checkpoints; rerun to resume',flush=True)
    break
   rid=row['id']
   prev=completed.get(rid)
   if prev and not self.o.force and prev in ('success','no_match','no_new_values'):
    skip+=1;continue
   if self.o.limit and done>=self.o.limit:break
   labelx=row['place_name'] if 'place_name' in row.keys() else row['city_name'] if 'city_name' in row.keys() else row['state_name'] if 'state_name' in row.keys() else row['country_name'] if 'country_name' in row.keys() else str(rid)
   print(f'[{self.stage}] {done+skip+1}/{total} id={rid} {labelx}',flush=True)
   try:
    self.con.execute('SAVEPOINT each_row')
    changes=handler(self,row) or 0
    self.con.execute('RELEASE SAVEPOINT each_row');self.con.commit()
    outcome='success' if changes else 'no_match'
    self.check.execute('INSERT OR REPLACE INTO completed(stage,record_id,outcome,updated_at) VALUES(?,?,?,?)',(self.stage,rid,outcome,TODAY()))
    self.check.commit();done+=1
    self.event('processed',record_id=rid,name=labelx,changes=changes,outcome=outcome)
    snapshot(labelx,outcome)
    print(f'  -> {changes} changes; status={outcome}',flush=True)
   except (SourceError,sqlite3.Error,ValueError,KeyError,TypeError) as exc:
    try:self.con.execute('ROLLBACK TO SAVEPOINT each_row');self.con.execute('RELEASE SAVEPOINT each_row')
    except sqlite3.Error:pass
    self.con.rollback();failed+=1
    self.check.execute('INSERT OR REPLACE INTO completed(stage,record_id,outcome,updated_at) VALUES(?,?,?,?)',(self.stage,rid,'retryable',TODAY()));self.check.commit()
    self.event('retryable_failure',record_id=rid,error=str(exc))
    snapshot(labelx,'retryable')
    print('  -> RETRYABLE ERROR',str(exc)[:200],flush=True)
  snapshot(last='stopped' if stopped else 'limited' if self.o.limit and done>=self.o.limit and done+skip<total else 'stage_complete')
  print(f'[{self.stage}] processed={done}, skipped_checkpoint={skip}, retryable_failures={failed}, requests={self.client.requests if self.client else 0}, cache_hits={self.client.cache_hits if self.client else 0}',flush=True)
  return {'processed':done,'skipped':skip,'failed':failed,'total':total}
 def close(self):self.store.close();self.check.close()

def select_db(opts):
 source=Path(opts.db).expanduser() if opts.db else None
 if source is None:
  here=Path(__file__).resolve()
  candidates=[Path.cwd()/'data/catalog/tripraft_places.db',*(root/'data/catalog/tripraft_places.db' for root in (here.parent, *here.parents))]
  source=next((p for p in candidates if p.exists()),None)
  if source is None:raise FileNotFoundError('Database not found. Use --db C:\\Tripraft\\data\\catalog\\tripraft_places.db')
 if not source.exists():raise FileNotFoundError(str(source))
 if opts.in_place:return source.resolve()
 output=Path(opts.output).expanduser() if opts.output else source.with_name(source.stem+'.table_enriched.db')
 if not output.exists():
  output.parent.mkdir(parents=True,exist_ok=True)
  with sqlite3.connect(str(source)) as src,sqlite3.connect(str(output)) as dest:src.backup(dest)
  print(f'Created working copy: {output}',flush=True)
 return output.resolve()

def base_args(parser):
 parser.add_argument('--db',help='Input SQLite (defaults to auto-detected data/catalog/tripraft_places.db)')
 parser.add_argument('--output',help='Enriched copy; reused on subsequent table runs')
 parser.add_argument('--in-place',action='store_true',help='EXPERT: writes directly to --db, make backup first')
 parser.add_argument('--country',help='Process only this country, e.g. Algeria')
 parser.add_argument('--all',action='store_true',help='Process all countries (default if no --country)')
 parser.add_argument('--limit',type=int,default=0,help='Maximum new records attempted in this table')
 parser.add_argument('--force',action='store_true',help='Revisit completed records, still idempotent')
 parser.add_argument('--contact',help='Email or HTTPS URL for Wikimedia User-Agent (required for online tables)')
 parser.add_argument('--interval',type=float,default=1.5,help='Seconds minimum between Wikimedia requests')
 parser.add_argument('--timeout',type=float,default=20)
 parser.add_argument('--retries',type=int,default=3)
 return parser

def run_stage(stage,func,online=False):
 p=base_args(argparse.ArgumentParser(description='TripRaft table: '+stage));o=p.parse_args()
 if online and not o.contact:p.error('--contact email@example.com is required for live Wikimedia API research')
 job=Job(o,stage)
 try:return func(job)
 finally:job.close()

def resolve_entity(job,name,country=None,state=None,qid=None,kind='place',city=None,gps=None):
 c=job.client
 if not c:raise SourceError('Missing Wikimedia contact')
 if qid:
  e=c.entity(qid)
  if e and similarity(name,label(e))>=.57:
   x=coords(e)
   if gps and x and km(*gps,*x)>35:return None,'Existing QID conflicts with known GPS'
   return e,'existing Wikidata ID with name cross-check'
 if not name:return None,'no name'
 found=c.search(name,n=8)
 if city and kind=='place':
  found+=c.search(f'{name} {city}',n=8)
 found=list({x['id']:x for x in found if x.get('id')}.values())
 candidates=[]
 for x in found:
  score=max(similarity(name,x.get('label')),similarity(name,x.get('match',{}).get('text')))
  if score<.85:continue
  e=c.entity(x['id'])
  if not e:continue
  score=max(score,similarity(name,label(e)))
  if score<.85:continue
  cc=ids(e,'P17')
  if country and cc:
   if country not in cc:continue
   score+=.15
  elif country and not cc:score-=.15
  if state and state in ids(e,'P131'):score+=.07
  x=coords(e)
  if gps and x:
   distance=km(*gps,*x)
   if distance>6:continue
   score+=.2
  elif gps and not x:continue
  elif kind=='place' and city:
   desc=norm(description(e))
   city_name=norm(city)
   city_ok=bool(city_name and re.search(r'(?<!\w)'+re.escape(city_name)+r'(?!\w)',desc))
   if not city_ok:
    for parent_qid in ids(e,'P131')[:2]:
     parent=c.entity(parent_qid)
     if parent and norm(label(parent))==city_name:city_ok=True;break
   if not city_ok:continue
   score+=.08
  candidates.append((score,e))
 if not candidates:return None,'No safely matched Wikidata entity'
 candidates.sort(key=lambda x:x[0],reverse=True)
 if len(candidates)>1 and candidates[0][0]-candidates[1][0]<.08:return None,'Ambiguous matches'
 if country and country not in ids(candidates[0][1],'P17') and kind not in ('country','state'):
  return None,'No verified country association'
 return candidates[0][1],f'Wikidata name/country match score {candidates[0][0]:.2f}'

def country_qid(job,name):
 found=job.client.search(name,n=7)
 exact=[x for x in found if norm(x.get('label'))==norm(name)]
 for x in exact:
  e=job.client.entity(x['id'])
  if e and (first_string(e,'P297') or first_string(e,'P298')):return e['id']
 return None

def country_context(job,cid):
 row=job.con.execute('SELECT country_name,iso2 FROM countries WHERE id=?',(cid,)).fetchone()
 qid=country_qid(job,row['country_name'])
 return row['country_name'],qid,row['iso2']
