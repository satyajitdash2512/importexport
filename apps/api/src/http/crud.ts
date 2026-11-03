/**
 * Generic CRUD layer. Each resource declares its table, the columns a client may
 * write, and how its public id (P-001, CS-001, …) resolves to the physical row.
 * The router then serves list/get/create/update/delete for every resource,
 * entity-scoped and permission-checked, so the front end gets working
 * New / Edit / Delete on every screen from one framework.
 *
 * Partitioned tables (declaration, voucher) carry period_key in their primary
 * key; the resolver fetches it, and create derives it from a date column.
 */
import { Router } from 'express';
import { q, q1, exec, withTx, n } from '../db/pool.js';
import { HttpError, requirePermission, h, type AuthedRequest } from './context.js';
import { writeAudit } from '../repos/audit.js';

const actor = (req: AuthedRequest) => ({ entityId: req.entityId!, userId: req.auth?.sub, username: req.auth?.username });

type IdKind = 'surrogate' | 'partitioned' | { natural: string };

export interface Resource {
  name: string;
  table: string;
  perm: string;              // base permission; needs `${perm}:read` and `${perm}:write`
  idKind: IdKind;
  columns: string[];         // writable columns
  required: string[];
  /** public-id prefix for surrogate/partitioned resources (e.g. 'P' → P-001). */
  extPrefix?: string;
  /** column holding a date, used to derive period_key on create (partitioned). */
  periodDate?: string;
  /** default values injected on create (besides entity_id). */
  defaults?: Record<string, any>;
  /** order-by for list. */
  orderBy?: string;
  /** text columns a server-side `q` search matches against (LIKE). */
  searchCols?: string[];
}

const pad3 = (id: number | string) => String(id).padStart(3, '0');
const pk = (d: string) => Number(d.slice(0, 4)) * 100 + Number(d.slice(5, 7));

