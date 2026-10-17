#!/usr/bin/env python3
"""Offline schema and table-writer integration tests, mock API responses, no network."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import tempfile,sqlite3,os,argparse,unittest
from types import SimpleNamespace
from pathlib import Path
from unittest import mock
from core import Job
import places,photos,place_hours_intervals

class FakeClient:
 requests=0;cache_hits=0
 def fileinfo(self,files):
  return [{'title':x if x.startswith('File:') else 'File:'+x,'imageinfo':[{'url':'https://upload.wikimedia.org/a.jpg','thumburl':'https://upload.wikimedia.org/b.jpg','width':1234,'height':900,'extmetadata':{'LicenseShortName':{'value':'CC BY-SA 4.0'},'Artist':{'value':'A. Photographer'},'LicenseUrl':{'value':'https://creativecommons.org/licenses/by-sa/4.0/'}}}]} for x in files]
 def categoryfiles(self,*args,**kw):return []

class Tests(unittest.TestCase):
 def setUp(self):
  if not os.environ.get('TRIPRAFT_TEST_DB'):self.skipTest('--db required')
  self.tmp=tempfile.TemporaryDirectory()
  self.db=Path(self.tmp.name)/'db.sqlite'
  with sqlite3.connect(os.environ['TRIPRAFT_TEST_DB']) as src,sqlite3.connect(self.db) as dest:src.backup(dest)
  self.opts=SimpleNamespace(db=str(self.db),output=None,in_place=True,country='Algeria',all=False,limit=1,force=False,contact='test@example.org',interval=1.5,timeout=5,retries=0)
 def tearDown(self):
  if hasattr(self,'tmp'):self.tmp.cleanup()
 def job(self,stage):
  x=Job(self.opts,stage);x.client=FakeClient();return x
 def entity(self):
  return {'id':'Q9988776655443322','labels':{'en':{'value':'Kasbah of Algiers'}},'descriptions':{'en':{'value':'historic fortress'}},'claims':{'P18':[{'rank':'normal','mainsnak':{'snaktype':'value','datavalue':{'value':'Kasbah of Algiers photo 1.jpg'}}},{'rank':'normal','mainsnak':{'snaktype':'value','datavalue':{'value':'Kasbah of Algiers photo 2.jpg'}}}]}}
 def test_places(self):
  j=self.job('places')
  try:
   existing=j.con.execute("SELECT wikidata_id FROM places WHERE place_name='Kasbah of Algiers'").fetchone()[0]
   entity=self.entity();entity['id']=existing
   with mock.patch.object(j.client,'entity',return_value=entity,create=True):
    x=places.work(j)
   self.assertEqual(x['failed'],0)
   row=j.con.execute("SELECT id,wikidata_id,ai_summary FROM places WHERE place_name='Kasbah of Algiers'").fetchone()
   self.assertEqual(row['wikidata_id'],'Q662102')  # preserve existing identity; conflicts are audited
   self.assertIn('historic fortress',row['ai_summary'])
   self.assertEqual(j.con.execute('PRAGMA foreign_key_check').fetchall(),[])
  finally:j.close()
 def test_photos_primary_and_resume(self):
  j=self.job('photos')
  try:
   with mock.patch.object(photos,'country_qid',return_value='Q1'),mock.patch.object(photos,'resolve_entity',return_value=(self.entity(),'offline mock')):
    x=photos.work(j)
    self.assertEqual(x['failed'],0)
    pid=j.con.execute("SELECT id FROM places WHERE place_name='Kasbah of Algiers'").fetchone()[0]
    self.assertEqual(j.con.execute('SELECT COUNT(*) FROM photos WHERE place_id=? AND photo_status=\'verified\' ',(pid,)).fetchone()[0],2)
    self.assertEqual(j.con.execute('SELECT COUNT(*) FROM photos WHERE place_id=? AND is_primary=1',(pid,)).fetchone()[0],1)
    self.opts.force=True;photos.work(j)
    self.assertEqual(j.con.execute('SELECT COUNT(*) FROM photos WHERE place_id=? AND photo_status=\'verified\' ',(pid,)).fetchone()[0],2)
    self.assertEqual(j.con.execute('SELECT COUNT(*) FROM photo_attributions WHERE photo_id IN (SELECT id FROM photos WHERE place_id=?)',(pid,)).fetchone()[0],2)
    self.assertEqual(j.con.execute('PRAGMA foreign_key_check').fetchall(),[])
  finally:j.close()
 def test_hours(self):
  self.opts.country=None;self.opts.limit=1
  j=self.job('place_hours_intervals')
  try:
   with mock.patch.object(place_hours_intervals,'existing_osm',return_value=({'tags':{'opening_hours':'Mo-Fr 09:00-18:00'}},'https://api.openstreetmap.org/api/0.6/node/123')):
    x=place_hours_intervals.work(j)
   self.assertEqual(x['failed'],0)
   self.assertEqual(j.con.execute('SELECT COUNT(*) FROM place_hours_intervals').fetchone()[0],5)
  finally:j.close()

if __name__=='__main__':
 p=argparse.ArgumentParser(add_help=False);p.add_argument('--db');known,rest=p.parse_known_args()
 if known.db:os.environ['TRIPRAFT_TEST_DB']=known.db
 unittest.main(argv=['integration_tests.py']+rest)
