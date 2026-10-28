# Purpose: Verifies shared database/bucket files, group-only downloads, rollback and storage failures.
"""Cloud I/O is mocked; all account/file metadata uses a migrated throwaway DB."""
import io
from unittest.mock import Mock

import pytest
from sqlalchemy import event

from app.core.config import Config
from app.core.db.connection import engine, get_db_session
from app.trips.models import TripMember, VaultDocument, VaultFileContent
from app.trips.services.vault_storage import SupabaseVaultStorage, VaultStorageError
from conftest import payload

PDF = b'%PDF-1.7\nshared booking bytes'


@pytest.fixture
def shared_vault(alice, bob, make_user, monkeypatch, tmp_path):
    api, owner_id, _ = alice
    viewer, viewer_id, _ = bob
    outsider, _, _ = make_user('outsider')
    monkeypatch.setenv('UPLOAD_DIR', str(tmp_path))
    monkeypatch.setattr(Config, 'SUPABASE_URL', 'https://storage.example.test')
    monkeypatch.setattr(Config, 'SUPABASE_SERVICE_ROLE_KEY', 'test-key-never-a-real-secret')
    monkeypatch.setattr(Config, 'SUPABASE_VAULT_BUCKET', 'tripraft-group-vault')
    group_id = payload(api.post('/api/v1/group-planner/groups', json={'name': 'Private documents'}))['id']
    with get_db_session() as session:
        session.add(TripMember(group_id=group_id, user_id=viewer_id, role='viewer', is_active=True))
        session.commit()
    return api, owner_id, viewer, viewer_id, outsider, group_id, tmp_path


@pytest.fixture
def remote(monkeypatch):
    objects = {}
    calls = []
    def request(method, url, **kwargs):
        calls.append((method, url, kwargs))
        response = Mock(status_code=200)
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        if '/bucket/' in url:
            response.json.return_value = {'public': False}
        elif method == 'POST':
            objects[url.split('/object/', 1)[1]] = kwargs['data']
            response.status_code = 201
        elif method == 'GET':
            key = url.split('/object/authenticated/', 1)[1]
            if key not in objects:
                response.status_code = 404
            response.iter_content.return_value = [objects.get(key, b'')]
        elif method == 'DELETE':
            bucket = url.rsplit('/', 1)[1]
            for key in kwargs['json']['prefixes']:
                objects.pop(bucket + '/' + key, None)
        return response
    monkeypatch.setattr('app.trips.services.vault_storage.requests.request', request)
    return objects, calls


def upload(api, group_id, data=PDF):
    return api.post(f'/api/v1/group-planner/groups/{group_id}/vault',
                    data={'file': (io.BytesIO(data), 'booking.pdf')}, content_type='multipart/form-data')


@pytest.mark.parametrize('backend', ['database', 'supabase'])
def test_only_same_group_members_can_list_preview_and_download(shared_vault, remote, monkeypatch, backend):
    api, _, viewer, viewer_id, outsider, group_id, directory = shared_vault
    monkeypatch.setattr(Config, 'VAULT_STORAGE_BACKEND', backend)
    emit = Mock()
    monkeypatch.setattr('app.trips.realtime.events.emit_to_group', emit)
    created = upload(api, group_id)
    assert created.status_code == 201, created.get_json()
    document = payload(created)
    base = f'/api/v1/group-planner/groups/{group_id}/vault'
    path = base + '/' + document['id']
    assert document['filename'] == 'booking.pdf'
    assert payload(viewer.get(base))[0]['id'] == document['id']
    reads = []
    def record(*args):
        reads.append(1)
    event.listen(engine, 'before_cursor_execute', record)
    try:
        downloaded = viewer.get(path)
    finally:
        event.remove(engine, 'before_cursor_execute', record)
    assert downloaded.status_code == 200 and downloaded.data == PDF
    assert len(reads) <= 3  # Auth, membership, metadata/content in one query.
    assert downloaded.headers['Cache-Control'] == 'private, no-store'
    assert 'booking.pdf' in downloaded.headers['Content-Disposition']
    assert outsider.get(base).status_code == 403
    assert outsider.get(path).status_code == 404
    other_group = payload(viewer.post('/api/v1/group-planner/groups', json={'name': 'Other group'}))['id']
    assert viewer.get(f'/api/v1/group-planner/groups/{other_group}/vault/{document["id"]}').status_code == 404
    assert viewer.delete(path).status_code == 403
    emit.assert_any_call(group_id, 'vault:uploaded', {'document': document, 'user_id': document['uploaded_by']})
    with get_db_session() as session:
        member = session.query(TripMember).filter_by(group_id=group_id, user_id=viewer_id).one()
        member.is_active = False
        session.commit()
    assert viewer.get(path).status_code == 404
    assert api.delete(path).status_code == 200
    assert api.get(path).status_code == 404
    with get_db_session() as session:
        assert session.get(VaultFileContent, document['id']) is None
    assert not remote[0] and not list(directory.rglob('*'))