export const RESOURCES: Record<string, Resource> = {
  parties: {
    name: 'parties', table: 'trade_party', perm: 'party', idKind: 'surrogate', extPrefix: 'P',
    columns: ['contact_code', 'name', 'legal_name', 'country_code', 'currency', 'gstin', 'pan', 'iec', 'ledger_group', 'default_incoterm', 'default_payment_term', 'is_related_party', 'bank_verified', 'screening_status'],
    required: ['contact_code', 'name', 'legal_name', 'country_code', 'currency'],
    defaults: { screening_status: 'NOT_SCREENED' }, orderBy: 'id',
    searchCols: ['contact_code', 'name', 'legal_name', 'country_code', 'gstin', 'iec'],
  },
  items: {
    name: 'items', table: 'item', perm: 'party', idKind: 'surrogate', extPrefix: 'ITM',
    columns: ['item_code', 'description', 'statutory_description', 'stock_uom', 'valuation_method', 'item_group', 'net_weight_kg', 'gross_weight_kg', 'is_capital_good'],
    required: ['item_code', 'description', 'stock_uom'], orderBy: 'id',
  },
  'charge-types': {
    name: 'charge-types', table: 'charge_type', perm: 'costsheet', idKind: 'surrogate', extPrefix: 'CHG',
    columns: ['code', 'name', 'category', 'treatment', 'allocation_basis', 'tolerance_pct', 'credit_eligible'],
    required: ['code', 'name', 'category', 'treatment'], orderBy: 'id',
  },
  accounts: {
    name: 'accounts', table: 'gl_account', perm: 'account', idKind: { natural: 'code' },
    columns: ['code', 'name', 'account_class', 'account_type', 'account_group', 'schedule_iii_group', 'cash_flow_class', 'subledger', 'is_monetary', 'manual_posting_allowed', 'recon_frequency', 'currency'],
    required: ['code', 'name', 'account_class', 'account_group'], defaults: { valid_from: '2020-04-01' }, orderBy: 'code',
    searchCols: ['code', 'name', 'account_class', 'account_group', 'account_type'],
  },
  'voucher-types': {
    name: 'voucher-types', table: 'voucher_type', perm: 'voucher', idKind: { natural: 'code' },
    columns: ['code', 'name', 'document_class', 'statutory_series', 'posts_on', 'reversible', 'approval_matrix', 'print_format', 'retention_years', 'books'],
    required: ['code', 'name', 'document_class'], orderBy: 'id',
  },
  orders: {
    name: 'orders', table: 'trade_order', perm: 'order', idKind: 'surrogate', extPrefix: 'O',
    columns: ['order_no', 'direction', 'order_date', 'party_id', 'currency', 'incoterm', 'named_place', 'transport_mode', 'port_of_loading', 'port_of_discharge', 'payment_term', 'zero_rating_route', 'order_value', 'status'],
    required: ['order_no', 'direction', 'order_date', 'party_id', 'currency', 'incoterm', 'transport_mode', 'port_of_loading', 'port_of_discharge', 'named_place', 'payment_term'],
    defaults: { zero_rating_route: 'NA', status: 'DRAFT' }, orderBy: 'id',
    searchCols: ['order_no', 'direction', 'incoterm', 'port_of_loading', 'port_of_discharge', 'status'],
  },
  shipments: {
    name: 'shipments', table: 'shipment', perm: 'shipment', idKind: 'surrogate', extPrefix: 'S',
    columns: ['shipment_no', 'direction', 'transport_mode', 'party_id', 'carrier', 'vessel', 'voyage', 'transport_doc_no', 'transport_doc_date', 'port_of_loading', 'port_of_discharge', 'incoterm', 'etd', 'atd', 'eta', 'ata', 'stage', 'status', 'currency', 'goods_value'],
    required: ['shipment_no', 'direction', 'transport_mode', 'party_id', 'port_of_loading', 'port_of_discharge', 'incoterm', 'currency'],
    defaults: { stage: 'PLANNED', status: 'OPEN' }, orderBy: 'id',
    searchCols: ['shipment_no', 'carrier', 'vessel', 'voyage', 'transport_doc_no', 'port_of_loading', 'port_of_discharge', 'stage', 'status'],
  },
  licences: {
    name: 'licences', table: 'licence', perm: 'licence', idKind: 'surrogate', extPrefix: 'L',
    columns: ['scheme_id', 'licence_no', 'issued_on', 'issuing_authority', 'import_valid_to', 'export_valid_to', 'status', 'scheme_label', 'obligation_label', 'status_label', 'cif_entitlement', 'duty_saved', 'obligation_type', 'obligation_amount', 'min_value_addition_pct'],
    required: ['scheme_id', 'licence_no', 'issued_on'], defaults: { status: 'ISSUED', obligation_type: 'NONE' }, orderBy: 'id',
  },
  instruments: {
    name: 'instruments', table: 'instrument', perm: 'instrument', idKind: 'surrogate', extPrefix: 'I',
    columns: ['instrument_no', 'instrument_type', 'governing_rules', 'issuing_bank_name', 'advising_bank_name', 'applicant_name', 'beneficiary_name', 'currency', 'face_value', 'tolerance_pct', 'latest_shipment_date', 'expiry_date', 'presentation_days', 'payment_terms', 'status', 'type_label', 'status_label'],
    required: ['instrument_no', 'instrument_type', 'currency', 'face_value'], defaults: { status: 'DRAFT' }, orderBy: 'id',
  },
  reconciliations: {
    name: 'reconciliations', table: 'reconciliation', perm: 'reconciliation', idKind: { natural: 'code' },
    columns: ['code', 'name', 'source_a', 'source_b', 'frequency', 'owner_role', 'as_of', 'matched_count', 'unmatched_a', 'unmatched_b', 'value_at_risk', 'oldest_days', 'status'],
    required: ['code', 'name', 'source_a', 'source_b', 'frequency', 'owner_role'], defaults: { status: 'CLEAN' }, orderBy: 'code',
  },
  tasks: {
    name: 'tasks', table: 'work_task', perm: 'cockpit', idKind: 'surrogate', extPrefix: 'T',
    columns: ['task_kind', 'title', 'detail', 'severity', 'object_type', 'object_id', 'route', 'due_on', 'status'],
    required: ['task_kind', 'title', 'detail', 'object_type', 'route'], defaults: { severity: 'MEDIUM', status: 'OPEN', object_id: 0 }, orderBy: 'id',
  },
  exceptions: {
    name: 'exceptions', table: 'exception_item', perm: 'exception', idKind: 'surrogate', extPrefix: 'E',
    columns: ['rule_id', 'severity', 'exception_type', 'title', 'detail', 'object_type', 'object_id', 'object_ref', 'exposure', 'deadline_on', 'first_seen_on', 'age_days', 'is_open', 'resolution'],
    required: ['rule_id', 'severity', 'exception_type', 'title', 'detail', 'object_type'], defaults: { object_id: 0, is_open: 1, first_seen_on: '2026-08-04', age_days: 0 }, orderBy: 'id',
  },
  'cost-sheets': {
    name: 'cost-sheets', table: 'cost_sheet', perm: 'costsheet', idKind: { natural: 'cost_sheet_no' },
    columns: ['cost_sheet_no', 'shipment_id', 'direction', 'currency', 'goods_value', 'stock_on_hand_pct', 'status', 'allocation_basis'],
    required: ['cost_sheet_no', 'shipment_id', 'currency'], defaults: { direction: 'IMPORT', status: 'OPEN', allocation_basis: 'VALUE' }, orderBy: 'id',
  },
  entitlements: {
    name: 'entitlements', table: 'entitlement_claim', perm: 'entitlement', idKind: { natural: 'claim_no' },
    columns: ['claim_no', 'scheme_id', 'declaration_no', 'fob_value', 'rate_pct', 'cap_amount', 'computed_amount', 'claimed_amount', 'sanctioned_amount', 'received_amount', 'stage', 'recognition_point', 'scrip_ref'],
    required: ['claim_no', 'scheme_id', 'fob_value'], defaults: { stage: 'ACCRUED', recognition_point: 'AT_SANCTION' }, orderBy: 'id',
  },
  'number-series': {
    name: 'number-series', table: 'number_series', perm: 'voucher', idKind: 'surrogate', extPrefix: 'NS',
    columns: ['voucher_type_id', 'fiscal_year', 'prefix', 'suffix', 'width', 'next_no', 'is_gapless', 'is_active'],
    required: ['voucher_type_id', 'fiscal_year', 'prefix'], defaults: { suffix: '', width: 5, next_no: 1, is_gapless: 1, is_active: 1 }, orderBy: 'id',
  },
  // ---- operational registers (migration 009) --------------------------------
  indents: {
    name: 'indents', table: 'indent', perm: 'order', idKind: 'surrogate', extPrefix: 'IND',
    columns: ['indent_no', 'indent_date', 'item_desc', 'qty', 'uom', 'required_by', 'cost_centre', 'precheck_status', 'status'],
    required: ['indent_no', 'indent_date', 'item_desc'], defaults: { qty: 0, uom: 'PCS', precheck_status: 'PENDING', status: 'DRAFT' }, orderBy: 'id',
    searchCols: ['indent_no', 'item_desc', 'cost_centre', 'status'],
  },
  receipts: {
    name: 'receipts', table: 'goods_receipt', perm: 'shipment', idKind: 'surrogate', extPrefix: 'GRN',
    columns: ['grn_no', 'grn_date', 'shipment_no', 'supplier', 'warehouse', 'line_count', 'value', 'currency', 'status'],
    required: ['grn_no', 'grn_date'], defaults: { line_count: 0, value: 0, currency: 'INR', status: 'DRAFT' }, orderBy: 'id',
    searchCols: ['grn_no', 'shipment_no', 'supplier', 'warehouse', 'status'],
  },
  'document-sets': {
    name: 'document-sets', table: 'document_set', perm: 'shipment', idKind: 'surrogate', extPrefix: 'DOC',
    columns: ['set_no', 'shipment_no', 'doc_type', 'party', 'received_on', 'completeness_pct', 'status'],
    required: ['set_no'], defaults: { completeness_pct: 0, status: 'OPEN' }, orderBy: 'id',
    searchCols: ['set_no', 'shipment_no', 'doc_type', 'party', 'status'],
  },
  bookings: {
    name: 'bookings', table: 'booking', perm: 'shipment', idKind: 'surrogate', extPrefix: 'BK',
    columns: ['booking_no', 'booking_date', 'carrier', 'transport_mode', 'origin_port', 'dest_port', 'container_type', 'containers', 'status'],
    required: ['booking_no', 'booking_date'], defaults: { transport_mode: 'SEA', containers: 0, status: 'REQUESTED' }, orderBy: 'id',
    searchCols: ['booking_no', 'carrier', 'origin_port', 'dest_port', 'status'],
  },
  containers: {
    name: 'containers', table: 'freight_container', perm: 'shipment', idKind: 'surrogate', extPrefix: 'CNT',
    columns: ['container_no', 'size_type', 'shipment_no', 'seal_no', 'gross_weight_kg', 'free_time_days', 'demurrage', 'status'],
    required: ['container_no'], defaults: { gross_weight_kg: 0, free_time_days: 0, demurrage: 0, status: 'IN_TRANSIT' }, orderBy: 'id',
    searchCols: ['container_no', 'shipment_no', 'seal_no', 'size_type', 'status'],
  },
  enquiries: {
    name: 'enquiries', table: 'enquiry', perm: 'order', idKind: 'surrogate', extPrefix: 'ENQ',
    columns: ['enquiry_no', 'enquiry_date', 'customer', 'country_code', 'item_desc', 'qty', 'target_price', 'currency', 'status'],
    required: ['enquiry_no', 'enquiry_date'], defaults: { qty: 0, target_price: 0, currency: 'USD', status: 'OPEN' }, orderBy: 'id',
    searchCols: ['enquiry_no', 'customer', 'item_desc', 'country_code', 'status'],
  },
  'export-invoices': {
    name: 'export-invoices', table: 'export_invoice', perm: 'order', idKind: 'surrogate', extPrefix: 'EXI',
    columns: ['invoice_no', 'invoice_date', 'customer', 'currency', 'fob_value', 'incoterm', 'shipment_no', 'status'],
    required: ['invoice_no', 'invoice_date'], defaults: { currency: 'USD', fob_value: 0, status: 'DRAFT' }, orderBy: 'id',
    searchCols: ['invoice_no', 'customer', 'shipment_no', 'incoterm', 'status'],
  },
  'provider-invoices': {
    name: 'provider-invoices', table: 'provider_invoice', perm: 'costsheet', idKind: 'surrogate', extPrefix: 'PVI',
    columns: ['invoice_no', 'invoice_date', 'provider', 'service_type', 'currency', 'amount', 'shipment_no', 'status'],
    required: ['invoice_no', 'invoice_date'], defaults: { currency: 'INR', amount: 0, status: 'RECEIVED' }, orderBy: 'id',
    searchCols: ['invoice_no', 'provider', 'service_type', 'shipment_no', 'status'],
  },
  'bank-charges': {
    name: 'bank-charges', table: 'bank_charge', perm: 'instrument', idKind: 'surrogate', extPrefix: 'BCH',
    columns: ['charge_ref', 'charge_date', 'bank', 'instrument_no', 'charge_type', 'currency', 'amount', 'status'],
    required: ['charge_ref', 'charge_date'], defaults: { currency: 'INR', amount: 0, status: 'POSTED' }, orderBy: 'id',
    searchCols: ['charge_ref', 'bank', 'instrument_no', 'charge_type', 'status'],
  },
  'insurance-policies': {
    name: 'insurance-policies', table: 'insurance_policy', perm: 'shipment', idKind: 'surrogate', extPrefix: 'INS',
    columns: ['policy_no', 'insurer', 'cover_type', 'currency', 'sum_insured', 'premium', 'valid_from', 'valid_to', 'status'],
    required: ['policy_no'], defaults: { currency: 'INR', sum_insured: 0, premium: 0, status: 'ACTIVE' }, orderBy: 'id',
    searchCols: ['policy_no', 'insurer', 'cover_type', 'status'],
  },
  // ---- operational registers, batch 2 (migration 010) ----------------------
  'sourcing-quotes': {
    name: 'sourcing-quotes', table: 'sourcing_quote', perm: 'order', idKind: 'surrogate', extPrefix: 'RFQ',
    columns: ['rfq_no', 'rfq_date', 'item_desc', 'supplier', 'country_code', 'currency', 'unit_price', 'lead_time_days', 'landed_estimate', 'status'],
    required: ['rfq_no', 'rfq_date'], defaults: { currency: 'USD', unit_price: 0, lead_time_days: 0, landed_estimate: 0, status: 'OPEN' }, orderBy: 'id',
    searchCols: ['rfq_no', 'item_desc', 'supplier', 'country_code', 'status'],
  },
  'post-clearance': {
    name: 'post-clearance', table: 'post_clearance_case', perm: 'declaration', idKind: 'surrogate', extPrefix: 'PCC',
    columns: ['case_no', 'opened_on', 'declaration_no', 'case_type', 'authority', 'exposure', 'currency', 'due_on', 'status'],
    required: ['case_no', 'opened_on'], defaults: { exposure: 0, currency: 'INR', status: 'OPEN' }, orderBy: 'id',
    searchCols: ['case_no', 'declaration_no', 'case_type', 'authority', 'status'],
  },
  realisations: {
    name: 'realisations', table: 'realisation', perm: 'instrument', idKind: 'surrogate', extPrefix: 'RLS',
    columns: ['realisation_no', 'invoice_no', 'customer', 'currency', 'invoice_value', 'realised_value', 'due_date', 'realised_on', 'edpms_status', 'status'],
    required: ['realisation_no'], defaults: { currency: 'USD', invoice_value: 0, realised_value: 0, status: 'PENDING' }, orderBy: 'id',
    searchCols: ['realisation_no', 'invoice_no', 'customer', 'status', 'edpms_status'],
  },
  stuffing: {
    name: 'stuffing', table: 'stuffing', perm: 'shipment', idKind: 'surrogate', extPrefix: 'STF',
    columns: ['stuffing_no', 'stuffing_date', 'shipment_no', 'container_no', 'location', 'supervisor', 'packages', 'gross_weight_kg', 'status'],
    required: ['stuffing_no', 'stuffing_date'], defaults: { packages: 0, gross_weight_kg: 0, status: 'PLANNED' }, orderBy: 'id',
    searchCols: ['stuffing_no', 'shipment_no', 'container_no', 'location', 'status'],
  },
  presentations: {
    name: 'presentations', table: 'presentation', perm: 'instrument', idKind: 'surrogate', extPrefix: 'PRS',
    columns: ['presentation_no', 'presented_on', 'instrument_no', 'bank', 'currency', 'amount', 'discrepancies', 'deadline', 'status'],
    required: ['presentation_no'], defaults: { currency: 'USD', amount: 0, discrepancies: 0, status: 'DRAFT' }, orderBy: 'id',
    searchCols: ['presentation_no', 'instrument_no', 'bank', 'status'],
  },
  collections: {
    name: 'collections', table: 'collection_bill', perm: 'instrument', idKind: 'surrogate', extPrefix: 'COL',
    columns: ['bill_no', 'bill_date', 'drawee', 'bank', 'collection_type', 'currency', 'amount', 'tenor_days', 'maturity_on', 'status'],
    required: ['bill_no', 'bill_date'], defaults: { currency: 'USD', amount: 0, tenor_days: 0, status: 'LODGED' }, orderBy: 'id',
    searchCols: ['bill_no', 'drawee', 'bank', 'collection_type', 'status'],
  },
  exposures: {
    name: 'exposures', table: 'fx_position', perm: 'instrument', idKind: 'surrogate', extPrefix: 'FX',
    columns: ['ref_no', 'as_of', 'currency', 'exposure_type', 'gross_exposure', 'hedged_amount', 'forward_rate', 'maturity_on', 'status'],
    required: ['ref_no', 'as_of'], defaults: { currency: 'USD', gross_exposure: 0, hedged_amount: 0, forward_rate: 0, status: 'OPEN' }, orderBy: 'id',
    searchCols: ['ref_no', 'currency', 'exposure_type', 'status'],
  },
  bonded: {
    name: 'bonded', table: 'bonded_entry', perm: 'declaration', idKind: 'surrogate', extPrefix: 'BND',
    columns: ['entry_no', 'entry_date', 'warehouse_code', 'goods_desc', 'bond_type', 'duty_deferred', 'currency', 'rewarehouse_by', 'status'],
    required: ['entry_no', 'entry_date'], defaults: { duty_deferred: 0, currency: 'INR', status: 'IN_BOND' }, orderBy: 'id',
    searchCols: ['entry_no', 'warehouse_code', 'goods_desc', 'bond_type', 'status'],
  },
  'regulatory-changes': {
    name: 'regulatory-changes', table: 'regulatory_change', perm: 'exception', idKind: 'surrogate', extPrefix: 'REG',
    columns: ['ref_no', 'published_on', 'authority', 'title', 'category', 'effective_from', 'impact', 'owner_role', 'status'],
    required: ['ref_no', 'title'], defaults: { status: 'NEW' }, orderBy: 'id',
    searchCols: ['ref_no', 'authority', 'title', 'category', 'status'],
  },
  credentials: {
    name: 'credentials', table: 'credential', perm: 'exception', idKind: 'surrogate', extPrefix: 'CRD',
    columns: ['credential_no', 'credential_type', 'holder', 'authority', 'issued_on', 'valid_to', 'status'],
    required: ['credential_no'], defaults: { status: 'ACTIVE' }, orderBy: 'id',
    searchCols: ['credential_no', 'credential_type', 'holder', 'authority', 'status'],
  },
  filings: {
    name: 'filings', table: 'filing', perm: 'exception', idKind: 'surrogate', extPrefix: 'FIL',
    columns: ['filing_ref', 'filing_name', 'authority', 'frequency', 'period', 'due_on', 'preparer', 'approver', 'status'],
    required: ['filing_ref', 'filing_name'], defaults: { status: 'NOT_STARTED' }, orderBy: 'id',
    searchCols: ['filing_ref', 'filing_name', 'authority', 'period', 'status'],
  },
  'origin-determinations': {
    name: 'origin-determinations', table: 'origin_determination', perm: 'declaration', idKind: 'surrogate', extPrefix: 'ORG',
    columns: ['ref_no', 'item_desc', 'hs_code', 'agreement', 'origin_country', 'rule_applied', 'value_addition_pct', 'coo_ref', 'status'],
    required: ['ref_no'], defaults: { value_addition_pct: 0, status: 'DRAFT' }, orderBy: 'id',
    searchCols: ['ref_no', 'item_desc', 'hs_code', 'agreement', 'origin_country', 'status'],
  },
  checklists: {
    name: 'checklists', table: 'checklist', perm: 'party', idKind: 'surrogate', extPrefix: 'CHK',
    columns: ['code', 'name', 'applies_to', 'direction', 'item_count', 'mandatory_count', 'status'],
    required: ['code', 'name'], defaults: { item_count: 0, mandatory_count: 0, status: 'ACTIVE' }, orderBy: 'id',
    searchCols: ['code', 'name', 'applies_to', 'direction', 'status'],
  },
  'compliance-packs': {
    name: 'compliance-packs', table: 'compliance_pack', perm: 'party', idKind: 'surrogate', extPrefix: 'PCK',
    columns: ['code', 'name', 'jurisdiction', 'version', 'rule_count', 'effective_from', 'status'],
    required: ['code', 'name'], defaults: { rule_count: 0, status: 'ACTIVE' }, orderBy: 'id',
    searchCols: ['code', 'name', 'jurisdiction', 'version', 'status'],
  },
  declarations: {
    name: 'declarations', table: 'declaration', perm: 'declaration', idKind: 'partitioned', extPrefix: 'D', periodDate: 'declaration_date',
    columns: ['declaration_no', 'declaration_type', 'type_label', 'direction', 'jurisdiction', 'shipment_id', 'party_id', 'port_code', 'filing_channel', 'declaration_date', 'status', 'status_label', 'currency', 'statutory_fx_rate', 'assessable_value', 'duty_total'],
    required: ['declaration_no', 'declaration_type', 'direction', 'party_id', 'port_code', 'declaration_date', 'currency'],
    defaults: { jurisdiction: 'IN', filing_channel: 'ICEGATE', status: 'DRAFT', statutory_fx_rate: 1 }, orderBy: 'id',
    searchCols: ['declaration_no', 'declaration_type', 'direction', 'port_code', 'filing_channel', 'status'],
  },
};

