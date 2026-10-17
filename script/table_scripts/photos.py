#!/usr/bin/env python3
"""Wikimedia Commons licensed photo import. P18 -> identity-linked; category -> needs review."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *
BANNED=re.compile(r'\b(map|plan|diagram|logo|icon|poster|flag|coat of arms|seal|drawing|painting|portrait|postcard|chart)\b',re.I)
LIC_OK=re.compile(r'^(CC0|PUBLIC DOMAIN|PD[- ]|CC BY(?:-SA)?(?:[ -]?\d(?:\.\d)?)?|CC-BY(?:-SA)?(?:-[\d.]+)?)',re.I)
LIC_BAD=re.compile(r'\bNC\b|\bND\b|NON.?COMMERCIAL|NO.?DERIV',re.I)
def clean(t):return re.sub(r'\s+',' ',html.unescape(re.sub(r'<[^>]+>',' ',str(t or '')))).strip()[:350]
def metadata(i):
 x=i.get('extmetadata',{})
 def get(k):return clean(x.get(k,{}).get('value',''))
 lic=get('LicenseShortName');art=get('Artist') or get('Attribution')
 if not lic or LIC_BAD.search(lic) or not LIC_OK.match(lic):return None
 if 'BY' in lic.upper() and not art:return None
 return dict(license=lic,author=art,credit=get('Attribution') or art,license_url=get('LicenseUrl'))
def work(job):
 rows=job.rows('''SELECT p.id,p.place_name,p.wikidata_id,ci.city_name,s.country_id,c.country_name
                   FROM places p JOIN cities ci ON ci.id=p.city_id JOIN states s ON s.id=ci.state_id
                   JOIN countries c ON c.id=s.country_id ORDER BY c.country_name,ci.city_name,p.place_name''')
 contexts={}
 def each(j,r):
  cid=r['country_id']
  if cid not in contexts:contexts[cid]=country_qid(j,r['country_name'])
  e,why=resolve_entity(j,r['place_name'],country=contexts[cid],qid=r['wikidata_id'],city=r['city_name'])
  if not e:j.store.unresolved('photos',r['id'],'photo_url','NO_SAFE_PLACE_MATCH',why);return 0
  max_images=10;picks=[]
  for filename in values(e,'P18'):
   if isinstance(filename,str):picks.append(('File:'+filename,'P18'))
  cat=e.get('sitelinks',{}).get('commonswiki',{}).get('title','')
  if not cat.startswith('Category:'):cat=first_string(e,'P373')
  if cat:
   for filename in j.client.categoryfiles(cat,min(30,max_images*3)):
    picks.append((filename,'category'))
  seen=set();unique=[]
  for file,kind in picks:
   key=file.replace('_',' ').lower()
   if key in seen:continue
   seen.add(key);unique.append((file,kind))
  picks=unique
  picks=[(p,kind) for p,kind in picks if re.search(r'\.(jpg|jpeg|png|webp|tif|tiff)$',p,re.I) and not BANNED.search(p)]
  if not picks:return 0
  lookup={p.replace('_',' ').lower():kind for p,kind in picks}
  changes=0
  # Separate API query per <=25 images; properly batch imageinfo.
  for start in range(0,min(len(picks),40),25):
   pages=j.client.fileinfo([p for p,k in picks[start:start+25]])
   for page in pages:
    title=page.get('title','')
    kind=lookup.get(title.replace('_',' ').lower())
    if not kind:continue
    i=page['imageinfo'][0];meta=metadata(i)
    photo=i.get('url','');thumbnail=i.get('thumburl') or photo
    if not meta or not photo.startswith('https://') or not thumbnail.startswith('https://'):continue
    width,height=i.get('width'),i.get('height')
    if not (isinstance(width,int) and width>0 and isinstance(height,int) and height>0):continue
    source_url='https://commons.wikimedia.org/wiki/'+parse.quote(title.replace(' ','_'),safe=':/()')
    if j.con.execute('SELECT 1 FROM photos WHERE place_id=? AND (commons_file_name=? OR photo_source_url=?)',(r['id'],title,source_url)).fetchone():continue
    count=j.con.execute('SELECT COUNT(*) FROM photos WHERE place_id=? AND photo_status IN (\'verified\',\'needs_review\')',(r['id'],)).fetchone()[0]
    if count>=max_images:break
    status='verified' if kind=='P18' else 'needs_review'
    primary=int(kind=='P18' and not j.con.execute('SELECT 1 FROM photos WHERE place_id=? AND is_primary=1',(r['id'],)).fetchone())
    cur=j.con.execute('''INSERT INTO photos(place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,
          photo_license,photo_source_url,photo_status,is_primary,sort_order,commons_file_name,image_width,image_height)
          VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',(r['id'],title[5:].rsplit('.',1)[0],meta['license'],thumbnail,photo,meta['author'],meta['license'],source_url,status,primary,count+1,title,width,height))
    pid=cur.lastrowid
    j.con.execute('INSERT OR IGNORE INTO photo_attributions(photo_id,commons_file_page,license_url,attribution_text,notes) VALUES(?,?,?,?,?)',
      (pid,source_url,meta['license_url'],f"{meta['credit']} / {meta['license']} / {source_url}",'Wikidata P18 photo association' if kind=='P18' else 'Commons category association; manually review depiction'))
    sid=j.store.src(source_url,title,'Wikimedia Commons',2)
    vf=j.con.execute('INSERT INTO field_verifications(batch_id,entity_type,entity_id,source_table,column_name,accepted_value,source_id,verification_status,notes) VALUES(?,?,?,?,?,?,?,?,?)',
       (j.store.batch,'PHOTO',pid,'photos','photo_url',photo,sid,'verified' if kind=='P18' else 'needs_review',f'Commons metadata; association={kind}'))
    j.con.execute('INSERT OR IGNORE INTO verification_evidence(field_verification_id,source_id,evidence_excerpt,field_value,observed_at) VALUES(?,?,?,?,?)',
       (vf.lastrowid,sid,f"license={meta['license']}; association={kind}",photo,TODAY()))
    j.con.execute('INSERT INTO data_change_log(batch_id,table_name,record_id,column_name,new_value,change_type,source_id,notes) VALUES(?,?,?,?,?,?,?,?)',
       (j.store.batch,'photos',pid,'photo_url',photo,'PHOTO_ADDED',sid,'Image identity review required' if kind=='category' else 'Wikidata P18'))
    changes+=1
  if not changes:j.store.unresolved('photos',r['id'],'photo_url','NO_NEW_LICENSED_IMAGE','No new qualified Wikimedia Commons image; existing photos preserved')
  return changes
 return job.process(rows,each)
if __name__=='__main__':run_stage('photos',work,online=True)
