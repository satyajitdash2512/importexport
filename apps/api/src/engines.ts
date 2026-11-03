import type { CostLine, DeclarationLine, Levy, Licence, PostingLine } from './types.js';

/* ============================================================================
 *  DUTY ENGINE  —  RD Section 4.3 / HBIE-FIN-001..010
 *  Declarative levy cascade. Each levy's base is an expression over the
 *  assessable value and previously computed levies, so a new cess is content.
 * ========================================================================== */

export interface LevyDefinition {
  code: string; name: string; calcType: 'advalorem' | 'specific' | 'compound';
  ratePct?: number; ratePerUnit?: number; baseExpr: string; recoverable: boolean;
  effectiveFrom: string; effectiveTo?: string; roundTo: number;
}

/** India reference pack — illustrative cascade, effective-dated content. */
export const LEVY_CASCADE_IN: LevyDefinition[] = [
  { code: 'BCD', name: 'Basic customs duty', calcType: 'advalorem', ratePct: 7.5, baseExpr: 'AV', recoverable: false, effectiveFrom: '2026-04-01', roundTo: 2 },
  { code: 'SWS', name: 'Social welfare surcharge', calcType: 'advalorem', ratePct: 10, baseExpr: 'BCD', recoverable: false, effectiveFrom: '2026-04-01', roundTo: 2 },
  { code: 'AIDC', name: 'Agriculture infrastructure & development cess', calcType: 'advalorem', ratePct: 0, baseExpr: 'AV', recoverable: false, effectiveFrom: '2026-04-01', roundTo: 2 },
  { code: 'ADD', name: 'Anti-dumping duty', calcType: 'specific', ratePerUnit: 0, baseExpr: 'QTY', recoverable: false, effectiveFrom: '2026-04-01', roundTo: 2 },
  { code: 'IGST', name: 'Integrated tax on import', calcType: 'advalorem', ratePct: 18, baseExpr: 'AV+BCD+SWS+AIDC+ADD', recoverable: true, effectiveFrom: '2026-04-01', roundTo: 2 },
  { code: 'CESS', name: 'Compensation cess', calcType: 'advalorem', ratePct: 0, baseExpr: 'AV+BCD+SWS', recoverable: true, effectiveFrom: '2026-04-01', roundTo: 2 },
];

/** Preferential rate table: agreement + HS -> BCD rate. Effective dated content. */
export const PREFERENCE_RATES: Record<string, Record<string, number>> = {
  AIFTA: { '84821010': 0, '84821020': 0, '85043100': 2.5 },
  CEPA: { '84821010': 2.5 },
  CETA: { '22083011': 75 },
};

export interface DutyComputationInput {
  assessableValue: number; qty: number; hsCode: string;
  preferenceAgreement?: string; hasPreferenceProof?: boolean;
  exemptionRatePct?: number; asOf?: string;
}

export interface DutyTraceStep {
  code: string; name: string; baseExpr: string; base: number; rateLabel: string;
  amount: number; rateSource: string; recoverable: boolean;
}

export interface DutyComputationResult {
  levies: Levy[]; trace: DutyTraceStep[]; total: number; recoverable: number;
  inventoriable: number; dutySaved: number; dutyForegoneBlocked: number;
  scheduleRateApplied: number; appliedRateBasis: string; ruleVersion: string;
}

function round(v: number, dp: number) { const f = Math.pow(10, dp); return Math.round(v * f) / f; }

function evalBase(expr: string, av: number, qty: number, computed: Record<string, number>): number {
  if (expr === 'QTY') return qty;
  return expr.split('+').reduce((sum, token) => {
    const t = token.trim();
    if (t === 'AV') return sum + av;
    return sum + (computed[t] ?? 0);
  }, 0);
}

