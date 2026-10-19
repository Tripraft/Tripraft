// Purpose: Defines the private partner onboarding and internal review API contracts.
export type PartnerStatus = 'DRAFT_APPLICATION' | 'UNDER_REVIEW' | 'CHANGES_REQUESTED' | 'APPROVED' | 'SUSPENDED' | 'REJECTED';
export type PartnerDecision = 'APPROVED' | 'CHANGES_REQUESTED' | 'REJECTED' | 'SUSPENDED';
export interface PartnerApplication {
  id: string;
  status: PartnerStatus;
  version: number;
  is_demo: boolean;
  business_name: string;
  representative_name: string;
  contact_email: string;
  phone: string;
  country_code: string;
  business_type: 'tour_operator' | 'travel_agency';
  operating_regions: string[];
  website: string;
  review_reason: string | null;
  submitted_at: string | null;
  updated_at: string;
}
export type PartnerApplicationInput = Pick<PartnerApplication, 'version' | 'business_name' | 'representative_name' | 'contact_email' | 'phone' | 'country_code' | 'business_type' | 'operating_regions' | 'website'>;
export interface PartnerSnapshot {
  user: { id: string; email: string; display_name: string; email_verified: boolean };
  application: PartnerApplication;
  agreement: PartnerAgreementStatus;
  capabilities: { can_edit_application: boolean; can_submit_application: boolean; can_view_dashboard: boolean; can_manage_packages: boolean };
  verification_email_sent?: boolean;
}
export interface PartnerReviewApplication extends PartnerApplication { is_own_application: boolean; agreement: PartnerAgreementStatus }
export interface PartnerReviewList { applications: PartnerReviewApplication[]; total: number }

export interface PartnerAgreementStatus {
  document_version: string;
  source_sha256: string;
  status: 'DRAFT';
  acknowledged: boolean;
  acknowledged_at: string | null;
  acknowledged_by: string | null;
  execution_status: 'NOT_EXECUTED';
  commercial_activation_allowed: false;
}
export type AgreementBlock = { kind: 'heading' | 'paragraph' | 'bullet'; text: string } | { kind: 'table'; rows: string[][] };
export interface PartnerAgreementDocument {
  version: string;
  document_date: string;
  status: 'DRAFT';
  title: string;
  source_filename: string;
  source_sha256: string;
  blocks: AgreementBlock[];
  document_furniture: { part: string; paragraphs: string[] }[];
  acknowledgment_text: string;
}