def test_ten_mb_database_file_roundtrips_without_local_storage(shared_vault, monkeypatch):
    api, _, viewer, _, _, group_id, directory = shared_vault
    monkeypatch.setattr(Config, 'VAULT_STORAGE_BACKEND', 'database')
    data = b'%PDF-' + b'x' * (10 * 1024 * 1024 - 5)
    created = upload(api, group_id, data)
    assert created.status_code == 201, created.get_json()
    document = payload(created)
    assert document['file_size'] == len(data)
    downloaded = viewer.get(f'/api/v1/group-planner/groups/{group_id}/vault/{document["id"]}')
    assert downloaded.status_code == 200 and downloaded.data == data
    assert not list(directory.rglob('*'))


def test_database_file_and_metadata_rollback_together(shared_vault, monkeypatch):
    api, _, _, _, _, group_id, _ = shared_vault
    monkeypatch.setattr(Config, 'VAULT_STORAGE_BACKEND', 'database')
    from sqlalchemy.orm import Session
    def fail_content(session, _context, _instances):
        if any(isinstance(row, VaultFileContent) for row in session.new):
            raise RuntimeError('simulated failure')
    event.listen(Session, 'before_flush', fail_content)
    try:
        assert upload(api, group_id).status_code != 201
    finally:
        event.remove(Session, 'before_flush', fail_content)
    with get_db_session() as session:
        assert session.query(VaultDocument).filter_by(group_id=group_id).count() == 0
        assert session.query(VaultFileContent).join(VaultDocument).filter(VaultDocument.group_id == group_id).count() == 0


def test_bucket_object_is_removed_if_metadata_commit_fails(shared_vault, remote, monkeypatch):
    api, _, _, _, _, group_id, _ = shared_vault
    monkeypatch.setattr(Config, 'VAULT_STORAGE_BACKEND', 'supabase')
    from sqlalchemy.orm import Session
    def fail_commit(_session):
        raise RuntimeError('simulated commit failure')
    event.listen(Session, 'before_commit', fail_commit)
    try:
        assert upload(api, group_id).status_code != 201
    finally:
        event.remove(Session, 'before_commit', fail_commit)
    assert not remote[0]
    assert any(method == 'DELETE' for method, _, _ in remote[1])
    with get_db_session() as session:
        assert session.query(VaultDocument).filter_by(group_id=group_id).count() == 0


def test_missing_bucket_credentials_never_fall_back_to_disk(shared_vault, monkeypatch):
    api, _, _, _, _, group_id, directory = shared_vault
    monkeypatch.setattr(Config, 'VAULT_STORAGE_BACKEND', 'supabase')
    monkeypatch.setattr(Config, 'SUPABASE_SERVICE_ROLE_KEY', '')
    response = upload(api, group_id)
    assert response.status_code == 503
    assert not list(directory.rglob('*'))


def test_public_buckets_are_refused(shared_vault, monkeypatch):
    api, _, _, _, _, group_id, _ = shared_vault
    monkeypatch.setattr(Config, 'VAULT_STORAGE_BACKEND', 'supabase')
    response = Mock(status_code=200)
    response.json.return_value = {'public': True}
    response.__enter__ = Mock(return_value=response)
    response.__exit__ = Mock(return_value=False)
    monkeypatch.setattr('app.trips.services.vault_storage.requests.request', Mock(return_value=response))
    assert upload(api, group_id).status_code == 503


def test_storage_downloads_are_bounded_and_do_not_follow_redirects(shared_vault, monkeypatch):
    _, _, _, _, _, group_id, _ = shared_vault
    response = Mock(status_code=200)
    response.__enter__ = Mock(return_value=response)
    response.__exit__ = Mock(return_value=False)
    response.iter_content.return_value = [b'x' * (10 * 1024 * 1024 + 1)]
    request = Mock(return_value=response)
    monkeypatch.setattr('app.trips.services.vault_storage.requests.request', request)
    storage = SupabaseVaultStorage()
    with pytest.raises(VaultStorageError, match='10 MB'):
        storage.download(storage.reference(group_id, 'a' * 32 + '.pdf'), group_id)
    assert request.call_args.kwargs['allow_redirects'] is False
    assert request.call_args.kwargs['timeout'] == (5, 30)