export function computeDuty(input: DutyComputationInput): DutyComputationResult {
  const { assessableValue: av, qty, hsCode } = input;
  const computed: Record<string, number> = {};
  const levies: Levy[] = [];
  const trace: DutyTraceStep[] = [];

  // ---- rate resolution by precedence: preference > exemption > schedule -----
  const scheduleBcd = LEVY_CASCADE_IN.find((l) => l.code === 'BCD')!.ratePct ?? 0;
  let bcdRate = scheduleBcd;
  let basis = 'Tariff schedule rate';
  let blocked = 0;

  const prefRate = input.preferenceAgreement
    ? PREFERENCE_RATES[input.preferenceAgreement]?.[hsCode]
    : undefined;

  if (prefRate !== undefined && input.hasPreferenceProof) {
    bcdRate = prefRate;
    basis = `Preferential rate — ${input.preferenceAgreement}`;
  } else if (prefRate !== undefined && !input.hasPreferenceProof) {
    // eligible but blocked for want of proof: quantify the loss (HBIE-UIX-033)
    basis = 'Tariff schedule rate — preference blocked, origin proof not on file';
  } else if (input.exemptionRatePct !== undefined) {
    bcdRate = input.exemptionRatePct;
    basis = 'Exemption notification rate';
  }

  for (const def of LEVY_CASCADE_IN) {
    const base = evalBase(def.baseExpr, av, qty, computed);
    const rate = def.code === 'BCD' ? bcdRate : def.ratePct ?? 0;
    let amount = 0;
    let rateLabel = '';
    if (def.calcType === 'advalorem') { amount = round(base * (rate / 100), def.roundTo); rateLabel = `${rate}%`; }
    else if (def.calcType === 'specific') { amount = round(base * (def.ratePerUnit ?? 0), def.roundTo); rateLabel = `${def.ratePerUnit ?? 0}/unit`; }
    computed[def.code] = amount;
    if (amount !== 0 || ['BCD', 'SWS', 'IGST'].includes(def.code)) {
      levies.push({
        code: def.code, name: def.name, basis: def.baseExpr, rate, base,
        amount, rateSource: def.code === 'BCD' ? basis : 'Tariff schedule', recoverable: def.recoverable,
      });
      trace.push({
        code: def.code, name: def.name, baseExpr: def.baseExpr, base, rateLabel,
        amount, rateSource: def.code === 'BCD' ? basis : 'Tariff schedule', recoverable: def.recoverable,
      });
    }
  }

  // duty that would have been saved had the preference been claimable
  if (prefRate !== undefined && !input.hasPreferenceProof) {
    const savedBcd = round(av * ((scheduleBcd - prefRate) / 100), 2);
    const savedSws = round(savedBcd * 0.10, 2);
    blocked = round(savedBcd + savedSws, 2);
  }

  const total = round(levies.reduce((s, l) => s + l.amount, 0), 2);
  const recoverable = round(levies.filter((l) => l.recoverable).reduce((s, l) => s + l.amount, 0), 2);
  const dutySaved = prefRate !== undefined && input.hasPreferenceProof
    ? round(av * ((scheduleBcd - prefRate) / 100) * 1.1, 2) : 0;

  return {
    levies, trace, total, recoverable, inventoriable: round(total - recoverable, 2),
    dutySaved, dutyForegoneBlocked: blocked, scheduleRateApplied: bcdRate,
    appliedRateBasis: basis, ruleVersion: 'IN-PACK-2026.08 / duty-v3',
  };
}

export function computeDeclarationLine(line: DeclarationLine, fxRate: number): DeclarationLine {
  const av = round((line.invoiceValueFc + line.freightFc + line.insuranceFc) * fxRate, 2);
  const res = computeDuty({
    assessableValue: av, qty: line.qty, hsCode: line.hsCode,
    preferenceAgreement: line.preferenceAgreement,
    hasPreferenceProof: Boolean(line.preferenceProofRef),
  });
  return { ...line, assessableValue: av, levies: res.levies, dutySaved: res.dutySaved, dutyForegoneBlocked: res.dutyForegoneBlocked };
}

/* ============================================================================
 *  LANDED COST ENGINE  —  RD Section 16.2 / HBIE-FIN-030..037
 * ========================================================================== */

export type AllocationBasis = 'value' | 'grossWeight' | 'volume' | 'quantity' | 'chargeableWeight' | 'container' | 'direct' | 'equal';

export interface AllocationTarget { id: string; label: string; value: number; grossWeight: number; volume: number; quantity: number }

export function allocate(amount: number, basis: AllocationBasis, targets: AllocationTarget[]) {
  const measure = (t: AllocationTarget) =>
    basis === 'value' ? t.value :
    basis === 'grossWeight' ? t.grossWeight :
    basis === 'volume' ? t.volume :
    basis === 'quantity' ? t.quantity :
    basis === 'chargeableWeight' ? Math.max(t.grossWeight, t.volume * 167) :
    1;
  const total = targets.reduce((s, t) => s + measure(t), 0) || 1;
  let running = 0;
  return targets.map((t, i) => {
    const share = measure(t) / total;
    const alloc = i === targets.length - 1 ? round(amount - running, 2) : round(amount * share, 2);
    running = round(running + alloc, 2);
    return { id: t.id, label: t.label, measure: measure(t), sharePct: round(share * 100, 1), allocated: alloc };
  });
}

