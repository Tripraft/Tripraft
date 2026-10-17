#!/usr/bin/env python3
"""Real coverage measurements. Populated != verified. No fake 80-90% claim."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *
import csv,collections

def main():
 p=argparse.ArgumentParser();p.add_argument('--db');p.add_argument('--output');p.add_argument('--country');p.add_argument('--csv',default=str(Path(__file__).with_name('tripraft-all-schema-fields-enrichment-review.csv')))
 o=p.parse_args();o.in_place=True
 # Never create a copy just to report progress; use existing enriched output if available.
 if o.output:o.db=o.output
 elif not o.db:
  base=Path(__file__).resolve().parent
  candidates=[p/'data/catalog/tripraft_places.table_enriched.db' for p in (base,*base.parents)]
  o.db=str(next((x for x in candidates if x.exists()),'')) or None
 db=select_db(o);conn=sqlite3.connect(db)
 count=lambda sql:conn.execute(sql).fetchone()[0]
 names=[r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'place_search_fts_%' ORDER BY name")]
 print('DATABASE:',db)
 for name in names:
  if name=='place_search_fts':continue
  nr=count(f'SELECT COUNT(*) FROM "{name}"')
  print(f'{name:29s} {nr:8,d} rows')
 print('\nCORE NULL FIELD COVERAGE (population, not independent verification)')
 for table in ('countries','states','cities','places'):
  counts=[]
  cols=[r[1] for r in conn.execute('PRAGMA table_info('+table+')')]
  if Path(o.csv).is_file():
   with open(o.csv,encoding='utf-8-sig',newline='') as f:
    policies=list(csv.DictReader(f))
   targets=[r['column_name'] for r in policies if r['table_name']==table and r['suggested_action'] in ('RESEARCH_VERIFY','CONDITIONAL','VERIFIED_DERIVATION') and r['column_name'] in cols]
  else:targets=[x for x in cols if x not in ('id','created_at','updated_at','deleted_at')]
  for col in targets:
   n=count(f'SELECT COUNT(*) FROM "{table}" WHERE "{col}" IS NOT NULL AND TRIM(CAST("{col}" AS TEXT)) <> \'\'')
   total=count(f'SELECT COUNT(*) FROM "{table}"')
   counts.append((col,n,total))
  populated=sum(x[1] for x in counts);possible=sum(x[2] for x in counts)
  print(f'{table:14s} {populated:,}/{possible:,} field-cells populated ({(100*populated/possible if possible else 0):.1f}%). Not all fields apply to every row.')
  if table=='places':
   for col,n,t in counts:print(f'   {col:30s} {n:7,d}/{t:7,d}  {100*n/t if t else 0:5.1f}%')
 try:
  verified=count("SELECT COUNT(*) FROM field_verifications WHERE verification_status='verified'")
  print(f'\nRecorded verified FIELD EVENTS (not deduplicated cells): {verified:,}')
 except sqlite3.Error:pass
 conn.close()
if __name__=='__main__':main()
