#!/usr/bin/env python3
"""Sequential table research controller: independent stages, saved checkpoints, start/status/stop/resume."""
import sys
from pathlib import Path
_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from core import *
import subprocess
STAGES=['countries','states','cities','places','photos','photo_attributions','tags','place_tags','place_hours_intervals','ticket_price_revisions','festivals','opening_hour_exceptions','place_access_events']
DEFAULT_STAGES=['countries','states','cities','tags','place_tags','place_hours_intervals','ticket_price_revisions','festivals','opening_hour_exceptions','place_access_events']
HERE=Path(__file__).resolve().parent

def cli():
 p=argparse.ArgumentParser(description='TripRaft per-table enrichment controller')
 p.add_argument('command',choices=('run','start','status','stop','resume','list'))
 base_args(p);p.add_argument('--only',help='Comma-separated table stages or e.g. places,photos')
 return p.parse_args()

def selected(o):
 wanted=[x.strip() for x in o.only.split(',') if x.strip()] if o.only else DEFAULT_STAGES
 invalid=[x for x in wanted if x not in STAGES]
 if invalid:raise ValueError(f'Unknown stage: {invalid}; available: {STAGES}')
 return wanted

def dbpath(o):
 # Matches core.select_db default without modifying database.
 if o.output:return Path(o.output).resolve()
 if o.db:
  p=Path(o.db).resolve()
  return p if o.in_place else p.with_name(p.stem+'.table_enriched.db')
 for base in (Path.cwd(),HERE,*HERE.parents):
  src=base/'data/catalog/tripraft_places.db'
  if src.exists():return src if o.in_place else src.with_name(src.stem+'.table_enriched.db')
 raise FileNotFoundError('Provide --db')

def cmdrun(o):
 if not o.contact:raise ValueError('--contact is required for research stages')
 dest=dbpath(o);stop=Path(str(dest)+'.stop')
 runner=Path(str(dest)+'.runner.json')
 def mark(state,stage=''):
  tmp=runner.with_suffix('.tmp');tmp.write_text(json.dumps({'state':state,'stage':stage,'updated_at':TODAY(),'pid':os.getpid()},indent=2),encoding='utf8');tmp.replace(runner)
 mark('RUNNING')
 if stop.exists():stop.unlink()  # explicit run/resume clears previous stop
 for stage in selected(o):
  if stop.exists():print('Received stop request between stages');mark('STOPPED');break
  cmd=[sys.executable,str(HERE/(stage+'.py')),'--contact',o.contact,'--interval',str(o.interval),'--timeout',str(o.timeout),'--retries',str(o.retries)]
  if o.db:cmd+=['--db',o.db]
  if o.output:cmd+=['--output',o.output]
  if o.in_place:cmd.append('--in-place')
  if o.country:cmd+=['--country',o.country]
  if o.limit:cmd+=['--limit',str(o.limit)]
  if o.force:cmd.append('--force')
  mark('RUNNING',stage)
  print('\n=== START TABLE',stage,'===',flush=True)
  rc=subprocess.call(cmd,cwd=str(HERE))
  if rc:
   mark('FAILED',stage)
   print('Table failed:',stage,'exit',rc,flush=True)
   return rc
 mark('STOPPED' if stop.exists() else 'FINISHED')
 print('Runner finished or stopped; all completed checkpoints retained.',flush=True)
 return 0

def main():
 o=cli()
 if o.command=='list':print('\n'.join(STAGES));return
 dest=dbpath(o);progress=Path(str(dest)+'.progress.json');log=Path(str(dest)+'.tables.worker.log');pidfile=Path(str(dest)+'.tables.pid.json');stop=Path(str(dest)+'.stop')
 if o.command=='stop':
  stop.write_text(TODAY(),encoding='utf8');print('Stop requested; worker will finish current place and checkpoint.');return
 if o.command=='status':
  print('Database:',dest,'\nProgress:',progress,'\nLog:',log)
  runner=Path(str(dest)+'.runner.json')
  if runner.exists():print('Runner:',runner.read_text(encoding='utf8'))
  if pidfile.exists():print('Background process metadata:',pidfile.read_text(encoding='utf8'))
  if progress.exists():print(progress.read_text(encoding='utf8'))
  state=Path(str(dest)+'.checkpoints.sqlite3')
  if state.exists():
   with sqlite3.connect(state) as conn:
    for row in conn.execute('SELECT stage,outcome,COUNT(*) FROM completed GROUP BY stage,outcome ORDER BY stage,outcome'):
     print(*row)
  else:print('No checkpoints yet.')
  return
 if o.command in ('run','resume'):
  sys.exit(cmdrun(o))
 if o.command=='start':
  if not o.contact:raise ValueError('--contact required')
  if pidfile.exists():
   try:
    old=json.loads(pidfile.read_text(encoding='utf8')).get('pid')
    if isinstance(old,int) and old>0:
     if os.name=='nt':
      status=subprocess.run(['tasklist','/FI',f'PID eq {old}','/FO','CSV','/NH'],capture_output=True,text=True).stdout
      alive=',' in status and str(old) in status
     else:
      try:os.kill(old,0);alive=True
      except ProcessLookupError:alive=False
      except PermissionError:alive=True
     if alive:raise ValueError(f'Existing worker PID {old} may still be running; stop it before starting another')
   except (OSError,json.JSONDecodeError):pass
  args=[a for a in sys.argv[1:] if a!='start']
  args=['run']+args
  cmd=[sys.executable,str(HERE/'run_all.py')]+args
  log.parent.mkdir(parents=True,exist_ok=True)
  if stop.exists():stop.unlink()
  flags=getattr(subprocess,'CREATE_NEW_PROCESS_GROUP',0) if os.name=='nt' else 0
  with log.open('a',encoding='utf8') as f:
   p=subprocess.Popen(cmd,stdin=subprocess.DEVNULL,stdout=f,stderr=subprocess.STDOUT,
      creationflags=flags,start_new_session=(os.name!='nt'),cwd=str(Path.cwd()))
  pidfile.write_text(json.dumps({'pid':p.pid,'started_at':TODAY(),'log':str(log),'stages':selected(o)},indent=2))
  print('Started PID',p.pid,'\nDatabase:',dest,'\nLog:',log,'\nCheck: python run_all.py status --output '+str(dest))
if __name__=='__main__':
 try:main()
 except (ValueError,FileNotFoundError) as ex:print('ERROR:',ex,file=sys.stderr);sys.exit(2)