/** Child collections editable under a parent (nested line editing). */
interface Child {
  table: string; parentCol: string; parentRes: string; perm: string;
  columns: string[]; seqCol?: string; computed?: (row: any) => Record<string, any>;
  defaults?: Record<string, any>; orderBy?: string;
}
export const CHILDREN: Record<string, Child> = {
  'orders/lines': {
    table: 'trade_order_line', parentCol: 'order_id', parentRes: 'orders', perm: 'order', seqCol: 'line_no', orderBy: 'line_no',
    columns: ['item_code', 'description', 'hs_code', 'qty', 'uom', 'unit_price', 'currency', 'origin_country', 'net_weight_kg'],
    defaults: { uom: 'PCS', currency: 'USD', qty: 0, unit_price: 0, net_weight_kg: 0 },
    computed: (r) => ({ line_value: Math.round((Number(r.qty) || 0) * (Number(r.unit_price) || 0) * 100) / 100 }),
  },
  'cost-sheets/lines': {
    table: 'cost_line', parentCol: 'cost_sheet_id', parentRes: 'cost-sheets', perm: 'costsheet', seqCol: 'line_no', orderBy: 'line_no',
    columns: ['charge_type_id', 'provider_id', 'basis', 'treatment', 'currency', 'fx_rate', 'estimate', 'accrued', 'actual', 'invoice_ref', 'tolerance_pct', 'status_label'],
    defaults: { basis: 'VALUE', treatment: 'CAPITALISE', currency: 'INR', fx_rate: 1, estimate: 0, accrued: 0, tolerance_pct: 10 },
    computed: (r) => ({ estimate_fc: Number(r.estimate) || 0, status: r.actual != null && r.actual !== '' ? 'MATCHED' : Number(r.accrued) > 0 ? 'ACCRUED' : 'ESTIMATED' }),
  },
  'reconciliations/items': {
    table: 'reconciliation_item', parentCol: 'reconciliation_id', parentRes: 'reconciliations', perm: 'reconciliation', orderBy: 'id',
    columns: ['item_ref', 'item_date', 'description', 'amount_a', 'amount_b', 'difference', 'cause', 'age_days', 'status'],
    defaults: { difference: 0, age_days: 0, status: 'UNMATCHED', item_date: '2026-07-31' },
  },
  'licences/blocks': {
    table: 'licence_block', parentCol: 'licence_id', parentRes: 'licences', perm: 'licence', seqCol: 'block_no', orderBy: 'block_no',
    columns: ['label', 'share_pct', 'due_on', 'obligation_amount', 'fulfilled_amount', 'status'],
    defaults: { share_pct: 0, obligation_amount: 0, fulfilled_amount: 0, status: 'OPEN', due_on: '2027-03-31' },
  },
  'instruments/requirements': {
    table: 'instrument_doc_requirement', parentCol: 'instrument_id', parentRes: 'instruments', perm: 'instrument', seqCol: 'seq', orderBy: 'seq',
    columns: ['doc_type', 'originals', 'copies', 'issuer', 'required_wording', 'is_held'],
    defaults: { originals: 1, copies: 0, is_held: 0 },
  },
};

