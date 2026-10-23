"""Local demo delivery status never implies a welcome email was sent."""
from conftest import payload
from test_employee_access import employee_setup as employee_setup


def test_demo_reports_email_disabled_without_requiring_smtp(employee_setup, app, monkeypatch):
    cto, _, _, _, _ = employee_setup
    monkeypatch.setitem(app.config, 'EMPLOYEE_LOCAL_DEMO', True)
    identity = payload(cto.get('/api/v1/employees/me'))
    assert identity['invitation_delivery_mode'] == 'disabled_local_demo'
    assert identity['live_provisioning_enabled'] is False


def test_normal_portal_reports_queue_without_claiming_smtp_delivery(employee_setup, app, monkeypatch):
    cto, _, _, _, _ = employee_setup
    monkeypatch.setitem(app.config, 'EMPLOYEE_LOCAL_DEMO', False)
    assert payload(cto.get('/api/v1/employees/me'))['invitation_delivery_mode'] == 'trusted_worker_queue'
