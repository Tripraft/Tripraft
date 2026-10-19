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


class AgreementAcknowledgment(BaseModel):
    model_config = ConfigDict(extra='forbid')
    version: int = Field(ge=1, strict=True)
    document_version: str = Field(max_length=32)
    source_sha256: str = Field(pattern=r'^[a-f0-9]{64}$')
    acknowledged: Literal[True]

    @field_validator('acknowledged', mode='before')
    @classmethod
    def explicit_acknowledgment(cls, value):
        if value is not True:
            raise ValueError('Explicit draft acknowledgment is required')
        return value


class AgreementTextBlock(BaseModel):
    kind: Literal['heading', 'paragraph', 'bullet']
    text: str


class AgreementTableBlock(BaseModel):
    kind: Literal['table']
    rows: list[list[str]]


class AgreementFurniture(BaseModel):
    part: str
    paragraphs: list[str]


class PartnerAgreementDocument(BaseModel):
    version: str
    document_date: str
    status: Literal['DRAFT']
    title: str
    source_filename: str
    source_sha256: str
    blocks: list[AgreementTextBlock | AgreementTableBlock]
    document_furniture: list[AgreementFurniture]
    acknowledgment_text: str
    original_download_available: bool = False
    signing_declaration: str
    esign_consent_text: str
    signing_confirmations: list[dict[str, str]]


class PartnerAgreementStatus(BaseModel):
    document_version: str
    source_sha256: str
    status: Literal['DRAFT']
    acknowledged: bool
    acknowledged_at: str | None
    acknowledged_by: str | None
    execution_status: Literal['NOT_EXECUTED', 'AGENT_SIGNED_DRAFT']
    commercial_activation_allowed: Literal[False]
    agent_signed: bool
    signature_required: bool
    signature_id: str | None
    signed_at: str | None
    signer_name: str | None
    signer_title: str | None


class AgentAgreementSign(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    version: int = Field(ge=1, strict=True)
    document_version: str = Field(max_length=32)
    source_sha256: str = Field(pattern=r'^[a-f0-9]{64}$')
    signer_name: str = Field(min_length=2, max_length=100)
    signer_title: str = Field(min_length=2, max_length=100)
    authority_confirmed: Literal[True]
    esign_consent: Literal[True]
    draft_understood: Literal[True]
    confirmations: list[str] = Field(min_length=8, max_length=8)

    @field_validator('authority_confirmed', 'esign_consent', 'draft_understood', mode='before')
    @classmethod
    def explicit_consent(cls, value):
        if value is not True:
            raise ValueError('Explicit confirmation is required')
        return value


class AgentSignatureReceipt(BaseModel):
    signature_id: str
    evidence_sha256: str
    evidence: dict
