#!/usr/bin/env python3
"""Offline safety regression checks against a supplied TripRaft database; makes a temporary copy."""
from __future__ import annotations
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import argparse,os,sqlite3,tempfile,unittest
from pathlib import Path
from core import Store,coords,norm,similarity,values
from osm_known import parse_hours
from photos import metadata

class Tests(unittest.TestCase):
 def test_norm(self):self.assertEqual(norm('Ghardaïa'),'ghardaia')
 def test_similarity(self):self.assertGreater(similarity('Berat Castle','Berat castle'),.95)
 def test_parse_hours(self):
  x=parse_hours('Mo-Fr 09:00-17:00; Sa 10:00-14:00')
  self.assertEqual(len(x),6);self.assertEqual(x[0],(0,'09:00','17:00',0))
 def test_reject_complex_hours(self):self.assertIsNone(parse_hours('PH off; Mo-Fr 09:00-17:00'))
 def test_overnight(self):self.assertEqual(parse_hours('Sa 20:00-02:00'),[(5,'20:00','02:00',1)])
 def test_licenses(self):
  f=lambda lic,artist:{'extmetadata':{'LicenseShortName':{'value':lic},'Artist':{'value':artist}}}
  self.assertIsNotNone(metadata(f('CC BY-SA 4.0','Author')))
  self.assertIsNone(metadata(f('CC BY-NC 4.0','Author')))
  self.assertIsNone(metadata(f('CC BY-SA 4.0','')))
 def test_coords(self):
  e={'claims':{'P625':[{'rank':'normal','mainsnak':{'snaktype':'value','datavalue':{'value':{'latitude':35.1,'longitude':20.3,'globe':'http://www.wikidata.org/entity/Q2'}}}}]}}
  self.assertEqual(coords(e),(35.1,20.3))
 def test_database_constraints(self):
  if not os.environ.get('TRIPRAFT_TEST_DB'):self.skipTest('Set TRIPRAFT_TEST_DB to an existing SQLite database')
  src=os.environ['TRIPRAFT_TEST_DB']
  with tempfile.TemporaryDirectory() as dir:
   p=Path(dir)/'work.db'
   with sqlite3.connect(src) as x,sqlite3.connect(p) as y:x.backup(y)
   s=Store(p);s.batch='TEST-ONE'
   row=s.con.execute('SELECT id FROM places WHERE official_website IS NULL LIMIT 1').fetchone();self.assertIsNotNone(row)
   rid=row[0]
   self.assertTrue(s.write('places',rid,'official_website','https://example.org','https://www.wikidata.org/wiki/Q1','test property - not live checked'))
   self.assertFalse(s.write('places',rid,'official_website','https://example.org','https://www.wikidata.org/wiki/Q1','test property - not live checked'))
   self.assertEqual(s.con.execute('SELECT official_website FROM places WHERE id=?',(rid,)).fetchone()[0],'https://example.org')
   self.assertEqual(s.con.execute("SELECT COUNT(*) FROM field_verifications WHERE batch_id='TEST-ONE'").fetchone()[0],1)
   self.assertEqual(s.con.execute('PRAGMA foreign_key_check').fetchall(),[])
   s.con.rollback();s.close()

if __name__=='__main__':
 p=argparse.ArgumentParser(add_help=False);p.add_argument('--db');known,others=p.parse_known_args()
 if known.db:os.environ['TRIPRAFT_TEST_DB']=known.db
 unittest.main(argv=['offline_tests.py']+others)
