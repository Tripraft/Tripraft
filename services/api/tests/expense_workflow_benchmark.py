# Purpose: Measures synthetic expense workflows in a disposable SQLite fixture and optionally records timing/SQL counts.
"""Opt-in local workflow benchmark; uses conftest's disposable SQLite database.

Run from services/api: python -m pytest tests/expense_workflow_benchmark.py -q -s
Set TRIPRAFT_EXPENSE_BENCHMARK_OUTPUT to an output JSON path to retain results.
This measures Flask request work, including auth/SQL/commit/live recipient lookup,
not browser rendering, remote PostgreSQL, SMTP delivery or external FX latency.
"""
import json
import math
import os
from collections import OrderedDict, defaultdict
from pathlib import Path
from statistics import median
from time import perf_counter, time

from sqlalchemy import event

from conftest import payload


def test_measure_expense_workflows(app, make_user, monkeypatch):
    from app.auth.services.auth_service import email_service
    from app.core.db.connection import engine
    from app.expenses.services.expense_invite_service import InvitationServiceSQL
    from app.expenses.services import exchange_rates as fx

    monkeypatch.setattr(email_service, 'send_verification', lambda *args: True)
    monkeypatch.setattr(InvitationServiceSQL, '_send_invitation_email', lambda *args: 'disabled')
    # A primed quote measures the real cached FX endpoint without contacting a provider.
    monkeypatch.setattr(fx, '_cache', OrderedDict({
        'currencies': (time(), {'currencies': [{'code': 'USD'}, {'code': 'INR'}]}, 0),
        'USD:INR': (time(), {'base': 'USD', 'quote': 'INR', 'rate': 95, 'date': '2026-10-26'}, 0),
    }))

    def no_network(*args):
        raise AssertionError('The benchmark must not contact the exchange provider')

    monkeypatch.setattr(fx, '_get', no_network)
    samples = defaultdict(list)
    statements = []

    def capture(*args):
        statements.append(1)

    def measure(label, api, method, path, expected=200, **kwargs):
        statements.clear()
        start = perf_counter()
        response = getattr(api, method)(path, **kwargs)
        elapsed = (perf_counter() - start) * 1000
        assert response.status_code == expected, (label, response.status_code, response.get_json())
        samples[label].append({'ms': round(elapsed, 3), 'sql': len(statements)})
        return payload(response)

    event.listen(engine, 'before_cursor_execute', capture)
    try:
        for iteration in range(12):
            owner, uid, _ = make_user('benchmark_owner')
            member, mid, email = make_user('benchmark_member')
            joiner, _, _ = make_user('benchmark_joiner')
            base = '/api/v1/expenses'
            measure('session_read', owner, 'get', '/api/v1/auth/me')
            measure('personal_profile', owner, 'get', '/api/v1/auth/user/profile')
            measure('pending_invitations', owner, 'get', base + '/invitations')
            personal = measure('personal_add', owner, 'post', base + '?compact=true', expected=201,
                               json={'description': 'Benchmark meal', 'amount': '12', 'currency': 'USD'})['expense']
            measure('personal_expenses_page', owner, 'get', base + '/user?personal_only=true&include_deleted=true&limit=100&offset=0')
            measure('personal_income_page', owner, 'get', base + '/incomes?limit=100&offset=0')
            measure('personal_edit', owner, 'put', base + '/' + personal['id'] + '?compact=true', json={'amount': '20'})
            measure('personal_currency_save', owner, 'put', '/api/v1/auth/user/profile', json={'personal_display_currency': 'INR'})
            measure('fx_cached_read', owner, 'get', '/api/v1/exchange-rates?base=USD&quote=INR')
            measure('personal_delete', owner, 'delete', base + '/' + personal['id'] + '?compact=true')
            group = measure('group_create', owner, 'post', base + '/groups?compact=true', expected=201,
                            json={'name': f'Benchmark {iteration}', 'currency': 'USD'})['group']
            gid = group['id']
            path = base + '/groups/' + gid
            measure('group_list', owner, 'get', base + '/groups?mode=summary')
            measure('group_detail', owner, 'get', path + '/full?include_deleted=true&expense_limit=100&settlement_limit=100')
            invitation = measure('invitation_send', owner, 'post', base + '/invitations?compact=true', expected=201,
                                 json={'group_id': gid, 'email': email})['invitation']
            measure('invitation_details', member, 'get', base + '/invitations/' + invitation['id'] + '/details')
            measure('invitation_accept', member, 'post', base + '/invitations/' + invitation['id'] + '/accept?compact=true')
            measure('group_join_code', joiner, 'post', base + '/groups/join', json={'code': group['group_code']})
            expense = measure('group_expense_add', owner, 'post', base + '?compact=true', expected=201,
                              json={'group_id': gid, 'paid_by': uid, 'description': 'Benchmark dinner', 'amount': '30', 'split_type': 'equal'})['expense']
            measure('group_expense_edit', owner, 'put', base + '/' + expense['id'] + '?compact=true', json={'amount': '60'})
            measure('group_detail_with_ledger', owner, 'get', path + '/full?include_deleted=true&expense_limit=100&settlement_limit=100')
            settlement = measure('settlement_create', owner, 'post', base + '/settlements', expected=201,
                                 json={'group_id': gid, 'from_user_id': mid, 'to_user_id': uid, 'amount': '5'})['settlement']
            measure('settlement_delete', owner, 'delete', base + '/settlements/' + settlement['id'])
            measure('group_currency_save', owner, 'put', path, json={'display_currency': 'INR'})
            measure('group_expense_delete', owner, 'delete', base + '/' + expense['id'] + '?compact=true')
            measure('group_delete', owner, 'delete', path)
    finally:
        event.remove(engine, 'before_cursor_execute', capture)

    # Retain first-run costs separately; the next eleven runs describe the warm fixture.
    report = {'environment': 'Isolated SQLite / Flask test client; no network or real mail', 'iterations': 12,
              'summary': {}, 'samples': dict(samples)}
    for label, rows in samples.items():
        warm = sorted(row['ms'] for row in rows[1:])
        report['summary'][label] = {'first_ms': rows[0]['ms'], 'median_ms': round(median(warm), 2),
                                    'p95_ms': warm[math.ceil(len(warm) * .95) - 1],
                                    'median_sql': median(row['sql'] for row in rows[1:])}
    output = os.environ.get('TRIPRAFT_EXPENSE_BENCHMARK_OUTPUT')
    if output:
        Path(output).parent.mkdir(parents=True, exist_ok=True)
        Path(output).write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report['summary'], indent=2))
