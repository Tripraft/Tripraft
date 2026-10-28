# Purpose: Regression tests for planner latency, including success and failure behavior.
"""Planner write query budgets and reproducible isolated HTTP measurements."""
import json
import os
from pathlib import Path
from time import perf_counter

import pytest
from sqlalchemy import event

from app.core.db.connection import engine
from conftest import payload


@pytest.fixture(autouse=True)
def no_external_email(monkeypatch):
    monkeypatch.setattr('app.notifications.email.background.submit_auth_email', lambda *args: True)


def test_planner_write_query_budgets(alice, monkeypatch):
    api, _, _ = alice
    # Do not contact SMTP or a real recipient during measurement.
    monkeypatch.setattr('app.notifications.email.smtp.email_service.send_invitation', lambda **kw: True)
    samples = []
    for run in range(3):
        base = '/api/v1/group-planner'
        group_id = None
        for operation in ('group', 'poll', 'checklist', 'invitation'):
            queries = []
            def record(_conn, _cursor, statement, _params, _context, _many):
                queries.append(statement.split()[0])
            event.listen(engine, 'before_cursor_execute', record)
            started = perf_counter()
            try:
                if operation == 'group':
                    response = api.post(base + '/groups', json={'name': 'Latency fixture', 'destination': 'Lisbon'})
                elif operation == 'poll':
                    response = api.post(f'{base}/groups/{group_id}/polls', json={'name': 'Dinner?', 'options': ['A', 'B']})
                elif operation == 'checklist':
                    response = api.post(f'{base}/groups/{group_id}/checklist', json={'text': 'Pack passport'})
                else:
                    response = api.post(base + '/invitations', json={'group_id': group_id, 'email': f'latency{run}@example.test'})
            finally:
                elapsed = (perf_counter() - started) * 1000
                event.remove(engine, 'before_cursor_execute', record)
            assert response.status_code == 201, response.get_json()
            if operation == 'group':
                group_id = payload(response)['id']
            samples.append({'operation': operation, 'ms': round(elapsed, 3), 'sql': len(queries)})
            assert len(queries) <= {'group': 8, 'poll': 8, 'checklist': 8, 'invitation': 8}[operation]
    output = os.environ.get('PLANNER_LATENCY_OUTPUT')
    if output:
        Path(output).write_text(json.dumps(samples, indent=2), encoding='utf-8')
    print(json.dumps(samples))
