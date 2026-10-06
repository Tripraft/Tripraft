# Purpose: Settlement validation schemas.
"""Settlement validation schemas."""
from app.core.config import Config
from decimal import Decimal, ROUND_HALF_UP
from app.core.schemas.fields import UUIDString
from marshmallow import (EXCLUDE, Schema, ValidationError, fields, validate,
                         validates)


class CreateSettlementSchema(Schema):
    class Meta:
        unknown = EXCLUDE

    group_id = UUIDString(required=True)
    from_user_id = UUIDString(load_default=None, allow_none=True)
    from_user = UUIDString(load_default=None, allow_none=True)      # alias
    to_user_id = UUIDString(load_default=None, allow_none=True)
    to_user = UUIDString(load_default=None, allow_none=True)         # alias
    amount = fields.Decimal(
        required=True,
        places=2, rounding=ROUND_HALF_UP,
        validate=validate.Range(min=Decimal('0.01'), max=Decimal(str(Config.MAX_EXPENSE_AMOUNT))),
    )
    method = fields.String(
        validate=validate.OneOf(Config.PAYMENT_METHODS),
        load_default=Config.DEFAULT_PAYMENT_METHOD,
    )
    notes = fields.String(validate=validate.Length(max=1000), load_default=None)

    @validates('amount')
    def validate_amount(self, value, **kwargs):
        """Ensure amount is positive."""
        if value <= 0:
            raise ValidationError('Amount must be greater than zero')