export interface ClosureImpact {
  differential: number; toInventory: number; toCogs: number; stockOnHandPct: number; method: string;
}

export function closureImpact(lines: CostLine[], stockOnHandPct: number, method = 'Weighted average'): ClosureImpact {
  const capitalising = lines.filter((l) => l.treatment === 'capitalise');
  const differential = round(capitalising.reduce((s, l) => s + ((l.actual ?? l.estimate) - l.accrued), 0), 2);
  const toInventory = round(differential * (stockOnHandPct / 100), 2);
  return { differential, toInventory, toCogs: round(differential - toInventory, 2), stockOnHandPct, method };
}

export function costTotals(lines: CostLine[], goodsValue: number) {
  const sum = (f: (l: CostLine) => number) => round(lines.reduce((s, l) => s + f(l), 0), 2);
  const estimate = round(goodsValue + sum((l) => l.estimate), 2);
  const actual = round(goodsValue + sum((l) => l.actual ?? 0), 2);
  const capitalised = round(goodsValue + sum((l) => (l.treatment === 'capitalise' ? (l.actual ?? l.estimate) : 0)), 2);
  const expensed = sum((l) => (l.treatment === 'expense' ? (l.actual ?? l.estimate) : 0));
  const recoverable = sum((l) => (l.treatment === 'recoverable' ? (l.actual ?? l.estimate) : 0));
  const invoicedAll = lines.every((l) => l.actual !== undefined);
  // Variance compares only lines that HAVE an actual. Comparing the estimate to
  // an "actual to date" that excludes uninvoiced elements reads as a favourable
  // variance when it is really a missing invoice — the opposite of the truth.
  const variance = sum((l) => (l.actual === undefined ? 0 : l.actual - l.estimate));
  const uninvoicedAccrual = sum((l) => (l.actual === undefined ? l.accrued : 0));
  return { estimate, actual, variance, uninvoicedAccrual, capitalised, expensed, recoverable, invoicedAll };
}

/* ============================================================================
 *  OBLIGATION PROJECTION  —  RD Section 13.3 / HBIE-CMP-053..054
 * ========================================================================== */

export interface ObligationProjection {
  totalObligation: number; fulfilled: number; pct: number; remaining: number;
  runRatePerYear: number; projectedCompletion: string; deadline: string;
  headroomDays: number; atRisk: boolean; exposureDuty: number; exposureInterest: number;
}

export function projectObligation(lic: Licence, asOf = new Date()): ObligationProjection {
  const fulfilled = lic.fulfilment.reduce((s, e) => s + e.value, 0);
  const remaining = Math.max(lic.obligationAmount - fulfilled, 0);
  const issued = new Date(lic.issuedOn).getTime();
  const years = Math.max((asOf.getTime() - issued) / (365.25 * 864e5), 0.25);
  const runRate = fulfilled / years;
  const yearsNeeded = runRate > 0 ? remaining / runRate : 99;
  const projected = new Date(asOf.getTime() + yearsNeeded * 365.25 * 864e5);
  const firstOpenBlock = lic.blocks.find((b) => b.fulfilled < b.sharePct) ?? lic.blocks[lic.blocks.length - 1];
  const deadline = new Date(firstOpenBlock.dueOn);
  const headroomDays = Math.round((deadline.getTime() - projected.getTime()) / 864e5);
  const noObligation = lic.obligationAmount <= 0;
  const shortfallShare = noObligation ? 0 : remaining / lic.obligationAmount;
  const exposureDuty = round(lic.dutySaved * shortfallShare, 0);
  const exposureInterest = round(exposureDuty * 0.15 * Math.max(years, 1), 0);
  // An authorisation with no obligation (e.g. bonded manufacturing, where duty is
  // merely deferred) is fully covered by definition. Guard the division: a NaN
  // here serialises to null and silently blanks the cockpit figure.
  const pctFulfilled = lic.obligationAmount > 0
    ? round((fulfilled / lic.obligationAmount) * 100, 1)
    : 100;
  return {
    totalObligation: lic.obligationAmount, fulfilled: round(fulfilled, 0),
    pct: pctFulfilled, remaining: round(remaining, 0),
    runRatePerYear: round(runRate, 0), projectedCompletion: projected.toISOString().slice(0, 10),
    deadline: firstOpenBlock.dueOn,
    headroomDays: noObligation ? 0 : headroomDays,
    // No obligation means nothing to fall short of — duty is merely deferred.
    atRisk: noObligation ? false : headroomDays < 90,
    exposureDuty, exposureInterest,
  };
}

