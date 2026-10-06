"""Expense group inputs match persisted limits and reject unsupported role escalation."""
from marshmallow import Schema, ValidationError, fields, validate, validates_schema

from app.core.config import Config
from app.core.schemas.fields import CurrencyCode, TrimmedString
from app.core.schemas.invitations import _EmailNormalizingSchema


class CreateExpenseGroupSchema(Schema):
    name = TrimmedString(required=True, validate=validate.Length(min=1, max=100))
    description = TrimmedString(validate=validate.Length(max=1000), allow_none=True)
    currency = CurrencyCode(load_default=Config.DEFAULT_CURRENCY)
    category = TrimmedString(validate=validate.Length(max=50), allow_none=True)


class UpdateExpenseGroupSchema(Schema):
    name = TrimmedString(validate=validate.Length(min=1, max=100))
    description = TrimmedString(validate=validate.Length(max=1000), allow_none=True)
    currency = CurrencyCode()
    category = TrimmedString(validate=validate.Length(max=50), allow_none=True)

    @validates_schema
    def require_change(self, data, **kwargs):
        if not data:
            raise ValidationError('At least one editable field is required')


class AddExpenseMemberSchema(_EmailNormalizingSchema):
    email = fields.Email(required=True)
    role = fields.String(load_default='member', validate=validate.OneOf(['member', 'admin']))


class UpdateExpenseMemberSchema(Schema):
    role = fields.String(required=True, validate=validate.OneOf(['member', 'admin']))


class JoinGroupSchema(Schema):
    code = TrimmedString(required=True, validate=validate.Length(min=1, max=50))
