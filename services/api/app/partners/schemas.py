# Purpose: Validates partner input without accepting role, approval or ownership fields from clients.
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class PartnerRegister(BaseModel):
    model_config = ConfigDict(extra='forbid')
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    display_name: str = Field(min_length=2, max_length=100)

    @field_validator('display_name')
    @classmethod
    def clean_name(cls, value):
        value = value.strip()
        if len(value) < 2:
            raise ValueError('Enter a representative name of at least two characters')
        return value

class PartnerLogin(BaseModel):
    model_config = ConfigDict(extra='forbid')
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class ApplicationUpdate(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    version: int = Field(ge=1, strict=True)
    business_name: str = Field(max_length=120)
    representative_name: str = Field(max_length=100)
    contact_email: EmailStr | Literal['']
    phone: str = Field(max_length=40)
    country_code: str = Field(pattern=r'^(?:[A-Za-z]{2})?$')
    business_type: Literal['tour_operator', 'travel_agency']
    operating_regions: list[str] = Field(max_length=20)
    website: str = Field(default='', max_length=500)

    @field_validator('operating_regions')
    @classmethod
    def regions(cls, values):
        result = list(dict.fromkeys(value.strip() for value in values))
        if any(not value or len(value) > 100 for value in result):
            raise ValueError('Each operating region must contain 1–100 characters')
        return result

    @field_validator('website')
    @classmethod
    def website_scheme(cls, value):
        from urllib.parse import urlparse
        if value:
            parsed = urlparse(value)
            if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password:
                raise ValueError('Use a public https website address without credentials')
        return value


class ApplicationSubmit(BaseModel):
    model_config = ConfigDict(extra='forbid')
    version: int = Field(ge=1, strict=True)
    information_attestation: Literal[True]

    @field_validator('information_attestation', mode='before')
    @classmethod
    def explicit_attestation(cls, value):
        if value is not True:
            raise ValueError('Explicit confirmation is required')
        return value


class ReviewDecision(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    version: int = Field(ge=1, strict=True)
    decision: Literal['APPROVED', 'CHANGES_REQUESTED', 'REJECTED', 'SUSPENDED']
    reason: str = Field(min_length=5, max_length=2000)
