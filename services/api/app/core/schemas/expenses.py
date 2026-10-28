# Purpose: Expense-related validation schemas.
"""Expense-related validation schemas."""
from decimal import Decimal, ROUND_HALF_UP

from app.core.config import Config
from app.core.schemas.fields import CalendarDate, CurrencyCode, TrimmedString, UUIDString
from marshmallow import EXCLUDE, Schema, ValidationError, fields, validate, validates_schema


class CreateExpenseSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    description = TrimmedString(
        required=True,
        validate=validate.Length(min=1, max=500),
    )
    amount = fields.Decimal(
        required=True,
        places=2,
        rounding=ROUND_HALF_UP,
        as_string=False,
        validate=validate.Range(
            min=Decimal('0.01'),
            max=Decimal(str(Config.MAX_EXPENSE_AMOUNT)),
        ),
    )
    group_id = UUIDString(load_default=None, allow_none=True)
    paid_by = UUIDString(load_default=None, allow_none=True)
    payers = fields.List(fields.Dict(), validate=validate.Length(min=1, max=100))
    split_type = fields.String(
        validate=validate.OneOf(Config.SPLIT_TYPES + [s.upper() for s in Config.SPLIT_TYPES]),
        load_default='equal',
    )
    splits = fields.List(fields.Dict(), load_default=None, allow_none=True)
    split_details = fields.Dict(load_default=None, allow_none=True)
    category = fields.String(
        validate=validate.Length(max=50),
        load_default=None,
        allow_none=True,
    )
    expense_date = CalendarDate(load_default=None, allow_none=True)
    date = CalendarDate(load_default=None, allow_none=True)
    notes = fields.String(validate=validate.Length(max=1000), load_default=None, allow_none=True)
    receipt_url = fields.String(load_default=None, allow_none=True)
    currency = CurrencyCode(load_default=Config.DEFAULT_CURRENCY)

    @validates_schema
    def validate_date_alias(self, data, **kwargs):
        if data.get('date') and data.get('expense_date') and data['date'] != data['expense_date']:
            raise ValidationError({'date': ['date and expense_date must agree.']})


class UpdateExpenseSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    description = TrimmedString(validate=validate.Length(min=1, max=500))
    amount = fields.Decimal(
        places=2,
        rounding=ROUND_HALF_UP,
        as_string=False,
        validate=validate.Range(
            min=Decimal('0.01'),
            max=Decimal(str(Config.MAX_EXPENSE_AMOUNT)),
        ),
    )
    paid_by = UUIDString()
    payers = fields.List(fields.Dict(), validate=validate.Length(min=1, max=100))
    split_type = fields.String(
        validate=validate.OneOf(Config.SPLIT_TYPES + [s.upper() for s in Config.SPLIT_TYPES]),
    )
    splits = fields.List(fields.Dict())
    split_details = fields.Dict(allow_none=True)
    category = fields.String(validate=validate.Length(max=50), allow_none=True)
    expense_date = CalendarDate()
    date = CalendarDate()
    notes = fields.String(validate=validate.Length(max=1000), allow_none=True)
    receipt_url = fields.String(allow_none=True)
    currency = CurrencyCode()

    @validates_schema
    def validate_update(self, data, **kwargs):
        if not data:
            raise ValidationError('At least one editable field is required.')
        if data.get('date') and data.get('expense_date') and data['date'] != data['expense_date']:
            raise ValidationError({'date': ['date and expense_date must agree.']})
