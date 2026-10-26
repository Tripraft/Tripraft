"""Expense group inputs match persisted limits and reject unsupported role escalation."""
from marshmallow import Schema, ValidationError, fields, validate, validates_schema
from decimal import Decimal, ROUND_HALF_UP

from app.core.config import Config
from app.core.schemas.fields import CurrencyCode, TrimmedString
from app.core.schemas.invitations import _EmailNormalizingSchema


class GroupPreferencesSchema(Schema):
    display_currency = CurrencyCode()
    budget = fields.Decimal(places=2, rounding=ROUND_HALF_UP, allow_none=True,
                            validate=validate.Range(min=Decimal('0'), max=Decimal('9999999999.99')))
    start_date = fields.Date(allow_none=True)
    end_date = fields.Date(allow_none=True)

    @validates_schema
    def valid_dates(self, data, **kwargs):
        if data.get('start_date') and data.get('end_date') and data['start_date'] > data['end_date']:
            raise ValidationError('End date must be on or after start date')


class CreateExpenseGroupSchema(GroupPreferencesSchema):
    name = TrimmedString(required=True, validate=validate.Length(min=1, max=100))
    description = TrimmedString(validate=validate.Length(max=1000), allow_none=True)
    currency = CurrencyCode(load_default=Config.DEFAULT_CURRENCY)
    category = TrimmedString(validate=validate.Length(max=50), allow_none=True)


class UpdateExpenseGroupSchema(GroupPreferencesSchema):
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
