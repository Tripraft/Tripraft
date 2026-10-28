# Purpose: Stores private group vault objects in Supabase and bounds authenticated downloads.
"""Server-only Supabase Storage access; membership is enforced by VaultService."""
import re
from urllib.parse import quote, urlsplit

import requests

from app.core.config import Config

MAX_VAULT_FILE_SIZE = 10 * 1024 * 1024
REFERENCE_PREFIX = 'supabase://'
_BUCKET = re.compile(r'[A-Za-z0-9][A-Za-z0-9._-]{0,99}')
_KEY = re.compile(r'groups/[0-9a-fA-F-]{36}/[0-9a-f]{32}\.(pdf|jpg|png|webp)')


class VaultStorageError(Exception):
    def __init__(self, message='Shared file storage is unavailable. Please try again.', status_code=503):
        super().__init__(message)
        self.status_code = status_code


class SupabaseVaultStorage:
    def __init__(self):
        self.base_url = Config.SUPABASE_URL.strip().rstrip('/')
        self.bucket = Config.SUPABASE_VAULT_BUCKET.strip()
        key = Config.SUPABASE_SERVICE_ROLE_KEY.strip()
        parsed = urlsplit(self.base_url)
        if (not key or parsed.scheme != 'https' or not parsed.netloc
                or parsed.username or parsed.password or parsed.query or parsed.fragment or parsed.path
                or not _BUCKET.fullmatch(self.bucket) or '..' in self.bucket):
            raise VaultStorageError('Shared file storage is not configured. Ask the administrator to configure Supabase Storage.')
        self.base_url += '/storage/v1'
        self.headers = {'apikey': key, 'Authorization': 'Bearer ' + key}

    @staticmethod
    def is_reference(value):
        return value.startswith(REFERENCE_PREFIX)

    def reference(self, group_id, filename):
        return f'{REFERENCE_PREFIX}{self.bucket}/groups/{group_id}/{filename}'

    @staticmethod
    def _parts(reference, group_id):
        parsed = urlsplit(reference)
        key = parsed.path.lstrip('/')
        if (parsed.scheme != 'supabase' or not _BUCKET.fullmatch(parsed.netloc)
                or '..' in parsed.netloc or not _KEY.fullmatch(key)
                or not key.startswith(f'groups/{group_id}/') or parsed.query or parsed.fragment):
            raise VaultStorageError('Invalid stored document reference.', 404)
        return parsed.netloc, key

    def _request(self, method, path, **kwargs):
        try:
            response = requests.request(
                method, self.base_url + path, headers={**self.headers, **kwargs.pop('headers', {})},
                timeout=(5, 30), allow_redirects=False, **kwargs,
            )
        except requests.RequestException:
            raise VaultStorageError() from None
        return response

    def require_private_bucket(self, bucket):
        with self._request('GET', '/bucket/' + quote(bucket, safe='')) as response:
            if response.status_code != 200:
                raise VaultStorageError('Shared file storage is unavailable. Check the private Supabase bucket configuration.')
            try:
                private = response.json().get('public') is False
            except (ValueError, AttributeError):
                private = False
            if not private:
                raise VaultStorageError('Group files require a private Supabase bucket. Contact the administrator.')

    def prepare_bucket(self, create=False):
        """Operator setup only; uploads never silently create or change buckets."""
        path = '/bucket/' + quote(self.bucket, safe='')
        with self._request('GET', path) as response:
            missing = response.status_code == 404
        if missing and create:
            with self._request('POST', '/bucket', json={
                'id': self.bucket, 'name': self.bucket, 'public': False,
                'file_size_limit': MAX_VAULT_FILE_SIZE,
                'allowed_mime_types': ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'],
            }) as response:
                if response.status_code not in (200, 201, 409):
                    raise VaultStorageError('Could not create the private vault bucket.')
        self.require_private_bucket(self.bucket)

    def upload(self, reference, group_id, data, mime_type):
        bucket, key = self._parts(reference, group_id)
        if len(data) > MAX_VAULT_FILE_SIZE:
            raise VaultStorageError('File exceeds 10 MB limit', 413)
        self.require_private_bucket(bucket)
        with self._request('POST', f'/object/{quote(bucket, safe="")}/{quote(key, safe="/")}',
                           data=data, headers={'Content-Type': mime_type, 'x-upsert': 'false', 'cache-control': '0'}) as response:
            if response.status_code not in (200, 201):
                raise VaultStorageError()

    def download(self, reference, group_id):
        bucket, key = self._parts(reference, group_id)
        with self._request('GET', f'/object/authenticated/{quote(bucket, safe="")}/{quote(key, safe="/")}',
                           stream=True) as response:
            if response.status_code == 404:
                raise VaultStorageError('Document not found in shared storage.', 404)
            if response.status_code != 200:
                raise VaultStorageError()
            data = bytearray()
            try:
                for chunk in response.iter_content(chunk_size=64 * 1024):
                    if len(data) + len(chunk) > MAX_VAULT_FILE_SIZE:
                        raise VaultStorageError('Stored file exceeds the 10 MB limit.', 413)
                    data.extend(chunk)
            except requests.RequestException:
                raise VaultStorageError() from None
            return bytes(data)

    def delete(self, reference, group_id):
        bucket, key = self._parts(reference, group_id)
        with self._request('DELETE', '/object/' + quote(bucket, safe=''), json={'prefixes': [key]}) as response:
            if response.status_code not in (200, 204, 404):
                raise VaultStorageError('Could not remove the document from shared storage. Please retry.')
