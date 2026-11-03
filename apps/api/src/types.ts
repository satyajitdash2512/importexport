/** Shared domain types. Mirrors the object model in RD section 3.3. */

export type Severity = 'critical' | 'high' | 'medium' | 'info';
export type Priority = 'M' | 'S' | 'C';

export interface Party {
  id: string; name: string; legalName: string; country: string; roles: string[];
  gstin?: string; pan?: string; iec?: string; ledgerGroup?: string; ledgerCode?: string;
  screeningStatus: 'clear' | 'review' | 'match'; screenedOn: string;
  currency: string; incoterm?: string; paymentTerm?: string; relatedParty: boolean;
  bankVerified: boolean; contactCode: string;
}

export interface OrderLine {
  id: string; itemCode: string; description: string; hsCode: string; qty: number; uom: string;
  unitPrice: number; currency: string; originCountry: string; licenceRef?: string;
  preferenceIntent?: string; schemeIntent?: string[]; estLandedCost?: number; netWeightKg: number;
}

export interface TradeOrder {
  id: string; type: 'import' | 'export'; number: string; date: string; partyId: string;
  currency: string; incoterm: string; namedPlace: string; mode: 'SEA' | 'AIR' | 'ROAD';
  portOfLoading: string; portOfDischarge: string; paymentTerm: string; instrumentRef?: string;
  shipmentWindowFrom: string; shipmentWindowTo: string; status: string; value: number;
  lines: OrderLine[]; zeroRatingRoute?: 'LUT' | 'IGST';
}

export interface Milestone { key: string; label: string; planned?: string; revised?: string; actual?: string }

export interface Container {
  number: string; type: string; sealNumber: string; tareKg: number; grossKg: number;
  freeFrom: string; freeDays: number; daysUsed: number; projectedCharge: number;
}

export interface Shipment {
  id: string; number: string; direction: 'import' | 'export'; mode: 'SEA' | 'AIR' | 'ROAD';
  orderIds: string[]; partyId: string; carrier: string; vessel?: string; voyage?: string;
  blNumber?: string; blDate?: string; portOfLoading: string; portOfDischarge: string;
  incoterm: string; etd?: string; atd?: string; eta?: string; ata?: string;
  stage: string; status: string; value: number; currency: string;
  containers: Container[]; milestones: Milestone[]; declarationIds: string[];
  docsRequired: number; docsReceived: number; exceptions: ExceptionItem[];
  forwarder: string; broker: string; grossKg: number; netKg: number;
}

export interface ExceptionItem {
  id: string; severity: Severity; type: string; title: string; detail: string;
  objectType: string; objectId: string; exposure?: number; deadline?: string;
  ageDays: number; owner: string; ruleId: string; open: boolean;
}

export interface Levy {
  code: string; name: string; basis: string; rate: number; base: number; amount: number;
  rateSource: string; recoverable: boolean; exemptionRef?: string;
}

export interface DeclarationLine {
  id: string; lineNo: number; itemCode: string; description: string; hsCode: string;
  qty: number; statutoryUom: string; stockUom: string; conversion: number;
  invoiceValueFc: number; currency: string; freightFc: number; insuranceFc: number;
  originCountry: string; preferenceAgreement?: string; preferenceProofRef?: string;
  licenceRef?: string; assessableValue: number; levies: Levy[]; dutySaved: number;
  dutyForegoneBlocked?: number; netWeightKg: number;
}

export interface Declaration {
  id: string; number: string; type: string; direction: 'import' | 'export';
  shipmentId: string; partyId: string; portCode: string; filingChannel: string;
  authorityRef?: string; filedOn?: string; status: string; statutoryFxRate: number;
  currency: string; assessableValue: number; dutyTotal: number; dutyRecoverable: number;
  dutyInventoriable: number; assessedDuty?: number; paidOn?: string; clearedOn?: string;
  lines: DeclarationLine[]; validations: ValidationFinding[]; provisional: boolean;
  entitlements?: EntitlementClaim[]; leoRef?: string; egmMatched?: boolean;
}

export interface ValidationFinding {
  id: string; severity: 'error' | 'warning'; field: string; lineNo?: number;
  rule: string; message: string; remedy: string;
}

export interface CostLine {
  id: string; chargeCode: string; chargeName: string; category: string; providerId?: string;
  providerName?: string; basis: string; estimate: number; accrued: number; actual?: number;
  invoiceRef?: string; treatment: 'capitalise' | 'expense' | 'recoverable'; status: string;
  currency: string; fxRate: number; tolerancePct: number;
}

export interface CostSheet {
  id: string; shipmentId: string; status: string; lines: CostLine[];
  goodsValue: number; stockOnHandPct: number;
}

