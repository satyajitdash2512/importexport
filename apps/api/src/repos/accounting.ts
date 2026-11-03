/**
 * Accounting read repositories. The trial balance reads the maintained rollup
 * (account_period_balance) — never posting_line — so it is a few-thousand-row
 * scan regardless of posting volume. Voucher detail reads posting_line by the
 * partition-pruned voucher key.
 */
import { q, q1, n, nOrNull } from '../db/pool.js';
import { config } from '../db/env.js';
import { ext, parseExt } from './ext.js';
import { POSTING_RULES, LEVY_CASCADE_IN, ACCOUNT_DETERMINATION } from '../engines.js';
import type { Account, Voucher, PostingLine, VoucherType, CloseTask, ReconciliationSummary, ReconItem } from '../types.js';

const bool = (v: any) => Number(v) === 1;
const lc = (s?: string | null) => (s ? s.toLowerCase() : s) as any;
const dstr = (v: any) => (v ? String(v).slice(0, 10) : undefined);
const SUBLEDGER: Record<string, string> = { NONE: '', AP: 'AP', AR: 'AR', BANK: 'Bank', INVENTORY: 'Inventory', TAX: 'Tax', ASSET: 'Asset', INSTRUMENT: 'Instrument', ENTITLEMENT: 'Entitlement', BONDED: 'Bonded', OBLIGATION: 'Obligation' };
const RECON: Record<string, string> = { NONE: '', DAILY: 'Daily', WEEKLY: 'Weekly', MONTHLY: 'Monthly', QUARTERLY: 'Quarterly' };
const VSTATUS: Record<string, string> = { POSTED: 'posted', PENDING_APPROVAL: 'pendingApproval', PARKED: 'parked', REVERSED: 'reversed', CANCELLED: 'cancelled' };
const CSTATUS: Record<string, string> = { COMPLETE: 'complete', IN_PROGRESS: 'inProgress', BLOCKED: 'blocked', NOT_STARTED: 'notStarted' };

function period(req?: number) { return req || config.server.defaultPeriodKey; }

// ---- masters --------------------------------------------------------------
export async function listAccounts(entityId: number, periodKey = config.server.defaultPeriodKey): Promise<Account[]> {
  const rows = await q<any>(
    `SELECT a.*, b.opening_dr, b.opening_cr, b.period_dr, b.period_cr
       FROM gl_account a
       LEFT JOIN account_period_balance b ON b.account_id = a.id AND b.entity_id = a.entity_id AND b.book_id = 1 AND b.period_key = ?
      WHERE a.entity_id = ? ORDER BY a.code`, [periodKey, entityId],
  );
  return rows.map(accountRow);
}
function accountRow(a: any): Account {
  return {
    code: a.code, name: a.name, class: lc(a.account_class), type: lc(a.account_type), group: a.account_group,
    scheduleIIIGroup: a.schedule_iii_group ?? '', cashFlow: lc(a.cash_flow_class), subledger: SUBLEDGER[a.subledger] || undefined,
    monetary: bool(a.is_monetary), manualPostingAllowed: bool(a.manual_posting_allowed),
    mandatoryDimensions: a.mandatory_dimensions ? String(a.mandatory_dimensions).split(',').filter(Boolean) : [],
    reconFrequency: RECON[a.recon_frequency] || undefined, currency: a.currency ?? undefined,
    openingDr: n(a.opening_dr), openingCr: n(a.opening_cr), periodDr: n(a.period_dr), periodCr: n(a.period_cr),
  };
}

export function listVoucherTypesStatic() { return null; }
export async function listVoucherTypes(entityId: number): Promise<VoucherType[]> {
  const rows = await q<any>('SELECT * FROM voucher_type WHERE entity_id = ? ORDER BY id', [entityId]);
  return rows.map((v) => ({
    code: v.code, name: v.name, documentClass: title(v.document_class), statutorySeries: bool(v.statutory_series),
    postsOn: lc(v.posts_on) === 'save' ? 'save' : 'approval', reversible: bool(v.reversible),
    requiredEvidence: v.required_evidence ? String(v.required_evidence).split('; ').filter(Boolean) : [],
    approvalMatrix: v.approval_matrix ?? '', printFormat: v.print_format ?? '', retentionYears: n(v.retention_years),
    books: v.books ? String(v.books).split(',').map(title) : ['Primary'],
  }));
}
const title = (s: string) => s.charAt(0) + s.slice(1).toLowerCase();

export function postingRules() { return POSTING_RULES; }
export function levyCascade() { return LEVY_CASCADE_IN; }
export function accountDetermination() { return ACCOUNT_DETERMINATION; }

