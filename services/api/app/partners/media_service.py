# Purpose: Validates image bytes, strips metadata and stores supplier package media outside public static directories.
from io import BytesIO
import hashlib
import os
from pathlib import Path
import re
from uuid import uuid4

from PIL import Image, UnidentifiedImageError

from app.core.config import Config
from app.partners.models import utcnow
from app.partners.package_models import TourPackageMedia
from app.partners.services import PartnerError

MAX_BYTES = 6 * 1024 * 1024


def storage_root():
    return Path(os.getenv('PARTNER_MEDIA_DIR', str(Config.BASE_DIR / 'uploads/partners'))).resolve()


def media_path(image):
    if not re.fullmatch(r'[a-f0-9]{32}\.jpg', image.storage_key):
        raise PartnerError('Image storage reference is invalid.', 404)
    path = (storage_root() / image.storage_key).resolve()
    if path.parent != storage_root():
        raise PartnerError('Image unavailable.', 404)
    return path


def sanitized_image(upload):
    raw = upload.stream.read(MAX_BYTES + 1)
    if not raw or len(raw) > MAX_BYTES:
        raise PartnerError('Choose an image smaller than 6 MB.', 422)
    try:
        with Image.open(BytesIO(raw)) as image:
            if image.format not in {'JPEG', 'PNG', 'WEBP'} or getattr(image, 'n_frames', 1) != 1:
                raise PartnerError('Use a single JPEG, PNG or WebP image.', 422)
            width, height = image.size
            if width < 800 or height < 400 or width > 4096 or height > 4096 or width * height > 16_000_000:
                raise PartnerError('Image dimensions must be at least 800×400 and no more than 4096×4096.', 422)
            image.load()
            # Copy pixel data into a new image: no EXIF, location, text or embedded profile is retained.
            pixels = Image.new('RGB', image.size, 'white')
            if 'A' in image.getbands():
                rgba = image.convert('RGBA')
                pixels.paste(rgba, mask=rgba.getchannel('A'))
            else:
                pixels.paste(image.convert('RGB'))
            pixels.thumbnail((2400, 1600))
            output = BytesIO()
            pixels.save(output, format='JPEG', quality=88, optimize=True)
            return output.getvalue(), pixels.width, pixels.height
    except (UnidentifiedImageError, Image.DecompressionBombError, OSError, ValueError):
        raise PartnerError('The image is invalid or unsafe to decode.', 422) from None


def upload_image(session, user_id, package, revision, upload, data):
    from app.partners.package_schemas import TourDraftContent
    from app.partners.package_services import serialize
    if package.version != data.version:
        raise PartnerError('This package changed. Reload before uploading.', 409, 'VERSION_CONFLICT')
    if package.status not in {'DRAFT', 'CHANGES_REQUESTED'} or revision.status != 'DRAFT':
        raise PartnerError('Submitted package images are locked for review.', 409)
    content = TourDraftContent.model_validate(revision.content).model_dump(mode='json')
    if len(content['media_ids']) >= 10:
        raise PartnerError('Select at most ten package images.', 422)
    encoded, width, height = sanitized_image(upload)
    storage_root().mkdir(parents=True, exist_ok=True)
    key = uuid4().hex + '.jpg'
    row = TourPackageMedia(package_id=package.id, agent_id=package.agent_id, uploaded_by=user_id,
        storage_key=key, sha256=hashlib.sha256(encoded).hexdigest(), byte_size=len(encoded), width=width, height=height,
        caption=data.caption, rights_source=data.rights_source, rights_confirmed_at=utcnow())
    destination = media_path(row)
    temporary = destination.with_suffix('.tmp')
    try:
        temporary.write_bytes(encoded)
        temporary.replace(destination)
        session.add(row)
        session.flush()
        content['media_ids'].append(str(row.id))
        revision.content = content
        package.updated_at = utcnow()
        session.commit()
    except Exception:
        session.rollback()
        temporary.unlink(missing_ok=True)
        destination.unlink(missing_ok=True)
        raise
    return serialize(package, revision)
