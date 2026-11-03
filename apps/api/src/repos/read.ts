/**
 * Read repositories. Every function is entity-scoped (the caller passes the
 * entity id resolved from the token) and returns objects shaped exactly as the
 * front end expects — the same contract the in-memory API served, now sourced
 * from MySQL. Business computation (duty, allocation, projection, validation)
 * is delegated to the engines, run over the reconstructed rows.
 */
import { q, q1, n, nOrNull } from '../db/pool.js';
import { ext, parseExt } from './ext.js';
import {
  costTotals, closureImpact, allocate, projectObligation, validateDeclaration, round,
} from '../engines.js';
import type {
  Party, TradeOrder, Shipment, Declaration, DeclarationLine, Levy, CostSheet, CostLine,
  Licence, Instrument, Account, Voucher, PostingLine, VoucherType, CloseTask,
  ReconciliationSummary, ReconItem, EntitlementClaim, ExceptionItem, TaskItem, Severity,
} from '../types.js';

const lc = (s?: string | null) => (s ? s.toLowerCase() : s) as any;
const bool = (v: any) => Number(v) === 1;
const SUBLEDGER: Record<string, string> = { NONE: '', AP: 'AP', AR: 'AR', BANK: 'Bank', INVENTORY: 'Inventory', TAX: 'Tax', ASSET: 'Asset', INSTRUMENT: 'Instrument', ENTITLEMENT: 'Entitlement', BONDED: 'Bonded', OBLIGATION: 'Obligation' };

// ---- parties --------------------------------------------------------------
export async function listParties(entityId: number): Promise<Party[]> {
  const rows = await q<any>('SELECT * FROM trade_party WHERE entity_id = ? ORDER BY id', [entityId]);
  const roleRows = await q<{ party_id: number; role: string }>(
    'SELECT tr.party_id, tr.role FROM trade_party_role tr JOIN trade_party p ON p.id = tr.party_id WHERE p.entity_id = ?', [entityId],
  );
  const roles = new Map<number, string[]>();
  for (const r of roleRows) { const k = n(r.party_id); roles.set(k, [...(roles.get(k) ?? []), lc(r.role)]); }
  return rows.map((r) => partyRow(r, roles.get(n(r.id)) ?? []));
}
function partyRow(r: any, roles: string[]): Party {
  return {
    id: ext.party(n(r.id)), contactCode: r.contact_code, name: r.name, legalName: r.legal_name, country: r.country_code,
    roles, gstin: r.gstin ?? undefined, pan: r.pan ?? undefined, iec: r.iec ?? undefined, ledgerGroup: r.ledger_group ?? undefined,
    ledgerCode: undefined, screeningStatus: lc(r.screening_status) as any, screenedOn: r.screened_at ? String(r.screened_at).slice(0, 10) : '',
    currency: r.currency, incoterm: r.default_incoterm ?? undefined, paymentTerm: r.default_payment_term ?? undefined,
    relatedParty: bool(r.is_related_party), bankVerified: bool(r.bank_verified),
  };
}
export async function getParty(entityId: number, idStr: string): Promise<Party | null> {
  const r = await q1<any>('SELECT * FROM trade_party WHERE entity_id = ? AND id = ?', [entityId, parseExt(idStr)]);
  if (!r) return null;
  const roleRows = await q<{ role: string }>('SELECT role FROM trade_party_role WHERE party_id = ?', [n(r.id)]);
  return partyRow(r, roleRows.map((x) => lc(x.role)));
}