function resolveId(res: Resource, idStr: string): { where: string; params: any[] } {
  if (res.idKind === 'surrogate' || res.idKind === 'partitioned') {
    const m = String(idStr).match(/(\d+)\s*$/);
    if (!m) throw new HttpError(400, `Bad id ${idStr}`);
    return { where: 'id = ?', params: [Number(m[1])] };
  }
  return { where: `\`${res.idKind.natural}\` = ?`, params: [idStr] };
}

function pickColumns(res: Resource, body: any): Record<string, any> {
  const out: Record<string, any> = {};
  for (const col of res.columns) if (body[col] !== undefined) out[col] = body[col] === '' ? null : body[col];
  return out;
}

export const crudRouter = Router();

// list (raw rows, entity-scoped) — supports server-side pagination + search.
//   ?limit=&offset=  → page window; when offset/paged is present the response
//                      also carries { page: { total, limit, offset } }.
//   ?q=              → LIKE match across the resource's searchCols (if declared).
crudRouter.get('/:resource', (req: AuthedRequest, res, next) => {
  const r = RESOURCES[req.params.resource];
  if (!r) return next(new HttpError(404, `Unknown resource ${req.params.resource}`));
  return requirePermission(`${r.perm}:read`)(req, res, () => h(async () => {
    const limit = Math.min(Math.max(Number(req.query.limit) || 100, 1), 500);
    const offset = Math.max(Number(req.query.offset) || 0, 0);
    const paged = req.query.offset !== undefined || req.query.paged !== undefined;

    // build the shared WHERE (entity scope + optional search)
    const clauses = ['entity_id = ?'];
    const params: any[] = [req.entityId];
    const qStr = req.query.q ? String(req.query.q).trim() : '';
    if (qStr && r.searchCols?.length) {
      const like = `%${qStr}%`;
      clauses.push(`(${r.searchCols.map((c) => `\`${c}\` LIKE ?`).join(' OR ')})`);
      for (const _ of r.searchCols) params.push(like);
    }
    const where = clauses.join(' AND ');

    const rows = await q(
      `SELECT * FROM \`${r.table}\` WHERE ${where} ORDER BY ${r.orderBy ?? 'id'} LIMIT ? OFFSET ?`,
      [...params, limit, offset],
    );
    if (!paged) { res.json({ data: rows, asOf: new Date().toISOString() }); return; }

    const totalRow = await q1<{ n: number }>(`SELECT COUNT(*) AS n FROM \`${r.table}\` WHERE ${where}`, params);
    res.json({ data: rows, page: { total: Number(totalRow?.n ?? 0), limit, offset }, asOf: new Date().toISOString() });
  })(req, res, next));
});

