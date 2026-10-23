"""Developer SQL generation and trusted offboarding adapters use restricted identities."""
from unittest.mock import Mock
from uuid import uuid4

import pytest

from app.employees.database_provisioning import PostgresDeveloperRevoker, developer_role, disable_sql, provision_sql
from app.employees.provisioning import ManualRequired


def test_generated_roles_are_unique_and_have_no_administrative_capabilities():
    first, second = uuid4(), uuid4()
    sql = provision_sql(first, ['users', 'user_sessions', 'groups', 'expenses'])
    assert developer_role(first) != developer_role(second)
    assert 'NOBYPASSRLS' in sql and 'NOCREATEROLE' in sql and 'NOSUPERUSER' in sql
    assert 'GRANT tripraft_dev_runtime' in sql
    assert 'PASSWORD' not in sql
    assert 'NOLOGIN' in disable_sql(first)
    assert 'pg_terminate_backend' in disable_sql(first)
    with pytest.raises(ValueError):
        provision_sql(first, ['employee_provisioning_jobs'])
    with pytest.raises(ValueError):
        provision_sql(first, ['users; DROP SCHEMA public'])


def test_database_revocation_refuses_wrong_database_and_protected_roles():
    session, connection = Mock(), Mock()
    session.query.return_value.filter_by.return_value.first.return_value = None
    employee = Mock(id=uuid4())
    connection.get_dsn_parameters.return_value = {'host': 'wrong.example', 'dbname': 'postgres'}
    revoker = PostgresDeveloperRevoker(lambda: connection, 'approved.example', 'postgres')
    with pytest.raises(ManualRequired, match='identity_mismatch'):
        revoker.disable(session, employee)
    connection.close.assert_called_once()
    connection.get_dsn_parameters.return_value = {'host': 'approved.example', 'dbname': 'postgres'}
    cursor = Mock()
    connection.cursor.return_value.__enter__ = Mock(return_value=cursor)
    connection.cursor.return_value.__exit__ = Mock(return_value=False)
    cursor.fetchone.return_value = (True, False, False, False, False)
    with pytest.raises(ManualRequired, match='administrative_database_role'):
        revoker.disable(session, employee)
    assert not connection.commit.called