// ---- orders ---------------------------------------------------------------
export async function listOrders(entityId: number, type?: string): Promise<TradeOrder[]> {
  const rows = await q<any>(
    `SELECT * FROM trade_order WHERE entity_id = ? ${type ? 'AND direction = ?' : ''} ORDER BY id`,
    type ? [entityId, type.toUpperCase()] : [entityId],
  );
  const out: TradeOrder[] = [];
  for (const r of rows) out.push(await orderRow(r));
  return out;
}
export async function getOrder(entityId: number, idStr: string): Promise<TradeOrder | null> {
  const r = await q1<any>('SELECT * FROM trade_order WHERE entity_id = ? AND id = ?', [entityId, parseExt(idStr)]);
  return r ? orderRow(r) : null;
}
async function orderRow(r: any): Promise<TradeOrder> {
  const party = await q1<any>('SELECT id FROM trade_party WHERE id = ?', [n(r.party_id)]);
  const lines = await q<any>('SELECT * FROM trade_order_line WHERE order_id = ? ORDER BY line_no', [n(r.id)]);
  const instr = r.instrument_id ? await q1<any>('SELECT id FROM instrument WHERE id = ?', [n(r.instrument_id)]) : null;
  return {
    id: ext.order(n(r.id)), type: lc(r.direction), number: r.order_no, date: String(r.order_date).slice(0, 10),
    partyId: party ? ext.party(n(r.party_id)) : '', currency: r.currency, incoterm: r.incoterm, namedPlace: r.named_place,
    mode: r.transport_mode, portOfLoading: r.port_of_loading, portOfDischarge: r.port_of_discharge, paymentTerm: r.payment_term,
    instrumentRef: instr ? ext.instrument(n(r.instrument_id)) : undefined, shipmentWindowFrom: r.shipment_window_from ? String(r.shipment_window_from).slice(0, 10) : '',
    shipmentWindowTo: r.shipment_window_to ? String(r.shipment_window_to).slice(0, 10) : '', status: r.status, value: n(r.order_value),
    zeroRatingRoute: r.zero_rating_route === 'NA' ? undefined : r.zero_rating_route,
    lines: lines.map((l) => ({
      id: `OL-${n(l.id)}`, itemCode: l.item_code, description: l.description, hsCode: l.hs_code, qty: n(l.qty), uom: l.uom,
      unitPrice: n(l.unit_price), currency: l.currency, originCountry: l.origin_country ?? '', netWeightKg: n(l.net_weight_kg),
      preferenceIntent: l.preference_agreement ?? undefined, schemeIntent: l.scheme_intent ? String(l.scheme_intent).split(',').filter(Boolean) : undefined,
      licenceRef: undefined, estLandedCost: l.est_landed_unit_cost ? round(n(l.est_landed_unit_cost) * n(l.qty), 2) : undefined,
    })),
  };
}

