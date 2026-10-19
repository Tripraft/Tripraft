// Purpose: Defines private supplier package drafts, bounded itinerary inputs and exact rate proposals.
export interface TourDay { day: number; title: string; details: string; meals: string; accommodation: string }
export interface DepartureProposal { start_date: string | null; timezone: string; supplier_rate_minor: string; currency: string; currency_exponent: number; rate_basis: 'per_person' | 'per_group'; notes: string }
export interface TourDraftContent {
  title: string; summary: string; language: string; supplier_sku: string; days: number; nights: number;
  overnight_explanation: string; route: string[]; itinerary: TourDay[]; inclusions: string[]; exclusions: string[];
  transport_details: string; accessibility_notes: string; cancellation_policy: string; safety_notes: string;
  departures: DepartureProposal[];
}
export interface TourPackageSummary { id: string; version: number; revision: number; status: 'DRAFT'; title: string; days: number; nights: number; route: string[]; updated_at: string }
export interface TourPackageDraft extends TourPackageSummary { content: TourDraftContent; preparation_notes: string[]; can_submit: boolean; submission_blocker: string }
export interface TourPackageList { packages: TourPackageSummary[]; total: number }