// ---- trial balance --------------------------------------------------------
export async function trialBalance(entityId: number, group?: string, periodKey = config.server.defaultPeriodKey) {
  const rows = await q<any>(
    `SELECT a.code, a.name, a.account_class, a.account_type, a.account_group, a.schedule_iii_group, a.subledger,
            a.is_monetary, a.manual_posting_allowed, a.recon_frequency,
            b.opening_dr, b.opening_cr, b.period_dr, b.period_cr
       FROM gl_account a
       JOIN account_period_balance b ON b.account_id = a.id AND b.entity_id = a.entity_id AND b.book_id = 1 AND b.period_key = ?
      WHERE a.entity_id = ? ${group ? 'AND a.account_group = ?' : ''}
      ORDER BY a.code`,
    group ? [periodKey, entityId, group] : [periodKey, entityId],
  );
  const mapped = rows.map((a) => {
    const openNet = n(a.opening_dr) - n(a.opening_cr);
    const closeNet = openNet + n(a.period_dr) - n(a.period_cr);
    return {
      code: a.code, name: a.name, class: lc(a.account_class), type: lc(a.account_type), group: a.account_group,
      scheduleIIIGroup: a.schedule_iii_group ?? '', subledger: SUBLEDGER[a.subledger] || undefined, monetary: bool(a.is_monetary),
      manualPostingAllowed: bool(a.manual_posting_allowed), reconFrequency: RECON[a.recon_frequency] || undefined,
      openingDr: openNet > 0 ? openNet : 0, openingCr: openNet < 0 ? -openNet : 0,
      periodDr: n(a.period_dr), periodCr: n(a.period_cr),
      closingDr: closeNet > 0 ? closeNet : 0, closingCr: closeNet < 0 ? -closeNet : 0,
    };
  });
  const totals = mapped.reduce((t, r) => ({
    openingDr: t.openingDr + r.openingDr, openingCr: t.openingCr + r.openingCr,
    periodDr: t.periodDr + r.periodDr, periodCr: t.periodCr + r.periodCr,
    closingDr: t.closingDr + r.closingDr, closingCr: t.closingCr + r.closingCr,
  }), { openingDr: 0, openingCr: 0, periodDr: 0, periodCr: 0, closingDr: 0, closingCr: 0 });
  const balanced = Math.abs(totals.closingDr - totals.closingCr) < 1;
  return { rows: mapped, totals, balanced, book: 'Primary', period: 'Jul 2026' };
}

// ---- vouchers -------------------------------------------------------------
export async function listVouchers(entityId: number, opts: { status?: string; voucherType?: string; q?: string; limit?: number; offset?: number } = {}) {
  const where: string[] = ['v.entity_id = ?'];
  const params: any[] = [entityId];
  if (opts.status) { where.push('v.status = ?'); params.push(Object.keys(VSTATUS).find((k) => VSTATUS[k] === opts.status) ?? opts.status.toUpperCase()); }
  if (opts.voucherType) { where.push('vt.code = ?'); params.push(opts.voucherType); }
  if (opts.q && opts.q.trim()) { const like = `%${opts.q.trim()}%`; where.push('(v.voucher_no LIKE ? OR v.narration LIKE ? OR vt.code LIKE ?)'); params.push(like, like, like); }
  const total = n((await q1<any>(`SELECT COUNT(*) c FROM voucher v JOIN voucher_type vt ON vt.id = v.voucher_type_id WHERE ${where.join(' AND ')}`, params))?.c);
  const limit = Math.min(Math.max(opts.limit ?? 100, 1), 500);
  const offset = Math.max(opts.offset ?? 0, 0);
  const rows = await q<any>(
    `SELECT v.*, vt.code vt_code, vt.name vt_name,
            (SELECT COUNT(*) FROM posting_line pl WHERE pl.voucher_id = v.id AND pl.period_key = v.period_key) line_count,
            (SELECT COUNT(*) FROM voucher_evidence e WHERE e.voucher_id = v.id AND e.is_mandatory = 1 AND e.is_attached = 0) ev_missing,
            v.prepared_by_name prepared_name, v.approved_by_name approved_name
       FROM voucher v
       JOIN voucher_type vt ON vt.id = v.voucher_type_id
      WHERE ${where.join(' AND ')}
      ORDER BY v.voucher_date DESC, v.id DESC
      LIMIT ? OFFSET ?`, [...params, limit, offset],
  );
  const list = rows.map((v) => ({
    id: ext.voucher(n(v.id)), voucherType: v.vt_code, voucherTypeName: v.vt_name, number: v.voucher_no, date: dstr(v.voucher_date),
    book: v.book_label ?? 'Primary', narration: v.narration, status: VSTATUS[v.status], sourceType: v.source_type ?? undefined,
    postingRule: v.posting_rule_code ?? 'MANUAL', postingRuleVersion: v.posting_rule_version ?? '—', preparedBy: v.prepared_name ?? '',
    approvedBy: v.approved_name ?? undefined, postedAt: v.posted_at ? String(v.posted_at).replace(' ', 'T') : undefined,
    totalDr: n(v.total_dr), totalCr: n(v.total_cr), currency: v.currency, lineCount: n(v.line_count),
    evidenceComplete: n(v.ev_missing) === 0, evidenceMissing: n(v.ev_missing),
  }));
  return { list, total, limit, offset };
}

