# Purpose: Regression tests for planner upload limits, including success and failure behavior.
"""Enforce the vault byte limit independently of client file metadata."""
import io
from pathlib import Path

import pytest
from werkzeug.datastructures import FileStorage

from app.core.db.connection import get_db_session
from app.trips.models import VaultDocument
from app.trips.services.vault_service import MAX_FILE_SIZE, VaultService
from conftest import payload


@pytest.fixture
def vault(alice, monkeypatch, tmp_path):
    api, user_id, _ = alice
    monkeypatch.setenv('UPLOAD_DIR', str(tmp_path))
    response = api.post('/api/v1/group-planner/groups', json={'name': 'Upload limits'})
    assert response.status_code == 201
    group_id = payload(response)['id']
    return api, user_id, group_id, tmp_path


@pytest.mark.parametrize('difference', [-1, 0, 1])
def test_vault_exact_ten_mb_boundary(vault, difference):
    api, _, group_id, directory = vault
    size = MAX_FILE_SIZE + difference
    response = api.post(f'/api/v1/group-planner/groups/{group_id}/vault',
                        data={'file': (io.BytesIO(b'%PDF-' + b'x' * (size - 5)), 'booking.pdf')},
                        content_type='multipart/form-data')
    assert response.status_code == (413 if difference > 0 else 201), response.get_json()
    with get_db_session() as session:
        documents = session.query(VaultDocument).filter_by(group_id=group_id).all()
        assert len(documents) == (0 if difference > 0 else 1)
        if documents:
            assert documents[0].file_size == size
            saved = directory / 'vault' / group_id / documents[0].filename
            assert saved.stat().st_size == size
    if difference > 0:
        assert '10 MB' in str(response.get_json())
        assert not list(directory.rglob('*'))


def test_oversized_stream_read_is_bounded_when_size_metadata_is_missing(vault):
    _, user_id, group_id, directory = vault
    stream = io.BytesIO(b'%PDF-' + b'x' * MAX_FILE_SIZE)
    uploaded = FileStorage(stream=stream, filename='booking.pdf', content_length=0)
    success, result = VaultService.upload_file(group_id, user_id, uploaded)
    assert not success and result['status_code'] == 413
    assert stream.tell() == MAX_FILE_SIZE + 1
    assert not list(Path(directory).rglob('*'))


def test_oversized_http_body_returns_413_instead_of_500(vault, app, monkeypatch):
    api, _, group_id, _ = vault
    monkeypatch.setitem(app.config, 'MAX_CONTENT_LENGTH', 4096)
    response = api.post(f'/api/v1/group-planner/groups/{group_id}/vault',
                        data={'file': (io.BytesIO(b'%PDF-' + b'x' * 5000), 'booking.pdf')},
                        content_type='multipart/form-data')
    assert response.status_code == 413, response.get_json()
