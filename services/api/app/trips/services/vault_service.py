# Purpose: Vault Service for Group Planner Handles file upload/download for the logistics vault.
"""
Vault Service for Group Planner
Handles file upload/download for the logistics vault.
New files use the shared application database; a private object bucket and legacy local files remain supported.
"""

import logging
import base64
import binascii
import os
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Tuple

from app.trips.models import (GroupActivity, TravelGroup,
                                             TripMember, VaultDocument, VaultFileContent)
from app.core.db.connection import get_db_session
from app.core.config import Config
from app.trips.services.vault_storage import MAX_VAULT_FILE_SIZE, SupabaseVaultStorage, VaultStorageError
from sqlalchemy.orm import joinedload

logger = logging.getLogger(__name__)

ALLOWED_MIME_TYPES = {
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
}
_EXTENSION_BY_MIME = {
    'application/pdf': '.pdf',
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
}
MAX_FILE_SIZE = MAX_VAULT_FILE_SIZE


class VaultService:

    @staticmethod
    def _publish_change(group_id, event, payload):
        from app.core.cache.redis import invalidate_cache
        invalidate_cache('gp_groups:*')
        try:
            from app.trips.realtime.events import emit_to_group
            emit_to_group(group_id, event, payload)
        except Exception:
            logger.debug('Vault broadcast unavailable', exc_info=True)

    @staticmethod
    def _upload_dir(group_id: str) -> str:
        base = os.environ.get('UPLOAD_DIR', os.path.join(os.getcwd(), 'uploads'))
        path = os.path.join(base, 'vault', str(group_id))
        os.makedirs(path, exist_ok=True)
        return path

    @staticmethod
    def _document_path(group_id: str, filename: str) -> str:
        """Build a vault path without allowing legacy names to traverse it."""
        directory = os.path.abspath(VaultService._upload_dir(group_id))
        basename = os.path.basename(filename)
        path = os.path.abspath(os.path.join(directory, basename))
        if os.path.commonpath((directory, path)) != directory:
            raise ValueError('Invalid vault file path')
        return path

    @staticmethod
    def _detect_mime(data: bytes) -> str | None:
        """Identify supported files from their signatures, never HTTP metadata."""
        if data.startswith(b'%PDF-'):
            return 'application/pdf'
        if data.startswith(b'\xff\xd8\xff'):
            return 'image/jpeg'
        if data.startswith(b'\x89PNG\r\n\x1a\n'):
            return 'image/png'
        if data.startswith(b'RIFF') and data[8:12] == b'WEBP':
            return 'image/webp'
        return None

    @staticmethod
    def upload_file(
        group_id: str,
        user_id: str,
        file_storage,
    ) -> Tuple[bool, Dict[str, Any]]:
        temporary_path = None
        remote_storage = None
        remote_reference = None
        metadata_committed = False
        try:
            with get_db_session() as session:
                member = session.query(TripMember).join(TravelGroup).filter(
                    TripMember.group_id == group_id,
                    TripMember.user_id == user_id,
                    TripMember.is_active == True,
                    TravelGroup.is_active == True,
                ).first()
                if not member or member.role not in {'creator', 'admin', 'member'}:
                    return False, {'error': 'Not a member of this group'}

                # Read at most the limit plus one byte, even when the client
                # omits or falsifies its size metadata.
                data = file_storage.read(MAX_FILE_SIZE + 1)
                if len(data) > MAX_FILE_SIZE:
                    return False, {'error': 'File exceeds 10 MB limit', 'status_code': 413}
                if len(data) == 0:
                    return False, {'error': 'Empty file'}

                # Content-Type and filename extensions come from the client;
                # use a compact signature allowlist and a server-assigned
                # extension instead.
                mime = VaultService._detect_mime(data)
                if mime not in ALLOWED_MIME_TYPES:
                    return False, {'error': 'File type not allowed. Accepted: PDF, JPEG, PNG, WebP'}
                original_name = os.path.basename(file_storage.filename or 'untitled')[:255]

                # Generate unique filename
                ext = _EXTENSION_BY_MIME[mime]
                safe_name = f"{uuid.uuid4().hex}{ext}"

                if Config.VAULT_STORAGE_BACKEND == 'database':
                    stored_name = 'database'
                elif Config.VAULT_STORAGE_BACKEND == 'supabase':
                    remote_storage = SupabaseVaultStorage()
                    remote_reference = remote_storage.reference(group_id, safe_name)
                    remote_storage.upload(remote_reference, group_id, data, mime)
                    stored_name = remote_reference
                elif Config.VAULT_STORAGE_BACKEND == 'local':
                    dest_path = VaultService._document_path(group_id, safe_name)
                    temporary_path = f'{dest_path}.{uuid.uuid4().hex}.uploading'
                    with open(temporary_path, 'xb') as f:
                        f.write(data)
                    stored_name = safe_name
                else:
                    raise VaultStorageError('Invalid vault storage backend configuration.')

                doc = VaultDocument(
                    group_id=group_id,
                    filename=stored_name,
                    original_filename=original_name,
                    mime_type=mime,
                    file_size=len(data),
                    uploaded_by=user_id,
                )
                session.add(doc)
                session.flush()
                if stored_name == 'database':
                    session.add(VaultFileContent(
                        document_id=doc.id, content_base64=base64.b64encode(data).decode('ascii'),
                    ))

                activity = GroupActivity(
                    group_id=group_id,
                    user_id=user_id,
                    action='vault_upload',
                    entity_type='vault',
                    entity_id=doc.id,
                    details={'filename': original_name[:80]},
                )
                session.add(activity)

                session.flush()
                document = doc.to_dict()
                session.commit()
                metadata_committed = True

                if temporary_path:
                    try:
                        os.replace(temporary_path, dest_path)
                        temporary_path = None
                    except OSError as exc:
                        logger.error('Vault file publication failed: %s', exc)
                        doc.is_deleted = True
                        session.commit()
                        return False, {'error': 'Failed to store upload'}

            VaultService._publish_change(group_id, 'vault:uploaded', {'document': document, 'user_id': str(user_id)})
            return True, {'document': document}

        except VaultStorageError as exc:
            return False, {'error': str(exc), 'status_code': exc.status_code}
        except Exception as e:
            logger.error("Vault upload error: %s", e)
            return False, {'error': 'Failed to upload file'}
        finally:
            if remote_storage and remote_reference and not metadata_committed:
                try:
                    remote_storage.delete(remote_reference, group_id)
                except VaultStorageError:
                    logger.error('Failed to clean up uncommitted vault object: %s', remote_reference)
            if temporary_path:
                try:
                    os.remove(temporary_path)
                except FileNotFoundError:
                    pass
                except OSError as exc:
                    logger.error('Could not clean up failed vault upload: %s', exc)

    @staticmethod
    def list_files(group_id: str, user_id: str) -> Tuple[bool, Dict[str, Any]]:
        try:
            with get_db_session() as session:
                member = session.query(TripMember).join(TravelGroup).filter(
                    TripMember.group_id == group_id,
                    TripMember.user_id == user_id,
                    TripMember.is_active == True,
                    TravelGroup.is_active == True,
                ).first()
                if not member:
                    return False, {'error': 'Not a member of this group'}

                docs = session.query(VaultDocument).options(joinedload(VaultDocument.uploader)).filter(
                    VaultDocument.group_id == group_id,
                    VaultDocument.is_deleted == False,
                ).order_by(VaultDocument.created_at.desc()).all()

                return True, {'documents': [d.to_dict() for d in docs]}

        except Exception as e:
            logger.error("Vault list error: %s", e)
            return False, {'error': 'Failed to list vault documents'}

    @staticmethod
    def delete_file(group_id: str, doc_id: str, user_id: str) -> Tuple[bool, Dict[str, Any]]:
        try:
            with get_db_session() as session:
                member = session.query(TripMember).join(TravelGroup).filter(
                    TripMember.group_id == group_id,
                    TripMember.user_id == user_id,
                    TripMember.is_active == True,
                    TravelGroup.is_active == True,
                ).first()
                if not member:
                    return False, {'error': 'Not a member of this group'}

                doc = session.query(VaultDocument).filter(
                    VaultDocument.id == doc_id,
                    VaultDocument.group_id == group_id,
                    VaultDocument.is_deleted == False,
                ).first()
                if not doc:
                    return False, {'error': 'Document not found'}

                is_group_admin = member.role in {'creator', 'admin'}
                if str(doc.uploaded_by) != str(user_id) and not is_group_admin:
                    return False, {
                        'error': 'Only the uploader or a group admin may delete this document',
                        'status_code': 403,
                    }

                stored_name = doc.filename
                if stored_name == 'database':
                    session.query(VaultFileContent).filter(VaultFileContent.document_id == doc.id).delete()
                doc.is_deleted = True
                session.commit()

            # The database commit makes the document inaccessible.  Remove
            # its private bytes immediately rather than retaining a growing
            # collection of soft-deleted files on disk.
            try:
                if stored_name == 'database':
                    pass  # Body and metadata deletion committed atomically above.
                elif SupabaseVaultStorage.is_reference(stored_name):
                    SupabaseVaultStorage().delete(stored_name, group_id)
                else:
                    os.remove(VaultService._document_path(group_id, stored_name))
            except FileNotFoundError:
                pass
            except (OSError, VaultStorageError) as exc:
                # Do not claim deletion while private bytes remain on disk.
                # Restore the metadata so the caller can retry, instead of
                # creating an unreachable file with no cleanup queue.
                logger.error('Vault storage cleanup failed for %s', doc_id)
                with get_db_session() as recovery_session:
                    failed_delete = recovery_session.get(VaultDocument, doc_id)
                    if failed_delete:
                        failed_delete.is_deleted = False
                        recovery_session.commit()
                return False, {'error': 'Failed to remove document from storage',
                               'status_code': getattr(exc, 'status_code', 500)}

            VaultService._publish_change(group_id, 'vault:deleted', {'document_id': doc_id, 'user_id': str(user_id)})
            return True, {'message': 'Document deleted'}

        except Exception as e:
            logger.error("Vault delete error: %s", e)
            return False, {'error': 'Failed to delete document'}

    @staticmethod
    def get_file_path(group_id: str, doc_id: str, user_id: str) -> Tuple[bool, Dict[str, Any]]:
        """Authorize every member read and return private cloud bytes or a legacy path."""
        try:
            with get_db_session() as session:
                member = session.query(TripMember).join(TravelGroup).filter(
                    TripMember.group_id == group_id,
                    TripMember.user_id == user_id,
                    TripMember.is_active == True,
                    TravelGroup.is_active == True,
                ).first()
                if not member:
                    return False, {'error': 'Not a member of this group'}

                row = session.query(VaultDocument, VaultFileContent.content_base64).outerjoin(
                    VaultFileContent, VaultFileContent.document_id == VaultDocument.id,
                ).filter(
                    VaultDocument.id == doc_id,
                    VaultDocument.group_id == group_id,
                    VaultDocument.is_deleted == False,
                ).first()
                if not row:
                    return False, {'error': 'Document not found'}
                doc, content = row
                stored_name = doc.filename
                expected_size = doc.file_size
                result = {
                    'filename': doc.original_filename,
                    'mime_type': doc.mime_type,
                }
            if stored_name == 'database':
                if content is None or len(content) > 4 * ((MAX_FILE_SIZE + 2) // 3):
                    raise VaultStorageError('Stored document content is unavailable.')
                try:
                    result['data'] = base64.b64decode(content, validate=True)
                except (ValueError, binascii.Error):
                    raise VaultStorageError('Stored document content is invalid.') from None
            elif SupabaseVaultStorage.is_reference(stored_name):
                result['data'] = SupabaseVaultStorage().download(stored_name, group_id)
            else:
                path = VaultService._document_path(group_id, stored_name)
                if not os.path.isfile(path):
                    return False, {'error': 'File not found on disk'}
                result['path'] = path
            if 'data' in result and (len(result['data']) != expected_size or len(result['data']) > MAX_FILE_SIZE):
                raise VaultStorageError('Stored document size does not match its metadata.')
            return True, result

        except VaultStorageError as exc:
            return False, {'error': str(exc), 'status_code': exc.status_code}
        except Exception as e:
            logger.error("Vault get file error: %s", e)
            return False, {'error': 'Failed to get file'}


vault_service = VaultService()