export async function getVoucher(entityId: number, idStr: string) {
  const v = await q1<any>(
    `SELECT v.*, vt.code vt_code, vt.name vt_name, v.prepared_by_name prepared_name, v.approved_by_name approved_name
       FROM voucher v JOIN voucher_type vt ON vt.id = v.voucher_type_id
      WHERE v.entity_id = ? AND v.id = ?`, [entityId, parseExt(idStr)],
  );
  if (!v) return null;
  const lineRows = await q<any>(
    `SELECT pl.*, a.code account_code, a.name account_name
       FROM posting_line pl JOIN gl_account a ON a.id = pl.account_id
      WHERE pl.voucher_id = ? AND pl.period_key = ? ORDER BY pl.line_no`, [n(v.id), n(v.period_key)],
  );
  const lines: PostingLine[] = lineRows.map((l) => ({
    id: `PL-${n(l.id)}`, accountCode: l.account_code, accountName: l.account_name, drCr: l.dr_cr === 'DR' ? 'Dr' : 'Cr',
    amountTxn: n(l.amount_txn), amountFunc: n(l.amount_func), currency: l.currency, fxRate: n(l.fx_rate), rateType: title(l.fx_rate_type),
    dimensions: dims(l), taxCode: l.tax_code ?? undefined, subledgerKey: l.subledger_key ?? undefined, ruleBranch: l.rule_branch ?? undefined,
  }));
  const evRows = await q<any>('SELECT * FROM voucher_evidence WHERE voucher_id = ? ORDER BY id', [n(v.id)]);
  const evidence = evRows.map((e) => ({ id: `EV-${n(e.id)}`, docType: e.doc_type, name: e.file_name ?? '', issuer: e.issuer ?? undefined, ref: e.doc_ref ?? undefined, date: dstr(e.doc_date), mandatory: bool(e.is_mandatory), attached: bool(e.is_attached), version: n(e.version_no), sizeKb: nOrNull(e.size_kb) ?? undefined }));
  const voucher: Voucher = {
    id: ext.voucher(n(v.id)), voucherType: v.vt_code, voucherTypeName: v.vt_name, number: v.voucher_no, date: dstr(v.voucher_date) ?? '',
    book: v.book_label ?? 'Primary', narration: v.narration, status: VSTATUS[v.status] as any, sourceType: v.source_type ?? undefined,
    sourceId: v.source_id ? String(v.source_id) : undefined, postingRule: v.posting_rule_code ?? 'MANUAL', postingRuleVersion: v.posting_rule_version ?? '—',
    preparedBy: v.prepared_name ?? '', approvedBy: v.approved_name ?? undefined, postedAt: v.posted_at ? String(v.posted_at).replace(' ', 'T') : undefined,
    lines, evidence, totalDr: n(v.total_dr), totalCr: n(v.total_cr), currency: v.currency,
  };
  const rule = POSTING_RULES.find((r) => r.code === voucher.postingRule) ?? null;
  const vt = (await listVoucherTypes(entityId)).find((t) => t.code === voucher.voucherType) ?? null;
  return { ...voucher, rule, voucherTypeDef: vt };
}
function dims(l: any): Record<string, string> {
  const d: Record<string, string> = {};
  if (l.shipment_id) d.shipment = ext.shipment(n(l.shipment_id));
  if (l.declaration_id) d.declaration = ext.declaration(n(l.declaration_id));
  if (l.cost_centre) d.costCentre = l.cost_centre;
  if (l.project_code) d.project = l.project_code;
  return d;
}