// ---- shipments ------------------------------------------------------------
export async function listShipments(entityId: number, direction?: string): Promise<Shipment[]> {
  const rows = await q<any>(
    `SELECT * FROM shipment WHERE entity_id = ? ${direction ? 'AND direction = ?' : ''} ORDER BY id`,
    direction ? [entityId, direction.toUpperCase()] : [entityId],
  );
  const out: Shipment[] = [];
  for (const r of rows) out.push(await shipmentRow(entityId, r));
  return out;
}
export async function getShipment(entityId: number, idStr: string) {
  const r = await q1<any>('SELECT * FROM shipment WHERE entity_id = ? AND id = ?', [entityId, parseExt(idStr)]);
  if (!r) return null;
  const s = await shipmentRow(entityId, r);
  const party = await getParty(entityId, ext.party(n(r.party_id)));
  const orderIdRows = await q<{ order_id: number }>('SELECT order_id FROM shipment_order WHERE shipment_id = ?', [n(r.id)]);
  const relatedOrders: TradeOrder[] = [];
  for (const o of orderIdRows) { const od = await getOrder(entityId, ext.order(n(o.order_id))); if (od) relatedOrders.push(od); }
  const declRows = await q<any>('SELECT id FROM declaration WHERE entity_id = ? AND shipment_id = ?', [entityId, n(r.id)]);
  const decls: Declaration[] = [];
  for (const d of declRows) { const dd = await getDeclaration(entityId, ext.declaration(n(d.id))); if (dd) decls.push(dd.declaration); }
  const csRow = await q1<any>('SELECT * FROM cost_sheet WHERE entity_id = ? AND shipment_id = ?', [entityId, n(r.id)]);
  const cs = csRow ? await costSheetFromRow(entityId, csRow) : null;
  const costSummary = cs ? costTotals(cs.lines, cs.goodsValue) : null;
  return { ...s, party, orders: relatedOrders, declarations: decls, costSheet: cs, costSummary };
}
async function shipmentRow(entityId: number, r: any): Promise<Shipment> {
  const containers = await q<any>('SELECT * FROM container WHERE shipment_id = ? ORDER BY id', [n(r.id)]);
  const milestones = await q<any>('SELECT * FROM shipment_milestone WHERE shipment_id = ? ORDER BY seq', [n(r.id)]);
  const exc = await listExceptionsFor(entityId, 'shipment', n(r.id));
  const orderIdRows = await q<{ order_id: number }>('SELECT order_id FROM shipment_order WHERE shipment_id = ?', [n(r.id)]);
  const declRows = await q<{ id: number }>('SELECT id FROM declaration WHERE entity_id = ? AND shipment_id = ?', [entityId, n(r.id)]);
  const fwd = r.forwarder_id ? await q1<any>('SELECT name FROM trade_party WHERE id = ?', [n(r.forwarder_id)]) : null;
  const brk = r.broker_id ? await q1<any>('SELECT name FROM trade_party WHERE id = ?', [n(r.broker_id)]) : null;
  return {
    id: ext.shipment(n(r.id)), number: r.shipment_no, direction: lc(r.direction), mode: r.transport_mode,
    orderIds: orderIdRows.map((o) => ext.order(n(o.order_id))), partyId: ext.party(n(r.party_id)), carrier: r.carrier ?? '',
    vessel: r.vessel ?? undefined, voyage: r.voyage ?? undefined, blNumber: r.transport_doc_no ?? undefined,
    blDate: r.transport_doc_date ? String(r.transport_doc_date).slice(0, 10) : undefined, portOfLoading: r.port_of_loading,
    portOfDischarge: r.port_of_discharge, incoterm: r.incoterm, etd: dstr(r.etd), atd: dstr(r.atd), eta: dstr(r.eta), ata: dstr(r.ata),
    stage: r.stage_label ?? r.stage, status: r.status, value: n(r.goods_value), currency: r.currency,
    containers: containers.map((c) => ({ number: c.container_no, type: c.container_type, sealNumber: c.seal_no ?? '', tareKg: n(c.tare_kg), grossKg: n(c.gross_kg), freeFrom: dstr(c.free_from) ?? '', freeDays: n(c.free_days), daysUsed: n(c.days_used), projectedCharge: n(c.projected_charge) })),
    milestones: milestones.map((m) => ({ key: m.milestone_key, label: m.label, planned: dstr(m.planned_on), revised: dstr(m.revised_on), actual: dstr(m.actual_on) })),
    declarationIds: declRows.map((d) => ext.declaration(n(d.id))), docsRequired: n(r.docs_required), docsReceived: n(r.docs_received),
    exceptions: exc, forwarder: fwd?.name ?? '', broker: brk?.name ?? '', grossKg: n(r.gross_weight_kg), netKg: n(r.net_weight_kg),
  };
}
const dstr = (v: any) => (v ? String(v).slice(0, 10) : undefined);