/* ============================================================================
 *  POSTING RULE ENGINE  —  RD Section 7 / HBIE-ACC-060..066
 *  Declarative: event -> posting lines. Accounts resolved by determination key.
 * ========================================================================== */

export interface PostingRuleLine {
  drCr: 'Dr' | 'Cr'; accountKey: string; amountKey: string; taxCode?: string;
  condition?: string; treatmentBranch?: string;
}

export interface PostingRule {
  code: string; version: string; effectiveFrom: string; event: string; voucherType: string;
  book: string; description: string; standardRef?: string; lines: PostingRuleLine[];
}

export const ACCOUNT_DETERMINATION: Record<string, { code: string; name: string; subledger?: string }> = {
  INVENTORY: { code: '1401001', name: 'Inventory — raw material (imported)', subledger: 'Inventory' },
  GIT: { code: '1403001', name: 'Goods in transit — imports', subledger: 'Inventory' },
  AP_FOREIGN: { code: '2101001', name: 'Trade payables — foreign suppliers', subledger: 'AP' },
  AP_SERVICE: { code: '2101003', name: 'Trade payables — service providers', subledger: 'AP' },
  AR_EXPORT: { code: '1301001', name: 'Trade receivables — export debtors', subledger: 'AR' },
  BANK: { code: '1201001', name: 'Bank — current account', subledger: 'Bank' },
  BANK_FC: { code: '1201004', name: 'Bank — EEFC foreign currency account', subledger: 'Bank' },
  DUTY_PAYABLE: { code: '2103001', name: 'Customs duty and levies payable' },
  IGST_RECOVERABLE: { code: '1405002', name: 'IGST on imports — credit receivable', subledger: 'Tax' },
  CLEARING_FREIGHT: { code: '2109001', name: 'Landed cost clearing — freight' },
  CLEARING_DUTY: { code: '2109002', name: 'Landed cost clearing — duty' },
  CLEARING_PORT: { code: '2109003', name: 'Landed cost clearing — port and brokerage' },
  CLEARING_GRIR: { code: '2109009', name: 'Goods received / invoice received clearing' },
  LANDED_VARIANCE: { code: '5109001', name: 'Landed cost variance' },
  COGS: { code: '5101001', name: 'Cost of materials consumed' },
  REVENUE_EXPORT: { code: '4101002', name: 'Revenue from exports' },
  FX_REALISED: { code: '5301001', name: 'Exchange difference — realised' },
  FX_UNREALISED: { code: '5301002', name: 'Exchange difference — unrealised' },
  BANK_CHARGES: { code: '5302001', name: 'Bank charges — trade' },
  ENTITLEMENT_REC: { code: '1307001', name: 'Entitlement receivable — RoDTEP', subledger: 'Entitlement' },
  ENTITLEMENT_INC: { code: '4301001', name: 'Other operating income — export entitlements' },
  SCRIP_LEDGER: { code: '1308001', name: 'Duty credit scrip ledger', subledger: 'Entitlement' },
  DEMURRAGE: { code: '5203001', name: 'Demurrage and detention' },
  TDS_PAYABLE: { code: '2105001', name: 'Tax deducted at source payable', subledger: 'Tax' },
  MEMO_DEFERRED_DUTY: { code: '9101001', name: 'Memorandum — deferred duty on bonded stock' },
};