// ---- close ----------------------------------------------------------------
export async function closeTasks(entityId: number, periodKey = config.server.defaultPeriodKey) {
  const rows = await q<any>('SELECT * FROM close_task WHERE entity_id = ? AND period_key = ? ORDER BY seq_no', [entityId, periodKey]);
  const tasks: CloseTask[] = rows.map((t) => ({
    id: `CT-${n(t.id)}`, day: t.day_offset, step: t.step, area: t.area, owner: t.owner_role, status: CSTATUS[t.status] as any,
    mandatory: bool(t.is_mandatory), blockingCount: n(t.blocking_count), blockingDetail: t.blocking_detail ?? undefined,
    evidence: t.evidence_ref ?? undefined, signedOffBy: undefined,
  }));
  const summary = {
    total: tasks.length, complete: tasks.filter((t) => t.status === 'complete').length, blocked: tasks.filter((t) => t.status === 'blocked').length,
    inProgress: tasks.filter((t) => t.status === 'inProgress').length, notStarted: tasks.filter((t) => t.status === 'notStarted').length,
    mandatoryIncomplete: tasks.filter((t) => t.mandatory && t.status !== 'complete').length,
    lockPermitted: tasks.filter((t) => t.mandatory && t.status !== 'complete').length === 0,
  };
  return { tasks, summary };
}

// ---- reconciliations ------------------------------------------------------
export async function listReconciliations(entityId: number) {
  const rows = await q<any>('SELECT * FROM reconciliation WHERE entity_id = ? ORDER BY code', [entityId]);
  const out: any[] = [];
  for (const r of rows) {
    const count = n((await q1<any>('SELECT COUNT(*) c FROM reconciliation_item WHERE reconciliation_id = ?', [n(r.id)]))?.c);
    out.push({ ...reconHeader(r), itemCount: count });
  }
  return out;
}
export async function getReconciliation(entityId: number, code: string) {
  const r = await q1<any>('SELECT * FROM reconciliation WHERE entity_id = ? AND code = ?', [entityId, code]);
  if (!r) return null;
  const items = await q<any>('SELECT * FROM reconciliation_item WHERE reconciliation_id = ? ORDER BY age_days DESC, id', [n(r.id)]);
  return { ...reconHeader(r), items: items.map(reconItem) };
}
function reconHeader(r: any): Omit<ReconciliationSummary, 'items'> {
  return {
    id: r.code, name: r.name, sourceA: r.source_a, sourceB: r.source_b, frequency: title(r.frequency), owner: r.owner_role,
    asOf: dstr(r.as_of) ?? '', matched: n(r.matched_count), unmatchedA: n(r.unmatched_a), unmatchedB: n(r.unmatched_b),
    valueAtRisk: n(r.value_at_risk), oldestDays: n(r.oldest_days), status: lc(r.status),
  } as any;
}
function reconItem(i: any): ReconItem {
  const stMap: Record<string, string> = { UNMATCHED: 'unmatched', MATCHED_MANUAL: 'matchedManual', MATCHED_AUTO: 'matchedManual', DISPUTED: 'disputed', WRITTEN_OFF: 'unmatched' };
  return {
    id: `RI-${n(i.id)}`, ref: i.item_ref, date: dstr(i.item_date) ?? '', description: i.description, amountA: nOrNull(i.amount_a) ?? undefined,
    amountB: nOrNull(i.amount_b) ?? undefined, difference: n(i.difference), cause: i.cause ?? '', ageDays: n(i.age_days),
    limitationDate: dstr(i.limitation_date), status: stMap[i.status] as any,
  };
}