// ---- declarations ---------------------------------------------------------
export async function listDeclarations(entityId: number, direction?: string) {
  const rows = await q<any>(
    `SELECT * FROM declaration WHERE entity_id = ? ${direction ? 'AND direction = ?' : ''} ORDER BY id`,
    direction ? [entityId, direction.toUpperCase()] : [entityId],
  );
  const out: any[] = [];
  for (const r of rows) {
    const lineCount = n((await q1<any>('SELECT COUNT(*) c FROM declaration_line WHERE declaration_id = ? AND period_key = ?', [n(r.id), n(r.period_key)]))?.c);
    out.push({ ...declHeader(r), lineCount });
  }
  return out;
}
export async function getDeclaration(entityId: number, idStr: string) {
  const r = await q1<any>('SELECT * FROM declaration WHERE entity_id = ? AND id = ?', [entityId, parseExt(idStr)]);
  if (!r) return null;
  const lineRows = await q<any>('SELECT * FROM declaration_line WHERE declaration_id = ? AND period_key = ? ORDER BY line_no', [n(r.id), n(r.period_key)]);
  const lines: DeclarationLine[] = [];
  for (const l of lineRows) {
    const levyRows = await q<any>('SELECT * FROM declaration_levy WHERE declaration_line_id = ? AND period_key = ? ORDER BY seq', [n(l.id), n(r.period_key)]);
    const levies: Levy[] = levyRows.map((v) => ({ code: v.levy_code, name: v.levy_name, basis: v.base_expression, rate: n(v.rate_pct), base: n(v.base_amount), amount: n(v.amount), rateSource: v.rate_source, recoverable: bool(v.is_recoverable), exemptionRef: v.rate_source_ref ?? undefined }));
    lines.push({
      id: `DL-${n(l.id)}`, lineNo: n(l.line_no), itemCode: l.item_code, description: l.description, hsCode: l.hs_code, qty: n(l.qty_statutory),
      statutoryUom: l.statutory_uom, stockUom: l.stock_uom, conversion: n(l.uom_conversion), invoiceValueFc: n(l.invoice_value_fc), currency: l.currency,
      freightFc: n(l.freight_fc), insuranceFc: n(l.insurance_fc), originCountry: l.origin_country ?? '', preferenceAgreement: l.preference_agreement ?? undefined,
      preferenceProofRef: l.preference_proof_ref ?? undefined, licenceRef: undefined, assessableValue: n(l.assessable_value), levies,
      dutySaved: n(l.duty_saved), dutyForegoneBlocked: n(l.duty_blocked) || undefined, netWeightKg: n(l.net_weight_kg),
    });
  }
  const entRows = await q<any>('SELECT * FROM entitlement_claim WHERE entity_id = ? AND declaration_id = ? ORDER BY id', [entityId, n(r.id)]);
  const declaration: Declaration = { ...declHeader(r), lines, validations: [], entitlements: entRows.map(entRow) };
  const validations = validateDeclaration(declaration);
  const shipment = r.shipment_id ? (await getShipmentLight(entityId, n(r.shipment_id))) : undefined;
  const party = await getParty(entityId, ext.party(n(r.party_id)));
  const blockedSaving = round(lines.reduce((s, l) => s + (l.dutyForegoneBlocked ?? 0), 0), 2);
  return { declaration, detail: { ...declaration, validations, shipment, party, blockedSaving } };
}
function declHeader(r: any): Declaration {
  return {
    id: ext.declaration(n(r.id)), number: r.declaration_no, type: r.type_label ?? r.declaration_type, direction: lc(r.direction),
    shipmentId: r.shipment_id ? ext.shipment(n(r.shipment_id)) : '', partyId: ext.party(n(r.party_id)), portCode: r.port_code,
    filingChannel: r.filing_channel, authorityRef: r.authority_ref ?? undefined, filedOn: dstr(r.filed_on), status: r.status_label ?? r.status,
    statutoryFxRate: n(r.statutory_fx_rate), currency: r.currency, assessableValue: n(r.assessable_value), dutyTotal: n(r.duty_total),
    dutyRecoverable: n(r.duty_recoverable), dutyInventoriable: n(r.duty_inventoriable), assessedDuty: nOrNull(r.duty_assessed) ?? undefined,
    paidOn: dstr(r.paid_on), clearedOn: dstr(r.cleared_on), lines: [], validations: [], provisional: bool(r.is_provisional),
    leoRef: r.leo_ref ?? undefined, egmMatched: bool(r.egm_matched),
  };
}
async function getShipmentLight(entityId: number, id: number): Promise<Shipment | undefined> {
  const r = await q1<any>('SELECT * FROM shipment WHERE entity_id = ? AND id = ?', [entityId, id]);
  return r ? shipmentRow(entityId, r) : undefined;
}

