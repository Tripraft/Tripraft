"""Verify that engineer database identities cannot author control-plane approvals."""
from sqlalchemy import text


def verify_protected_store(session, trusted_roles, expected_database):
    trusted_roles = set(trusted_roles)
    identity = session.execute(text('SELECT current_user, current_database()')).one()
    if identity[0] not in trusted_roles or identity[1] != expected_database:
        raise ValueError('Control-plane database identity is not explicitly trusted')
    roles = session.execute(text('SELECT rolname FROM pg_roles WHERE rolcanlogin')).scalars().all()
    for role in roles:
        if role in trusted_roles:
            continue
        for table in ('users', 'employees', 'employee_sessions', 'employee_provisioning_jobs',
                      'employee_access_requests', 'employee_access_events'):
            can_modify = session.execute(text('SELECT has_table_privilege(:role, :table, :privileges)'),
                {'role': role, 'table': table, 'privileges': 'INSERT,UPDATE,DELETE,TRUNCATE'}).scalar()
            if can_modify:
                raise ValueError('An untrusted login can modify the approval store; provisioning refused')
    return True