// ---- cockpit --------------------------------------------------------------
export async function cockpit(entityId: number) {
  const one = async (sql: string, p: any[] = []) => n((await q1<any>(sql, p))?.c);
  const openExceptions = await one('SELECT COUNT(*) c FROM exception_item WHERE entity_id = ? AND is_open = 1', [entityId]);
  const critical = await one("SELECT COUNT(*) c FROM exception_item WHERE entity_id = ? AND is_open = 1 AND severity = 'CRITICAL'", [entityId]);
  const high = await one("SELECT COUNT(*) c FROM exception_item WHERE entity_id = ? AND is_open = 1 AND severity = 'HIGH'", [entityId]);
  const parkedVouchers = await one("SELECT COUNT(*) c FROM voucher WHERE entity_id = ? AND status IN ('PARKED','PENDING_APPROVAL')", [entityId]);

  const ent = await q1<any>(
    `SELECT COALESCE(SUM(computed_amount),0) eligible, COALESCE(SUM(claimed_amount),0) claimed, COALESCE(SUM(received_amount),0) received
       FROM entitlement_claim WHERE entity_id = ?`, [entityId],
  );
  const closeAgg = await q1<any>(
    `SELECT COUNT(*) total, SUM(status = 'COMPLETE') complete FROM close_task WHERE entity_id = ? AND period_key = ?`, [entityId, config.server.defaultPeriodKey],
  );
  const closeProgressPct = closeAgg && n(closeAgg.total) ? Math.round((n(closeAgg.complete) / n(closeAgg.total)) * 100) : 0;

  const lics = await q<any>('SELECT id, obligation_amount, obligation_fulfilled FROM licence WHERE entity_id = ?', [entityId]);
  const pctList = lics.map((l) => (n(l.obligation_amount) === 0 ? 100 : Math.min(100, (n(l.obligation_fulfilled) / n(l.obligation_amount)) * 100)));
  const obligationCoverPct = pctList.length ? Math.round(pctList.reduce((a, b) => a + b, 0) / pctList.length) : 0;

  const uninvoiced = n((await q1<any>('SELECT COALESCE(SUM(uninvoiced_accrual),0) c FROM cost_sheet WHERE entity_id = ?', [entityId]))?.c);
  const openCostSheets = await one("SELECT COUNT(*) c FROM cost_sheet WHERE entity_id = ? AND status <> 'CLOSED'", [entityId]);
  const clearingAged = uninvoiced;

  // The curated narrative panels below are the same demonstration content the
  // reference build shipped; the counts above are live from the database.
  return {
    needsAction: [
      { key: 'freeTime', label: 'containers with free time under 2 days', count: 2, exposure: 68000, severity: 'critical', route: '/logistics/containers' },
      { key: 'queries', label: 'declarations with an unanswered query', count: 1, ageDays: 3, severity: 'critical', route: '/import/declarations' },
      { key: 'presentation', label: 'bank presentation due tomorrow', count: 1, ref: 'LC/2026/0918', severity: 'critical', route: '/finance/presentations/I-002' },
      { key: 'docs', label: 'shipments with incomplete documents', count: 2, severity: 'high', route: '/import/shipments' },
      { key: 'obligation', label: 'authorisations with obligation at risk', count: 2, severity: 'high', route: '/compliance/licences' },
      { key: 'edpms', label: 'exchange-control entries over 8 months', count: 9, exposure: 8940000, severity: 'high', route: '/finance/reconciliations/R-04' },
      { key: 'parked', label: 'parked or unapproved vouchers at cut-off', count: parkedVouchers, severity: 'high', route: '/accounting/vouchers' },
      { key: 'clearing', label: 'clearing balances beyond policy age', count: 2, exposure: 212000, severity: 'high', route: '/finance/reconciliations/R-03' },
    ],
    importPipeline: [
      { stage: 'In transit', count: 1, value: 96400, currency: 'EUR' },
      { stage: 'Under clearance', count: 1, value: 184500, currency: 'USD', exceptions: 3 },
      { stage: 'Cleared, not received', count: 0, value: 0, currency: 'USD' },
      { stage: 'Cost sheet open', count: 2, value: 280700, currency: 'USD', exceptions: 1 },
    ],
    exportPipeline: [
      { stage: 'In fulfilment', count: 1, value: 128600, currency: 'USD', exceptions: 2 },
      { stage: 'Awaiting permission to export', count: 0, value: 0, currency: 'EUR' },
      { stage: 'Documents with bank', count: 1, value: 342800, currency: 'EUR', exceptions: 1 },
      { stage: 'Awaiting realisation', count: 9, value: 8940000, currency: 'INR', exceptions: 9 },
    ],
    compliance: { openExceptions, critical, high, obligationCoverPct, filingsDue7Days: 3, overridesThisMonth: 6, overridesTrend: 2 },
    accounting: { manualJournals: 4, manualJournalTrend: -1, parkedVouchers, clearingAged, subledgerDifferences: 0, closeProgressPct, lockPermitted: false, evidenceCompletePct: 92 },
    entitlements: { eligible: n(ent?.eligible), claimed: n(ent?.claimed), received: n(ent?.received), gap: Math.round(n(ent?.claimed) - n(ent?.received)) },
    fx: [
      { currency: 'USD', netExposure: 2400000, hedgedPct: 62, position: 'long' },
      { currency: 'EUR', netExposure: 820000, hedgedPct: 40, position: 'short' },
    ],
    costTrend: [
      { month: 'Feb', landedPct: 12.4, demurrage: 42000 }, { month: 'Mar', landedPct: 12.1, demurrage: 38000 },
      { month: 'Apr', landedPct: 11.6, demurrage: 51000 }, { month: 'May', landedPct: 11.9, demurrage: 26000 },
      { month: 'Jun', landedPct: 11.2, demurrage: 18000 }, { month: 'Jul', landedPct: 10.8, demurrage: 36000 },
    ],
    openCostSheets, uninvoicedAccrual: Math.round(uninvoiced),
  };
}
