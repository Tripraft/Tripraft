#!/usr/bin/env python3
"""Festival validation/report; no automated creation without verified official dates."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 rows=job.rows('''SELECT f.id,f.festival_name,f.month_label,f.source,s.country_id
   FROM festivals f LEFT JOIN places p ON p.id=f.place_id
   LEFT JOIN cities ci ON ci.id=COALESCE(f.city_id,p.city_id)
   LEFT JOIN states s ON s.id=ci.state_id ORDER BY f.id''')
 def each(j,r):
  if not r['source']:j.store.unresolved('festivals',r['id'],'source','MISSING_FESTIVAL_EVIDENCE','Do not invent festival dates or months')
  if not r['month_label']:j.store.unresolved('festivals',r['id'],'month_label','NEEDS_OFFICIAL_SCHEDULE','Not independently published')
  return 0
 return job.process(rows,each)
if __name__=='__main__':run_stage('festivals',work)