export const POSTING_RULES: PostingRule[] = [
  {
    code: 'PR-IMP-03', version: 'v2', effectiveFrom: '2026-04-01', event: 'ownershipTransferInTransit',
    voucherType: 'PJV', book: 'Primary', description: 'Ownership transfer at origin per Incoterm — goods in transit recognised',
    standardRef: 'Ind AS 2 / Incoterms 2020',
    lines: [
      { drCr: 'Dr', accountKey: 'GIT', amountKey: 'goodsValueFunc' },
      { drCr: 'Cr', accountKey: 'AP_FOREIGN', amountKey: 'goodsValueFunc' },
    ],
  },
  {
    code: 'PR-IMP-05', version: 'v3', effectiveFrom: '2026-04-01', event: 'dutyAssessed',
    voucherType: 'DTY', book: 'Primary', description: 'Customs duty assessed — split recoverable and inventoriable',
    standardRef: 'Ind AS 2.11 / CGST s.16',
    lines: [
      { drCr: 'Dr', accountKey: 'CLEARING_DUTY', amountKey: 'dutyInventoriable', treatmentBranch: 'non-recoverable to inventory via clearing' },
      { drCr: 'Dr', accountKey: 'IGST_RECOVERABLE', amountKey: 'dutyRecoverable', taxCode: 'IGST-IMP-18', treatmentBranch: 'credit available' },
      { drCr: 'Cr', accountKey: 'DUTY_PAYABLE', amountKey: 'dutyTotal' },
    ],
  },
  {
    code: 'PR-IMP-08', version: 'v3', effectiveFrom: '2026-04-01', event: 'goodsReceipt',
    voucherType: 'PJV', book: 'Primary', description: 'Goods receipt at estimated landed cost with per-element accrual',
    standardRef: 'Ind AS 2',
    lines: [
      { drCr: 'Dr', accountKey: 'INVENTORY', amountKey: 'estimatedLandedCost' },
      { drCr: 'Cr', accountKey: 'GIT', amountKey: 'goodsValueFunc' },
      { drCr: 'Cr', accountKey: 'CLEARING_DUTY', amountKey: 'dutyInventoriable' },
      { drCr: 'Cr', accountKey: 'CLEARING_FREIGHT', amountKey: 'freightEstimate' },
      { drCr: 'Cr', accountKey: 'CLEARING_PORT', amountKey: 'portEstimate' },
    ],
  },
  {
    code: 'PR-IMP-11', version: 'v2', effectiveFrom: '2026-04-01', event: 'landedCostClosure',
    voucherType: 'LCV', book: 'Primary', description: 'Landed cost closure — differential split by stock position',
    standardRef: 'Ind AS 2',
    lines: [
      { drCr: 'Dr', accountKey: 'INVENTORY', amountKey: 'toInventory' },
      { drCr: 'Dr', accountKey: 'COGS', amountKey: 'toCogs' },
      { drCr: 'Cr', accountKey: 'CLEARING_FREIGHT', amountKey: 'differential' },
    ],
  },
  {
    code: 'PR-EXP-02', version: 'v2', effectiveFrom: '2026-04-01', event: 'exportDispatch',
    voucherType: 'SIV', book: 'Primary', description: 'Export dispatch — revenue recognised on transfer of control',
    standardRef: 'Ind AS 115 / Ind AS 21',
    lines: [
      { drCr: 'Dr', accountKey: 'AR_EXPORT', amountKey: 'invoiceValueFunc' },
      { drCr: 'Cr', accountKey: 'REVENUE_EXPORT', amountKey: 'invoiceValueFunc' },
    ],
  },
  {
    code: 'PR-EXP-08', version: 'v2', effectiveFrom: '2026-04-01', event: 'exportRealisation',
    voucherType: 'RCP', book: 'Primary', description: 'Export realisation with charges and realised exchange difference',
    standardRef: 'Ind AS 21.28',
    lines: [
      { drCr: 'Dr', accountKey: 'BANK_FC', amountKey: 'netCredited' },
      { drCr: 'Dr', accountKey: 'BANK_CHARGES', amountKey: 'bankCharges' },
      { drCr: 'Dr', accountKey: 'FX_REALISED', amountKey: 'fxLoss' },
      { drCr: 'Cr', accountKey: 'AR_EXPORT', amountKey: 'carryingAmount' },
    ],
  },
  {
    code: 'PR-EXP-10', version: 'v4', effectiveFrom: '2026-04-01', event: 'entitlementAccrual',
    voucherType: 'ENT', book: 'Primary', description: 'Entitlement accrued where reasonable assurance exists',
    standardRef: 'Ind AS 20.7',
    lines: [
      { drCr: 'Dr', accountKey: 'ENTITLEMENT_REC', amountKey: 'entitlementValue' },
      { drCr: 'Cr', accountKey: 'ENTITLEMENT_INC', amountKey: 'entitlementValue' },
    ],
  },
  {
    code: 'PR-PER-02', version: 'v2', effectiveFrom: '2026-04-01', event: 'fxRevaluation',
    voucherType: 'FXR', book: 'Primary', description: 'Period-end revaluation of monetary items only, auto-reversing',
    standardRef: 'Ind AS 21.23',
    lines: [
      { drCr: 'Dr', accountKey: 'FX_UNREALISED', amountKey: 'revalLoss' },
      { drCr: 'Cr', accountKey: 'AP_FOREIGN', amountKey: 'revalLoss' },
    ],
  },
];

