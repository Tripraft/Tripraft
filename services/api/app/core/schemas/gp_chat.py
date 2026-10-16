# Purpose: Group-planner chat validation schemas.
"""Group-planner chat validation schemas."""
import bleach
from app.core.schemas.fields import UUIDString
from marshmallow import (EXCLUDE, Schema, ValidationError, fields, validate,
                         validates)

ALLOWED_MESSAGE_TYPES = (
    'text', 'poll_card', 'place_suggestion', 'checklist_update',
    'expense_added', 'plan_card', 'invite_sent',
)

ALLOWED_SENDER_TYPES = ('user', 'ai', 'system')


class SendMessageSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    content = fields.String(
        required=True,
        validate=validate.Length(min=1, max=5000),
    )
    type = fields.String(
        load_default='text',
        validate=validate.OneOf(ALLOWED_MESSAGE_TYPES),
    )
    metadata_json = fields.Dict(load_default=None)
    parent_message_id = UUIDString(load_default=None, allow_none=True)

    @validates('content')
    def sanitize_content(self, value, **kwargs):
        cleaned = bleach.clean(value, tags=[], strip=True).strip()
        if not cleaned:
            raise ValidationError('Content must not be empty after sanitization.')
        return cleaned

    @validates('metadata_json')
    def protect_server_metadata(self, value, **kwargs):
        if value and set(value) & {'agent', 'target_user_id', 'needs_consent', 'pending_key', 'edited_at', 'intent'}:
            raise ValidationError('Server message metadata cannot be supplied by users.')


class EditMessageSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    content = fields.String(required=True, validate=validate.Length(min=1, max=5000))

    @validates('content')
    def validate_content(self, value, **kwargs):
        if not bleach.clean(value, tags=[], strip=True).strip():
            raise ValidationError('Content must not be empty after sanitization.')


class ReadReceiptSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    last_read_message_id = UUIDString(required=True)