export interface Licence {
  id: string; scheme: string; number: string; issuedOn: string; importValidTo: string;
  exportValidTo: string; status: string; dutySaved: number; obligationAmount: number;
  obligationType: string; blocks: { label: string; sharePct: number; dueOn: string; fulfilled: number }[];
  averageObligation?: number; averageMaintained?: boolean; utilisation: LedgerEntry[];
  fulfilment: LedgerEntry[]; conditions: { name: string; satisfied: boolean; detail: string }[];
  bondRef?: string; bgWaived?: boolean; minValueAddition?: number;
}

export interface LedgerEntry {
  id: string; date: string; ref: string; description: string; qty?: number; value: number;
  balance?: number; evidenceComplete?: boolean;
}

/* ---------------- accounting ---------------- */

export interface Account {
  code: string; name: string; class: 'asset' | 'liability' | 'equity' | 'income' | 'expense';
  type: 'ordinary' | 'control' | 'clearing' | 'memorandum';
  group: string; scheduleIIIGroup: string; cashFlow: 'operating' | 'investing' | 'financing' | 'none';
  subledger?: string; monetary: boolean; manualPostingAllowed: boolean;
  mandatoryDimensions: string[]; reconFrequency?: string; currency?: string;
  openingDr: number; openingCr: number; periodDr: number; periodCr: number;
}

export interface PostingLine {
  id: string; accountCode: string; accountName: string; drCr: 'Dr' | 'Cr';
  amountTxn: number; amountFunc: number; currency: string; fxRate: number; rateType: string;
  dimensions: Record<string, string>; taxCode?: string; subledgerKey?: string;
  ruleBranch?: string;
}

export interface Voucher {
  id: string; voucherType: string; voucherTypeName: string; number: string; date: string;
  book: string; narration: string; status: 'parked' | 'pendingApproval' | 'posted' | 'reversed' | 'cancelled';
  sourceType?: string; sourceId?: string; postingRule: string; postingRuleVersion: string;
  preparedBy: string; approvedBy?: string; postedAt?: string;
  lines: PostingLine[]; evidence: EvidenceItem[]; reversalOf?: string; reversedBy?: string;
  totalDr: number; totalCr: number; currency: string;
}

export interface EvidenceItem {
  id: string; docType: string; name: string; issuer?: string; ref?: string; date?: string;
  mandatory: boolean; attached: boolean; version: number; sizeKb?: number;
}

export interface VoucherType {
  code: string; name: string; documentClass: string; statutorySeries: boolean;
  postsOn: 'save' | 'approval'; reversible: boolean; requiredEvidence: string[];
  approvalMatrix: string; printFormat: string; retentionYears: number; books: string[];
}

export interface CloseTask {
  id: string; day: string; step: string; area: string; owner: string;
  status: 'complete' | 'inProgress' | 'blocked' | 'notStarted'; mandatory: boolean;
  blockingCount: number; blockingDetail?: string; evidence?: string; signedOffBy?: string;
}

export interface ReconciliationSummary {
  id: string; name: string; sourceA: string; sourceB: string; frequency: string;
  owner: string; asOf: string; matched: number; unmatchedA: number; unmatchedB: number;
  valueAtRisk: number; oldestDays: number; status: 'clean' | 'exceptions' | 'critical';
  items: ReconItem[];
}

export interface ReconItem {
  id: string; ref: string; date: string; description: string; amountA?: number;
  amountB?: number; difference: number; cause: string; ageDays: number;
  limitationDate?: string; status: 'unmatched' | 'matchedManual' | 'disputed';
}

export interface EntitlementClaim {
  id: string; scheme: string; declarationId: string; declarationNumber: string;
  fobValue: number; ratePct: number; cap?: number; computed: number; claimed: number;
  sanctioned?: number; received?: number; scripRef?: string; stage: string;
  recognitionPoint: string; recognised: boolean; filedOn?: string; shortfallCause?: string;
}

export interface Instrument {
  id: string; number: string; type: string; governingRules: string; issuingBank: string;
  advisingBank?: string; applicant: string; beneficiary: string; currency: string;
  value: number; tolerancePct: number; latestShipmentDate: string; expiryDate: string;
  presentationDays: number; paymentTerms: string; status: string; drawnValue: number;
  availableValue: number; charges: number; discrepancies: Discrepancy[];
  documentRequirements: { doc: string; originals: number; copies: number; issuer: string; wording?: string; held: boolean }[];
}

export interface Discrepancy { id: string; code: string; description: string; disposition?: string; outcome?: string }

export interface TaskItem {
  id: string; title: string; detail: string; severity: Severity; objectType: string;
  objectId: string; route: string; dueOn?: string; owner: string; kind: string;
}

export interface KpiTile { label: string; value: string; sub?: string; severity?: Severity; route?: string }
