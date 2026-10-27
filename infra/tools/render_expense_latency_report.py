# Purpose: Renders a self-contained interactive table from the disposable expense workflow benchmark's summary JSON.
"""Run after tests/expense_workflow_benchmark.py; no app/database/network access."""
import argparse
import json
from pathlib import Path

LABELS = {
    'session_read': ('Shared', 'Read signed-in session'),
    'personal_profile': ('Personal', 'Open personal page: currency preference'),
    'pending_invitations': ('Shared', 'Read pending invitations'),
    'personal_expenses_page': ('Personal', 'Open personal page: expense page'),
    'personal_income_page': ('Personal', 'Open personal page: income page'),
    'personal_add': ('Personal', 'Add personal expense'),
    'personal_edit': ('Personal', 'Edit personal expense'),
    'personal_delete': ('Personal', 'Delete personal expense'),
    'personal_currency_save': ('Personal', 'Change personal currency: save preference'),
    'fx_cached_read': ('Shared', 'Currency conversion: cached rate read'),
    'group_list': ('Group', 'Switch to group: read group cards'),
    'group_detail': ('Group', 'Open empty group details'),
    'group_detail_with_ledger': ('Group', 'Open group details with an expense'),
    'group_create': ('Group', 'Create group'),
    'invitation_send': ('Group', 'Save/send invitation request (mail disabled)'),
    'invitation_details': ('Group', 'Read invitation details'),
    'invitation_accept': ('Group', 'Accept invitation and join'),
    'group_join_code': ('Group', 'Join with group code'),
    'group_expense_add': ('Group', 'Add group expense'),
    'group_expense_edit': ('Group', 'Edit group expense'),
    'group_expense_delete': ('Group', 'Delete group expense'),
    'settlement_create': ('Group', 'Record settlement'),
    'settlement_delete': ('Group', 'Delete settlement record'),
    'group_currency_save': ('Group', 'Change group display currency: save'),
    'group_delete': ('Group', 'Delete/archive settled group'),
}

