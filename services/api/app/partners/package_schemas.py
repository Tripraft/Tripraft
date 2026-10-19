# Purpose: Bounds private tour draft input, exact proposed rates and ownership/version allowlists.
from datetime import date
from typing import Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class DraftModel(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)


class TourDay(DraftModel):
    day: int = Field(ge=1, le=60, strict=True)
    title: str = Field(default='', max_length=120)
    details: str = Field(default='', max_length=4000)
    meals: str = Field(default='', max_length=300)
    accommodation: str = Field(default='', max_length=500)


class DepartureProposal(DraftModel):
    start_date: date | None = None
    timezone: str = Field(default='', max_length=64)
    supplier_rate_minor: str = Field(default='', pattern=r'^(?:[0-9]{1,12})?$')
    currency: str = Field(default='', pattern=r'^(?:[A-Z]{3})?$')
    currency_exponent: int = Field(default=2, ge=0, le=4, strict=True)
    rate_basis: Literal['per_person', 'per_group'] = 'per_person'
    notes: str = Field(default='', max_length=500)

    @field_validator('supplier_rate_minor')
    @classmethod
    def positive_proposal(cls, value):
        if value and int(value) <= 0:
            raise ValueError('A proposed supplier rate must be positive')
        return str(int(value)) if value else ''

    @field_validator('timezone')
    @classmethod
    def valid_zone(cls, value):
        if value:
            try:
                ZoneInfo(value)
            except (ZoneInfoNotFoundError, ValueError):
                raise ValueError('Use a valid IANA time zone') from None
        return value


class TourDraftContent(DraftModel):
    title: str = Field(default='', max_length=120)
    summary: str = Field(default='', max_length=2000)
    language: str = Field(default='', max_length=80)
    supplier_sku: str = Field(default='', max_length=80)
    days: int = Field(default=1, ge=1, le=60, strict=True)
    nights: int = Field(default=0, ge=0, le=60, strict=True)
    overnight_explanation: str = Field(default='', max_length=500)
    route: list[str] = Field(default_factory=list, max_length=60)
    itinerary: list[TourDay] = Field(default_factory=list, max_length=60)
    inclusions: list[str] = Field(default_factory=list, max_length=40)
    exclusions: list[str] = Field(default_factory=list, max_length=40)
    transport_details: str = Field(default='', max_length=2000)
    accessibility_notes: str = Field(default='', max_length=1000)
    cancellation_policy: str = Field(default='', max_length=4000)
    safety_notes: str = Field(default='', max_length=2000)
    departures: list[DepartureProposal] = Field(default_factory=list, max_length=100)
    media_ids: list[UUID] = Field(default_factory=list, max_length=10)

    @field_validator('media_ids')
    @classmethod
    def unique_media(cls, values):
        if len(set(values)) != len(values):
            raise ValueError('Each image may be selected only once')
        return values

    @field_validator('route', 'inclusions', 'exclusions')
    @classmethod
    def bounded_items(cls, values):
        if any(not value or len(value) > 300 for value in values):
            raise ValueError('Each item needs 1–300 characters')
        return values

    @field_validator('itinerary')
    @classmethod
    def unique_days(cls, values):
        if len({value.day for value in values}) != len(values):
            raise ValueError('Each itinerary day number must be unique')
        return sorted(values, key=lambda value: value.day)


class CreateTourDraft(DraftModel):
    pass


class SaveTourDraft(DraftModel):
    version: int = Field(ge=1, strict=True)
    content: TourDraftContent


class DuplicateTourDraft(DraftModel):
    version: int = Field(ge=1, strict=True)


class SubmitTourPackage(DraftModel):
    version: int = Field(ge=1, strict=True)
    information_attestation: Literal[True]

    @field_validator('information_attestation', mode='before')
    @classmethod
    def explicit_attestation(cls, value):
        if value is not True:
            raise ValueError('Explicit package confirmation is required')
        return value


class PackageReviewDecision(DraftModel):
    version: int = Field(ge=1, strict=True)
    revision: int = Field(ge=1, strict=True)
    decision: Literal['APPROVED', 'CHANGES_REQUESTED', 'REJECTED']
    reason: str = Field(min_length=5, max_length=2000)


class UploadPackageImage(DraftModel):
    version: int = Field(ge=1, strict=True)
    caption: str = Field(min_length=2, max_length=300)
    rights_source: str = Field(min_length=5, max_length=500)


class PackageSummary(BaseModel):
    id: UUID
    version: int
    revision: int
    status: Literal['DRAFT', 'UNDER_REVIEW', 'CHANGES_REQUESTED', 'APPROVED', 'REJECTED']
    title: str
    days: int
    nights: int
    route: list[str]
    updated_at: datetime


class PackageDraft(PackageSummary):
    content: TourDraftContent
    preparation_notes: list[str]
    can_submit: bool
    submission_blocker: str
    can_edit: bool
    revision_status: str
    review_reason: str | None
    approved_revision: int | None
    submitted_at: str | None
    media: list[dict]


class PackageList(BaseModel):
    packages: list[PackageSummary]
    total: int


class PackageReviewItem(BaseModel):
    package: PackageDraft
    business_name: str
    agent_id: UUID
    is_demo: bool
    is_own_application: bool


class PackageReviewList(BaseModel):
    packages: list[PackageReviewItem]
    total: int