// ---- cost sheets ----------------------------------------------------------
export async function listCostSheets(entityId: number) {
  const rows = await q<any>('SELECT * FROM cost_sheet WHERE entity_id = ? ORDER BY id', [entityId]);
  const out: any[] = [];
  for (const r of rows) {
    const cs = await costSheetFromRow(entityId, r);
    const ship = await q1<any>('SELECT shipment_no FROM shipment WHERE id = ?', [n(r.shipment_id)]);
    out.push({ ...cs, ...costTotals(cs.lines, cs.goodsValue), shipmentNumber: ship?.shipment_no });
  }
  return out;
}
export async function getCostSheet(entityId: number, idStr: string) {
  const r = await q1<any>('SELECT * FROM cost_sheet WHERE entity_id = ? AND cost_sheet_no = ?', [entityId, idStr]);
  if (!r) return null;
  const cs = await costSheetFromRow(entityId, r);
  const shipment = await getShipmentLight(entityId, n(r.shipment_id));
  return { ...cs, shipment, totals: costTotals(cs.lines, cs.goodsValue), closure: closureImpact(cs.lines, cs.stockOnHandPct) };
}
async function costSheetFromRow(entityId: number, r: any): Promise<CostSheet> {
  const lineRows = await q<any>('SELECT * FROM cost_line WHERE cost_sheet_id = ? ORDER BY line_no', [n(r.id)]);
  const lines: CostLine[] = [];
  for (const l of lineRows) {
    const prov = l.provider_id ? await q1<any>('SELECT name FROM trade_party WHERE id = ?', [n(l.provider_id)]) : null;
    const charge = await q1<any>('SELECT code, name, category FROM charge_type WHERE id = ?', [n(l.charge_type_id)]);
    lines.push({
      id: `CL-${n(l.id)}`, chargeCode: charge?.code ?? '', chargeName: charge?.name ?? '', category: charge?.category ? title(charge.category) : '',
      providerId: l.provider_id ? ext.party(n(l.provider_id)) : undefined, providerName: prov?.name ?? undefined,
      basis: lcBasis(l.basis), estimate: n(l.estimate), accrued: n(l.accrued), actual: l.actual == null ? undefined : n(l.actual),
      invoiceRef: l.invoice_ref ?? undefined, treatment: lc(l.treatment), status: l.status_label ?? l.status, currency: l.currency,
      fxRate: n(l.fx_rate), tolerancePct: n(l.tolerance_pct),
    });
  }
  return { id: r.cost_sheet_no, shipmentId: ext.shipment(n(r.shipment_id)), status: 'Partially actualised', lines, goodsValue: n(r.goods_value), stockOnHandPct: n(r.stock_on_hand_pct) };
}
const title = (s: string) => s.charAt(0) + s.slice(1).toLowerCase();
const lcBasis = (b: string) => ({ GROSS_WEIGHT: 'grossWeight', CHARGEABLE_WEIGHT: 'chargeableWeight', VALUE: 'value', VOLUME: 'volume', QUANTITY: 'quantity', CONTAINER: 'container', DIRECT: 'direct', EQUAL: 'equal' } as Record<string, string>)[b] ?? lc(b);

// allocation targets from the shipment's first order lines (as the old API did)
export async function allocateCostLine(entityId: number, csId: string, chargeLineId: string, basis: any) {
  const cs = await getCostSheet(entityId, csId);
  if (!cs) return null;
  const line = cs.lines.find((l) => l.id === chargeLineId);
  if (!line) return { notFound: 'line' as const };
  const shipRow = await q1<any>('SELECT id FROM shipment WHERE entity_id = ? AND shipment_no = ?', [entityId, (cs as any).shipment?.number ?? '']);
  let targets: any[] = [];
  if (shipRow) {
    const orderIdRows = await q<{ order_id: number }>('SELECT order_id FROM shipment_order WHERE shipment_id = ?', [n(shipRow.id)]);
    if (orderIdRows.length) {
      const ol = await q<any>('SELECT * FROM trade_order_line WHERE order_id = ? ORDER BY line_no', [n(orderIdRows[0].order_id)]);
      targets = ol.map((l) => ({ id: `OL-${n(l.id)}`, label: `${l.item_code} ${l.description}`, value: n(l.qty) * n(l.unit_price), grossWeight: n(l.net_weight_kg) * 1.06, volume: n(l.net_weight_kg) / 320, quantity: n(l.qty) }));
    }
  }
  const amount = line.actual ?? line.estimate;
  return { basis, amount, allocation: allocate(amount, basis, targets) };
}