// get one
crudRouter.get('/:resource/:id', (req: AuthedRequest, res, next) => {
  const r = RESOURCES[req.params.resource];
  if (!r) return next(new HttpError(404, `Unknown resource ${req.params.resource}`));
  return requirePermission(`${r.perm}:read`)(req, res, () => h(async () => {
    const { where, params } = resolveId(r, req.params.id);
    const row = await q1(`SELECT * FROM \`${r.table}\` WHERE entity_id = ? AND ${where}`, [req.entityId, ...params]);
    if (!row) throw new HttpError(404, `${r.name} not found`);
    res.json({ data: row, asOf: new Date().toISOString() });
  })(req, res, next));
});

// create
crudRouter.post('/:resource', (req: AuthedRequest, res, next) => {
  const r = RESOURCES[req.params.resource];
  if (!r) return next(new HttpError(404, `Unknown resource ${req.params.resource}`));
  return requirePermission(`${r.perm}:write`)(req, res, () => h(async () => {
    const cols = { ...(r.defaults ?? {}), ...pickColumns(r, req.body ?? {}) };
    for (const req_ of r.required) if (cols[req_] === undefined || cols[req_] === null || cols[req_] === '') throw new HttpError(422, `${req_} is required`);
    cols.entity_id = req.entityId;
    if (r.idKind === 'partitioned' && r.periodDate) cols.period_key = pk(String(cols[r.periodDate]));
    const keys = Object.keys(cols);
    const info = await exec(`INSERT INTO \`${r.table}\` (${keys.map((k) => `\`${k}\``).join(',')}) VALUES (${keys.map(() => '?').join(',')})`, keys.map((k) => cols[k]));
    const publicId = r.extPrefix ? `${r.extPrefix}-${pad3(info.insertId)}` : (r.idKind === 'surrogate' ? String(info.insertId) : cols[(r.idKind as any).natural]);
    await writeAudit({ ...actor(req), action: 'CREATE', objectType: r.name, objectId: info.insertId, objectRef: publicId });
    res.status(201).json({ data: { id: publicId, insertId: info.insertId }, asOf: new Date().toISOString() });
  })(req, res, next));
});

// update
crudRouter.put('/:resource/:id', (req: AuthedRequest, res, next) => {
  const r = RESOURCES[req.params.resource];
  if (!r) return next(new HttpError(404, `Unknown resource ${req.params.resource}`));
  return requirePermission(`${r.perm}:write`)(req, res, () => h(async () => {
    const cols = pickColumns(r, req.body ?? {});
    if (!Object.keys(cols).length) throw new HttpError(422, 'No writable fields supplied');
    const { where, params } = resolveId(r, req.params.id);
    const set = Object.keys(cols).map((k) => `\`${k}\` = ?`).join(', ');
    const info = await exec(`UPDATE \`${r.table}\` SET ${set} WHERE entity_id = ? AND ${where}`, [...Object.values(cols), req.entityId, ...params]);
    if (info.affectedRows === 0) throw new HttpError(404, `${r.name} not found`);
    await writeAudit({ ...actor(req), action: 'UPDATE', objectType: r.name, objectRef: req.params.id, newValue: Object.keys(cols).join(',') });
    res.json({ data: { updated: info.affectedRows }, asOf: new Date().toISOString() });
  })(req, res, next));
});

