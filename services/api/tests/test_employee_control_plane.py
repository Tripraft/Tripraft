"""A configured executor must still reject an engineer-writable approval database."""
from unittest.mock import Mock

import pytest

from app.employees.control_plane import verify_protected_store


def test_engineer_writable_store_is_never_accepted_as_authority():
    session = Mock()
    identity, logins, grant = Mock(), Mock(), Mock()
    identity.one.return_value = ('cto_executor', 'protected_control')
    logins.scalars.return_value.all.return_value = ['cto_executor', 'engineer_01']
    grant.scalar.return_value = True
    session.execute.side_effect = [identity, logins, grant]
    with pytest.raises(ValueError, match='untrusted login'):
        verify_protected_store(session, ['cto_executor'], 'protected_control')
    assert session.execute.call_args.args[1]['role'] == 'engineer_01'


def test_pinned_control_plane_identity_and_read_only_engineers():
    session = Mock()
    identity, logins, grant = Mock(), Mock(), Mock()
    identity.one.return_value = ('cto_executor', 'protected_control')
    logins.scalars.return_value.all.return_value = ['cto_executor', 'engineer_01']
    grant.scalar.return_value = False
    session.execute.side_effect = [identity, logins] + [grant] * 6
    assert verify_protected_store(session, ['cto_executor'], 'protected_control')
    session.execute.side_effect = [identity]
    with pytest.raises(ValueError, match='identity'):
        verify_protected_store(session, ['cto_executor'], 'engineer_database')
