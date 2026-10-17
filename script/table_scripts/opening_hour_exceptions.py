#!/usr/bin/env python3
"""No exceptions generated without event-specific official source; audit existing only."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 rows=job.rows('''SELECT e.id,e.place_id,e.date_from,e.source_id,s.country_id FROM opening_hour_exceptions e
 JOIN places p ON p.id=e.place_id JOIN cities ci ON ci.id=p.city_id JOIN states s ON s.id=ci.state_id''')
 def each(j,r):
  if r['source_id'] is None:j.store.unresolved('opening_hour_exceptions',r['id'],'source_id','NO_OFFICIAL_EXCEPTION_SOURCE')
  return 0
 return job.process(rows,each)
if __name__=='__main__':run_stage('opening_hour_exceptions',work)
