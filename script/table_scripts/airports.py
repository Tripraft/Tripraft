#!/usr/bin/env python3
"""Airports not part of requested enrichment. Safely leaves existing airport data unchanged."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *

def work(job):
 count=job.con.execute('SELECT COUNT(*) FROM airports').fetchone()[0]
 print(f'Airports excluded by configuration; {count} existing records preserved. To enrich airports, add an aviation-authority-licensed source module.')
 return {'processed':0,'preserved':count}
if __name__=='__main__':run_stage('airports',work)