// ---- licences -------------------------------------------------------------
export async function listLicences(entityId: number) {
  const rows = await q<any>('SELECT * FROM licence WHERE entity_id = ? ORDER BY id', [entityId]);
  const out: any[] = [];
  for (const r of rows) { const l = await licenceFromRow(entityId, r); out.push({ ...l, projection: projectObligation(l) }); }
  return out;
}
export async function getLicence(entityId: number, idStr: string) {
  const r = await q1<any>('SELECT * FROM licence WHERE entity_id = ? AND id = ?', [entityId, parseExt(idStr)]);
  if (!r) return null;
  const l = await licenceFromRow(entityId, r);
  return { ...l, projection: projectObligation(l) };
}
async function licenceFromRow(entityId: number, r: any): Promise<Licence> {
  const blocks = await q<any>('SELECT * FROM licence_block WHERE licence_id = ? ORDER BY block_no', [n(r.id)]);
  const util = await q<any>('SELECT * FROM licence_utilisation WHERE licence_id = ? ORDER BY entry_date, id', [n(r.id)]);
  const fulfil = await q<any>('SELECT * FROM licence_fulfilment WHERE licence_id = ? ORDER BY entry_date, id', [n(r.id)]);
  const conds = await q<any>('SELECT * FROM licence_condition WHERE licence_id = ? ORDER BY id', [n(r.id)]);
  return {
    id: ext.licence(n(r.id)), scheme: r.scheme_label ?? '', number: r.licence_no, issuedOn: dstr(r.issued_on) ?? '', importValidTo: dstr(r.import_valid_to) ?? '',
    exportValidTo: dstr(r.export_valid_to) ?? '', status: r.status_label ?? r.status, dutySaved: n(r.duty_saved), obligationAmount: n(r.obligation_amount),
    obligationType: r.obligation_label ?? '', minValueAddition: nOrNull(r.min_value_addition_pct) ?? undefined, averageObligation: nOrNull(r.average_obligation) ?? undefined,
    averageMaintained: r.average_maintained == null ? undefined : bool(r.average_maintained),
    blocks: blocks.map((b) => ({ label: b.label, sharePct: n(b.share_pct), dueOn: dstr(b.due_on) ?? '', fulfilled: n(b.fulfilled_amount) })),
    utilisation: util.map((u) => ({ id: `U-${n(u.id)}`, date: dstr(u.entry_date) ?? '', ref: u.reference, description: u.description, qty: nOrNull(u.qty) ?? undefined, value: n(u.value) })),
    fulfilment: fulfil.map((f) => ({ id: `F-${n(f.id)}`, date: dstr(f.entry_date) ?? '', ref: f.reference, description: f.description, value: n(f.fob_value), evidenceComplete: bool(f.evidence_complete) })),
    conditions: conds.map((c) => ({ name: c.name, satisfied: bool(c.is_satisfied), detail: c.detail })),
    bondRef: undefined, bgWaived: bool(r.bg_waived),
  };
}

// ---- instruments ----------------------------------------------------------
export async function listInstruments(entityId: number): Promise<Instrument[]> {
  const rows = await q<any>('SELECT * FROM instrument WHERE entity_id = ? ORDER BY id', [entityId]);
  const out: Instrument[] = [];
  for (const r of rows) out.push(await instrumentFromRow(r));
  return out;
}
export async function getInstrument(entityId: number, idStr: string) {
  const r = await q1<any>('SELECT * FROM instrument WHERE entity_id = ? AND id = ?', [entityId, parseExt(idStr)]);
  if (!r) return null;
  const i = await instrumentFromRow(r);
  // presentation deadline: latest shipment date + presentation days, capped at expiry
  const shipRow = await q1<any>(
    `SELECT s.atd, s.etd FROM shipment s
       JOIN shipment_order so ON so.shipment_id = s.id
       JOIN trade_order o ON o.id = so.order_id
      WHERE o.instrument_id = ? LIMIT 1`, [n(r.id)],
  );
  const shipDate = shipRow ? (dstr(shipRow.atd) ?? dstr(shipRow.etd)) : undefined;
  const deadline = shipDate ? new Date(new Date(shipDate).getTime() + n(r.presentation_days) * 864e5).toISOString().slice(0, 10) : undefined;
  const presentationDeadline = deadline && deadline > i.expiryDate ? i.expiryDate : deadline;
  return { ...i, presentationDeadline };
}
async function instrumentFromRow(r: any): Promise<Instrument> {
  const reqs = await q<any>('SELECT * FROM instrument_doc_requirement WHERE instrument_id = ? ORDER BY seq', [n(r.id)]);
  const disc = await q<any>('SELECT * FROM instrument_discrepancy WHERE instrument_id = ? ORDER BY id', [n(r.id)]);
  return {
    id: ext.instrument(n(r.id)), number: r.instrument_no, type: r.type_label ?? r.instrument_type, governingRules: r.governing_rules ?? '',
    issuingBank: r.issuing_bank_name ?? '', advisingBank: r.advising_bank_name ?? undefined, applicant: r.applicant_name ?? '', beneficiary: r.beneficiary_name ?? '',
    currency: r.currency, value: n(r.face_value), tolerancePct: n(r.tolerance_pct), latestShipmentDate: dstr(r.latest_shipment_date) ?? '',
    expiryDate: dstr(r.expiry_date) ?? '', presentationDays: n(r.presentation_days), paymentTerms: r.payment_terms ?? '', status: r.status_label ?? r.status,
    drawnValue: n(r.drawn_value), availableValue: n(r.available_value), charges: n(r.charges_to_date),
    discrepancies: disc.map((d) => ({ id: `DC-${n(d.id)}`, code: d.code, description: d.description, disposition: d.outcome ?? undefined })),
    documentRequirements: reqs.map((d) => ({ doc: d.doc_type, originals: n(d.originals), copies: n(d.copies), issuer: d.issuer ?? '', wording: d.required_wording ?? undefined, held: bool(d.is_held) })),
  };
}

