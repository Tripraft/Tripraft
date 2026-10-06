"""Validated personal income requests; ownership always comes from authentication."""
from decimal import Decimal, ROUND_HALF_UP

from marshmallow import RAISE, Schema, ValidationError, fields, validate, validates_schema

from app.core.config import Config
from app.core.schemas.fields import CalendarDate, CurrencyCode, TrimmedString


class UpdateIncomeSchema(Schema):
    class Meta:
        unknown = RAISE

    description = TrimmedString(validate=validate.Length(min=1, max=500))
    amount = fields.Decimal(places=2, rounding=ROUND_HALF_UP, validate=validate.Range(
        min=Decimal('0.01'), max=Decimal(str(Config.MAX_EXPENSE_AMOUNT)),
    ))
    currency = CurrencyCode()
    income_date = CalendarDate()
    date = CalendarDate()
    category = TrimmedString(validate=validate.Length(max=50), allow_none=True)
    notes = TrimmedString(validate=validate.Length(max=1000), allow_none=True)

    @validates_schema
    def validate_fields(self, data, **kwargs):
        if not data:
            raise ValidationError('At least one editable field is required.')
        if data.get('date') and data.get('income_date') and data['date'] != data['income_date']:
            raise ValidationError({'date': ['date and income_date must agree.']})


class CreateIncomeSchema(UpdateIncomeSchema):
    description = TrimmedString(required=True, validate=validate.Length(min=1, max=500))
    amount = fields.Decimal(required=True, places=2, rounding=ROUND_HALF_UP,
                            validate=validate.Range(min=Decimal('0.01'),
                                                    max=Decimal(str(Config.MAX_EXPENSE_AMOUNT))))
    currency = CurrencyCode(load_default=Config.DEFAULT_CURRENCY)