TEMPLATE = '''<!doctype html>
<!-- Purpose: Interactive local expense API latency evidence with filtering, sorting and explicit measurement limits. -->
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>TripRaft expense latency - October 26, 2026</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f6f7fb;color:#17253a;font:15px/1.6 system-ui,sans-serif}main{max-width:1120px;margin:auto;padding:42px 24px}h1{font-size:34px;letter-spacing:-.04em;margin:8px 0}h2{font-size:20px}p{max-width:900px}.eyebrow{color:#7c3aed;font-size:12px;letter-spacing:.12em;font-weight:700}.note,.metrics,table{background:#fff;border:1px solid #e2e8f0;border-radius:16px}.note{padding:20px 24px;border-left:4px solid #8b5cf6}.metrics{display:grid;grid-template-columns:repeat(3,1fr);padding:20px;gap:24px;margin:24px 0}.metrics strong{display:block;font-size:26px;color:#6d28d9}.metrics span{font-size:13px;color:#64748b}.controls{display:flex;gap:12px;flex-wrap:wrap;margin:24px 0 14px}label{display:grid;font-size:12px;gap:5px;color:#475569}select,input{padding:10px 12px;border:1px solid #cbd5e1;border-radius:9px;background:#fff;font:inherit;color:#17253a;min-height:42px}.table-wrap{overflow:auto}table{width:100%;border-collapse:separate;border-spacing:0;overflow:hidden}th{text-align:left;background:#17253a;color:white;padding:14px 16px;font-size:12px}td{padding:13px 16px;border-bottom:1px solid #eef2f7;font-size:13px}td.number,th.number{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}tbody tr:last-child td{border:0}tbody tr:nth-child(even){background:#fafbfe}.bar{height:3px;border-radius:3px;background:#8b5cf6;display:block;margin-top:6px}.scope{color:#64748b;font-size:11px}summary{cursor:pointer;font-weight:600}details{margin-top:22px}footer{color:#64748b;font-size:12px;margin-top:30px}a{color:#6d28d9}@media(max-width:600px){.metrics{grid-template-columns:1fr}h1{font-size:27px}main{padding:24px 16px}td,th{padding:12px}}
</style></head><body><main><div class="eyebrow">TRIPRAFT / ENGINEERING EVIDENCE</div>
<h1>Expense workflow latency</h1><p>October 26, 2026 · America/Los_Angeles</p>
<div class="note"><strong>These are local API request timings, not page-opening times.</strong>
<p>12 isolated SQLite/Flask workflow runs; the first request is reported separately, and median/p95 use the next 11 runs. Each account has one personal expense; each group reaches three members and one expense. Authentication, SQL and commits are included. Browser rendering, HTTP network travel, remote PostgreSQL, real email delivery and cold exchange-rate-provider calls are excluded. With 11 warm samples, p95 is the maximum observation; it is not a production service-level percentile.</p></div>
<div class="metrics"><div><strong>71% smaller</strong><span>Expense-page JS: 601.81 → 173.96 kB; PDF code loads on export</span></div><div><strong>2 seconds removed</strong><span>Copied-link acceptance opens the joined group immediately after success</span></div><div><strong>38 → 30 SQL</strong><span>Invitation acceptance; sending also drops from 20 to 17 statements</span></div></div>
<div class="controls"><label>Scope<select id="scope"><option>All</option><option>Personal</option><option>Group</option><option>Shared</option></select></label><label>Find a workflow<input id="search" type="search" placeholder="e.g. currency or settlement"></label><label>Sort<select id="sort"><option value="name">Workflow</option><option value="median_ms">Slowest median first</option><option value="p95_ms">Slowest p95 first</option><option value="median_sql">Most SQL first</option></select></label></div>
<p id="count" role="status" aria-live="polite"></p><div class="table-wrap"><table><thead><tr><th>Workflow / API portion</th><th class="number">First run ms</th><th class="number">Median ms</th><th class="number">p95 ms</th><th class="number">SQL statements</th></tr></thead><tbody id="rows"></tbody></table></div>
<details open><summary>How these requests relate to the app</summary><p>Opening personal expenses reads the session, currency preference, expense and income pages; expense/income pagination runs in parallel. Returning to a loaded tab reuses cached ledger data. Switching to group cards and opening a group are separate reads. Extra ledger pages add requests. Currency changes save a preference and may need one rate lookup per source currency; loaded browser-session rates are reused. Saving a group preference updates the UI from the committed response, then reconciles data in the background.</p></details>
<details><summary>What can still be improved</summary><p>Measure real browser navigation and production PostgreSQL first. Group expense edits still use 34 SQL statements in this small fixture; eager-loading and batching are the next query-reduction candidates. Large ledgers still need all pages for complete analytics. Cold FX calls and email transport remain external dependencies. Live focus/reconnect reconciliation owns refreshes, avoiding duplicate group-query focus reads.</p></details>
<footer>Benchmark: services/api/tests/expense_workflow_benchmark.py · This file is self-contained and makes no network requests.</footer></main>
<script type="application/json" id="data">__DATA__</script>
<script>
const data=JSON.parse(document.getElementById('data').textContent);
const scope=document.getElementById('scope'), search=document.getElementById('search'), sort=document.getElementById('sort');
function render(){const term=search.value.toLowerCase();const rows=data.filter(row=>(scope.value==='All'||row.scope===scope.value)&&row.name.toLowerCase().includes(term));rows.sort((a,b)=>sort.value==='name'?a.name.localeCompare(b.name):b[sort.value]-a[sort.value]);const target=document.getElementById('rows');target.replaceChildren();const max=Math.max(1,...rows.map(row=>row.median_ms));for(const row of rows){const tr=document.createElement('tr');const label=document.createElement('td');label.textContent=row.name;const tag=document.createElement('div');tag.className='scope';tag.textContent=row.scope;label.append(tag);tr.append(label);for(const key of ['first_ms','median_ms','p95_ms','median_sql']){const td=document.createElement('td');td.className='number';td.textContent=key==='median_sql'?String(row[key]):Number(row[key]).toFixed(2);if(key==='median_ms'){const bar=document.createElement('i');bar.className='bar';bar.style.width=(row[key]/max*100)+'%';td.append(bar);}tr.append(td);}target.append(tr);}document.getElementById('count').textContent=rows.length+' measured API portions';}
scope.addEventListener('change',render);search.addEventListener('input',render);sort.addEventListener('change',render);render();
</script></body></html>
'''


def render_report(source, output):
    report = json.loads(Path(source).read_text(encoding='utf-8'))
    rows = [{'scope': LABELS[key][0], 'name': LABELS[key][1], **values}
            for key, values in report['summary'].items()]
    encoded = json.dumps(rows, ensure_ascii=True).replace('<', '\\u003c')
    Path(output).write_text(TEMPLATE.replace('__DATA__', encoded), encoding='utf-8')
    return len(rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--output', type=Path, default=Path('docs/operations/expense-latency.html'))
    args = parser.parse_args()
    print(f'Rendered {render_report(args.source, args.output)} workflow portions to {args.output}')