// ---- entitlements ---------------------------------------------------------
function entRow(e: any): EntitlementClaim {
  return {
    id: e.claim_no, scheme: e.scheme_id ? '' : '', declarationId: '', declarationNumber: e.declaration_no, fobValue: n(e.fob_value),
    ratePct: n(e.rate_pct), cap: nOrNull(e.cap_amount) ?? undefined, computed: n(e.computed_amount), claimed: n(e.claimed_amount),
    sanctioned: nOrNull(e.sanctioned_amount) ?? undefined, received: nOrNull(e.received_amount) ?? undefined, scripRef: e.scrip_ref ?? undefined,
    stage: e.stage, recognitionPoint: e.recognition_point === 'AT_SANCTION' ? 'On sanction' : 'On export', recognised: bool(e.is_recognised),
    filedOn: dstr(e.filed_on), shortfallCause: e.shortfall_cause ?? undefined,
  };
}
export async function listEntitlements(entityId: number): Promise<EntitlementClaim[]> {
  const rows = await q<any>(
    `SELECT ec.*, s.code scheme_code, d.declaration_no decl_no
       FROM entitlement_claim ec
       LEFT JOIN scheme s ON s.id = ec.scheme_id
       LEFT JOIN declaration d ON d.id = ec.declaration_id
      WHERE ec.entity_id = ? ORDER BY ec.id`, [entityId],
  );
  return rows.map((e) => ({ ...entRow(e), scheme: e.scheme_code === 'RODTEP' ? 'RoDTEP' : e.scheme_code === 'DRAWBACK' ? 'Drawback' : e.scheme_code, declarationId: e.declaration_id ? ext.declaration(n(e.declaration_id)) : '' }));
}

// ---- exceptions & tasks ---------------------------------------------------
const SEV_RANK: Record<string, number> = { critical: 0, high: 1, medium: 2, info: 3 };
export async function listExceptions(entityId: number, severity?: string): Promise<ExceptionItem[]> {
  const rows = await q<any>(
    `SELECT * FROM exception_item WHERE entity_id = ? ${severity ? 'AND severity = ?' : ''}`,
    severity ? [entityId, severity.toUpperCase()] : [entityId],
  );
  return rows.map(excRow).sort((a, b) => (SEV_RANK[a.severity] - SEV_RANK[b.severity]) || ((b.exposure ?? 0) - (a.exposure ?? 0)));
}
async function listExceptionsFor(entityId: number, objectType: string, objectId: number): Promise<ExceptionItem[]> {
  const rows = await q<any>('SELECT * FROM exception_item WHERE entity_id = ? AND object_type = ? AND object_id = ?', [entityId, objectType, objectId]);
  return rows.map(excRow);
}
function excRow(e: any): ExceptionItem {
  return {
    id: `E-${n(e.id)}`, severity: lc(e.severity) as Severity, type: e.exception_type, title: e.title, detail: e.detail,
    objectType: e.object_type, objectId: e.object_ref ?? String(e.object_id), exposure: nOrNull(e.exposure) ?? undefined,
    deadline: dstr(e.deadline_on), ageDays: n(e.age_days), owner: '', ruleId: e.rule_id, open: bool(e.is_open),
  };
}
export async function listTasks(entityId: number): Promise<TaskItem[]> {
  const rows = await q<any>('SELECT * FROM work_task WHERE entity_id = ? ORDER BY id', [entityId]);
  return rows.map((t) => ({
    id: `T-${n(t.id)}`, title: t.title, detail: t.detail, severity: lc(t.severity) as Severity, objectType: t.object_type,
    objectId: String(t.object_id), route: t.route, dueOn: dstr(t.due_on), owner: '', kind: t.task_kind,
  }));
}