// ---- nested child collections --------------------------------------------
async function parentNumericId(res: Resource, entityId: number, idStr: string): Promise<number | null> {
  const { where, params } = resolveId(res, idStr);
  const row = await q1<any>(`SELECT id FROM \`${res.table}\` WHERE entity_id = ? AND ${where}`, [entityId, ...params]);
  return row ? n(row.id) : null;
}

// list children
crudRouter.get('/:resource/:id/:child', (req: AuthedRequest, res, next) => {
  const c = CHILDREN[`${req.params.resource}/${req.params.child}`];
  const parent = RESOURCES[req.params.resource];
  if (!c || !parent) return next(new HttpError(404, 'Unknown child collection'));
  return requirePermission(`${c.perm}:read`)(req, res, () => h(async () => {
    const pid = await parentNumericId(parent, req.entityId!, req.params.id);
    if (pid === null) throw new HttpError(404, 'Parent not found');
    const rows = await q(`SELECT * FROM \`${c.table}\` WHERE \`${c.parentCol}\` = ? ORDER BY ${c.orderBy ?? 'id'}`, [pid]);
    res.json({ data: rows, asOf: new Date().toISOString() });
  })(req, res, next));
});

// replace the whole child collection (edit lines, save)
crudRouter.put('/:resource/:id/:child', (req: AuthedRequest, res, next) => {
  const c = CHILDREN[`${req.params.resource}/${req.params.child}`];
  const parent = RESOURCES[req.params.resource];
  if (!c || !parent) return next(new HttpError(404, 'Unknown child collection'));
  return requirePermission(`${c.perm}:write`)(req, res, () => h(async () => {
    const pid = await parentNumericId(parent, req.entityId!, req.params.id);
    if (pid === null) throw new HttpError(404, 'Parent not found');
    const rows: any[] = Array.isArray(req.body?.rows) ? req.body.rows : [];
    return withTx(async (tx) => {
      await tx.exec(`DELETE FROM \`${c.table}\` WHERE \`${c.parentCol}\` = ?`, [pid]);
      let seq = 1;
      for (const raw of rows) {
        const cols: Record<string, any> = { ...(c.defaults ?? {}) };
        for (const col of c.columns) if (raw[col] !== undefined && raw[col] !== '' && raw[col] !== null) cols[col] = raw[col];
        Object.assign(cols, c.computed ? c.computed({ ...cols, ...raw }) : {});
        cols[c.parentCol] = pid;
        cols.entity_id = req.entityId;
        if (c.seqCol) cols[c.seqCol] = raw[c.seqCol] ?? seq;
        const keys = Object.keys(cols);
        await tx.exec(`INSERT INTO \`${c.table}\` (${keys.map((k) => `\`${k}\``).join(',')}) VALUES (${keys.map(() => '?').join(',')})`, keys.map((k) => cols[k]));
        seq += 1;
      }
      await writeAudit({ ...actor(req), action: 'EDIT_LINES', objectType: `${req.params.resource}/${req.params.child}`, objectRef: req.params.id, newValue: String(rows.length)+' rows' });
      res.json({ data: { replaced: rows.length }, asOf: new Date().toISOString() });
    });
  })(req, res, next));
});

// delete
crudRouter.delete('/:resource/:id', (req: AuthedRequest, res, next) => {
  const r = RESOURCES[req.params.resource];
  if (!r) return next(new HttpError(404, `Unknown resource ${req.params.resource}`));
  return requirePermission(`${r.perm}:write`)(req, res, () => h(async () => {
    const { where, params } = resolveId(r, req.params.id);
    let info;
    try {
      info = await exec(`DELETE FROM \`${r.table}\` WHERE entity_id = ? AND ${where}`, [req.entityId, ...params]);
    } catch (e: any) {
      if (e.code === 'ER_ROW_IS_REFERENCED_2' || e.code === 'ER_ROW_IS_REFERENCED') {
        throw new HttpError(409, `Cannot delete: other records reference this ${r.name.replace(/s$/, '')}.`, 'IN_USE');
      }
      throw e;
    }
    if (info.affectedRows === 0) throw new HttpError(404, `${r.name} not found`);
    await writeAudit({ ...actor(req), action: 'DELETE', objectType: r.name, objectRef: req.params.id });
    res.json({ data: { deleted: info.affectedRows }, asOf: new Date().toISOString() });
  })(req, res, next));
});