export interface PostingPreviewInput { event: string; amounts: Record<string, number>; dimensions: Record<string, string>; currency?: string; fxRate?: number }

export function previewPosting(input: PostingPreviewInput): {
  rule: PostingRule | null; lines: PostingLine[]; totalDr: number; totalCr: number; balanced: boolean; error?: string;
} {
  const rule = POSTING_RULES.find((r) => r.event === input.event) ?? null;
  if (!rule) {
    return { rule: null, lines: [], totalDr: 0, totalCr: 0, balanced: false,
      error: `No posting rule matches event "${input.event}". Posting is blocked; a default suspense posting is prohibited (HBIE-ACC-066).` };
  }
  const fx = input.fxRate ?? 1;
  const lines: PostingLine[] = rule.lines
    .map((rl, i) => {
      const amount = input.amounts[rl.amountKey] ?? 0;
      const acct = ACCOUNT_DETERMINATION[rl.accountKey];
      return {
        id: `${rule.code}-${i}`, accountCode: acct.code, accountName: acct.name, drCr: rl.drCr,
        amountTxn: round(amount / fx, 2), amountFunc: round(amount, 2),
        currency: input.currency ?? 'INR', fxRate: fx, rateType: 'Accounting (transaction date)',
        dimensions: input.dimensions, taxCode: rl.taxCode, subledgerKey: acct.subledger,
        ruleBranch: rl.treatmentBranch,
      };
    })
    .filter((l) => l.amountFunc !== 0);
  const totalDr = round(lines.filter((l) => l.drCr === 'Dr').reduce((s, l) => s + l.amountFunc, 0), 2);
  const totalCr = round(lines.filter((l) => l.drCr === 'Cr').reduce((s, l) => s + l.amountFunc, 0), 2);
  return { rule, lines, totalDr, totalCr, balanced: Math.abs(totalDr - totalCr) < 0.01 };
}

/* ============================================================================
 *  VALIDATION ENGINE  —  RD Section 21.2
 * ========================================================================== */

/** Units that are the same thing under different names — not a conversion issue. */
const EQUIVALENT_UNITS: string[][] = [
  ['PCS', 'EA', 'NOS', 'UNT', 'NUM'],
  ['KGS', 'KG'],
  ['LTR', 'L'],
  ['MTR', 'M'],
];
function unitsEquivalent(a: string, b: string) {
  if (a === b) return true;
  return EQUIVALENT_UNITS.some((g) => g.includes(a.toUpperCase()) && g.includes(b.toUpperCase()));
}

export function validateDeclaration(d: { lines: DeclarationLine[]; provisional: boolean }) {
  const findings: { id: string; severity: 'error' | 'warning'; field: string; lineNo?: number; rule: string; message: string; remedy: string }[] = [];
  d.lines.forEach((l) => {
    if (l.preferenceAgreement && !l.preferenceProofRef) {
      findings.push({
        id: `VR-009-${l.lineNo}`, severity: 'error', field: 'Origin proof reference', lineNo: l.lineNo, rule: 'VR-009',
        message: `Preferential claim under ${l.preferenceAgreement} requires a valid origin proof reference and confirmation that the underlying origin information is held.`,
        remedy: 'Attach the certificate of origin, or drop the preferential claim and accept the schedule rate.',
      });
    }
    if (l.netWeightKg <= 0) {
      findings.push({ id: `VR-006-${l.lineNo}`, severity: 'error', field: 'Net weight', lineNo: l.lineNo, rule: 'VR-006',
        message: 'Net weight must be positive and consistent with package and container data.', remedy: 'Enter net weight from the packing list.' });
    }
    if (l.conversion === 1 && !unitsEquivalent(l.statutoryUom, l.stockUom)) {
      findings.push({ id: `VR-007-${l.lineNo}`, severity: 'warning', field: 'Statutory unit conversion', lineNo: l.lineNo, rule: 'VR-007',
        message: `Statutory unit (${l.statutoryUom}) differs from stock unit (${l.stockUom}) but the conversion factor is 1.`, remedy: 'Confirm the conversion factor on the item master.' });
    }
  });
  return findings;
}

export { round };
