/**
 * Demo seed. Loads the engine-derived demo dataset (the SAME objects the
 * in-memory API served, so every figure is computed once and agrees
 * everywhere) into MySQL. Idempotent by truncate-and-reload of the demo entity.
 *
 *   tsx src/scripts/seed.ts
 *
 * The reference/master/security rows and the accounting + trade demo live under
 * entity_id = 1. The high-volume generator (generate.ts) adds synthetic
 * documents in future periods under the same entity without touching this data.
 */
import bcrypt from 'bcryptjs';
import { exec, q, cexec, cq, n } from '../db/pool.js';
import { runWithTenant, controlPool, closeAllPools } from '../db/pools.js';
import { config } from '../db/env.js';
import { ROLES, allPermissions, SOD, SEED_USERS, DEMO_PASSWORD } from '../auth/rbac.js';
import { ACCOUNT_DETERMINATION, POSTING_RULES } from '../engines.js';
import * as S from '../seed.js';

import { TENANTS } from '../tenants.js';

const ENTITY = 1;

/** Control-plane insert (hb_control). */
async function cins(table: string, obj: Record<string, any>): Promise<number> {
  const keys = Object.keys(obj);
  const sql = `INSERT INTO \`${table}\` (${keys.map((k) => `\`${k}\``).join(',')}) VALUES (${keys.map(() => '?').join(',')})`;
  const r = await cexec(sql, keys.map((k) => obj[k]));
  return r.insertId;
}
const pk = (d?: string) => (d ? Number(d.slice(0, 4)) * 100 + Number(d.slice(5, 7)) : config.server.defaultPeriodKey);

/** Generic insert; returns insertId. */
async function ins(table: string, obj: Record<string, any>): Promise<number> {
  const keys = Object.keys(obj);
  const sql = `INSERT INTO \`${table}\` (${keys.map((k) => `\`${k}\``).join(',')}) VALUES (${keys.map(() => '?').join(',')})`;
  const r = await exec(sql, keys.map((k) => obj[k]));
  return r.insertId;
}

const UP = (s?: string) => (s ? s.toUpperCase() : s);
const rateType = (s?: string) => {
  const t = (s ?? '').toLowerCase();
  if (t.includes('custom')) return 'CUSTOMS';
  if (t.includes('clos')) return 'CLOSING';
  if (t.includes('settle')) return 'SETTLEMENT';
  if (t.includes('forward')) return 'FORWARD';
  return 'ACCOUNTING';
};

async function wipeTenant() {
  // Truncate every table in the ACTIVE tenant database (routed via runWithTenant).
  await exec('SET FOREIGN_KEY_CHECKS = 0');
  const tables = await q<{ TABLE_NAME: string }>(
    `SELECT TABLE_NAME FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME <> 'schema_migration'`,
  );
  for (const t of tables) await exec(`TRUNCATE TABLE \`${t.TABLE_NAME}\``);
  await exec('SET FOREIGN_KEY_CHECKS = 1');
}

async function wipeControl() {
  await controlPool.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const t of ['refresh_token', 'user_role', 'user_entity_access', 'sod_conflict', 'role_permission', 'permission', 'role', 'app_user', 'tenant']) {
    await controlPool.query(`TRUNCATE TABLE \`${t}\``);
  }
  await controlPool.query('SET FOREIGN_KEY_CHECKS = 1');
}

async function seedReference() {
  const countries: [string, string, string][] = [
    ['IN', 'India', 'INR'], ['KR', 'Korea, Republic of', 'KRW'], ['DE', 'Germany', 'EUR'],
    ['AE', 'United Arab Emirates', 'AED'], ['CN', 'China', 'CNY'], ['SE', 'Sweden', 'SEK'],
    ['IT', 'Italy', 'EUR'], ['NL', 'Netherlands', 'EUR'], ['US', 'United States', 'USD'],
    ['GB', 'United Kingdom', 'GBP'], ['JP', 'Japan', 'JPY'], ['SG', 'Singapore', 'SGD'],
    ['FR', 'France', 'EUR'], ['AU', 'Australia', 'AUD'],
  ];
  for (const [code, name, ccy] of countries) await ins('country', { code, name, default_ccy: ccy });

  const ccys: [string, string, number][] = [
    ['INR', 'Indian Rupee', 2], ['USD', 'US Dollar', 2], ['EUR', 'Euro', 2], ['GBP', 'Pound Sterling', 2],
    ['JPY', 'Japanese Yen', 0], ['SGD', 'Singapore Dollar', 2], ['AED', 'UAE Dirham', 2],
    ['CNY', 'Chinese Yuan', 2], ['SEK', 'Swedish Krona', 2], ['KRW', 'Korean Won', 0], ['AUD', 'Australian Dollar', 2],
  ];
  for (const [code, name, dp] of ccys) await ins('currency', { code, name, precision_dp: dp });

  const ports: [string, string, string, string][] = [
    ['KRPUS', 'Busan', 'KR', 'SEA'], ['INNSA', 'Nhava Sheva (JNPT)', 'IN', 'SEA'],
    ['INBOM', 'Mumbai (Air)', 'IN', 'AIR'], ['DEHAM', 'Hamburg', 'DE', 'SEA'],
    ['SEGOT', 'Gothenburg', 'SE', 'SEA'], ['AEJEA', 'Jebel Ali', 'AE', 'SEA'], ['CNNGB', 'Ningbo', 'CN', 'SEA'],
  ];
  for (const [code, name, cc, mode] of ports) await ins('port', { code, name, country_code: cc, mode });

  const incoterms: [string, string, string, string, number, number, string, string][] = [
    ['EXW', 'Ex Works', 'ANY', 'At seller premises', 0, 0, 'BUYER', 'atCollection'],
    ['FCA', 'Free Carrier', 'ANY', 'On handover to carrier', 0, 0, 'BUYER', 'onHandover'],
    ['FOB', 'Free On Board', 'SEA', 'On board at port of loading', 0, 0, 'BUYER', 'onBoard'],
    ['CFR', 'Cost and Freight', 'SEA', 'On board at port of loading', 1, 0, 'BUYER', 'onBoard'],
    ['CIF', 'Cost, Insurance and Freight', 'SEA', 'On board at port of loading', 1, 1, 'BUYER', 'onBoard'],
    ['CPT', 'Carriage Paid To', 'ANY', 'On handover to first carrier', 1, 0, 'BUYER', 'onHandover'],
    ['CIP', 'Carriage and Insurance Paid To', 'ANY', 'On handover to first carrier', 1, 1, 'BUYER', 'onHandover'],
    ['DAP', 'Delivered At Place', 'ANY', 'At named place, not unloaded', 1, 0, 'BUYER', 'atDelivery'],
    ['DPU', 'Delivered At Place Unloaded', 'ANY', 'At named place, unloaded', 1, 0, 'BUYER', 'atDelivery'],
    ['DDP', 'Delivered Duty Paid', 'ANY', 'At named place, cleared', 1, 0, 'SELLER', 'atDelivery'],
  ];
  for (const [code, name, modes, risk, frt, ins2, cleared, own] of incoterms) {
    await ins('incoterm', { code, name, modes, risk_transfer: risk, freight_in_value: frt, insurance_by_seller: ins2, import_cleared_by: cleared, ownership_event: own });
  }

  const uoms: [string, string, string][] = [
    ['PCS', 'Pieces', 'count'], ['EA', 'Each', 'count'], ['NOS', 'Numbers', 'count'], ['SET', 'Set', 'count'],
    ['KG', 'Kilogram', 'mass'], ['MT', 'Metric tonne', 'mass'], ['LTR', 'Litre', 'volume'],
    ['CBM', 'Cubic metre', 'volume'], ['BOX', 'Box', 'count'], ['ROLL', 'Roll', 'count'],
  ];
  for (const [code, name, cls] of uoms) await ins('uom', { code, name, uom_class: cls });
}

let schemeId: Record<string, number> = {};
async function seedSchemes() {
  const rows: any[] = [
    { code: 'EPCG', name: 'Export Promotion Capital Goods', scheme_family: 'CAPITAL_AUTH', obligation_type: 'MULTIPLE_OF_DUTY_SAVED', obligation_multiple: 6, obligation_months: 72, recognition_point: 'ON_SANCTION' },
    { code: 'AA', name: 'Advance Authorisation', scheme_family: 'INPUT_AUTH', obligation_type: 'VALUE', obligation_months: 18, min_value_addition_pct: 15, recognition_point: 'ON_SANCTION' },
    { code: 'MOOWR', name: 'Manufacture in Bonded Warehouse (Section 65)', scheme_family: 'BONDED', obligation_type: 'NONE', recognition_point: 'ON_RECEIPT' },
    { code: 'RODTEP', name: 'Remission of Duties and Taxes on Exported Products', scheme_family: 'REBATE', obligation_type: 'NONE', recognition_point: 'ON_SANCTION' },
    { code: 'DRAWBACK', name: 'Duty Drawback', scheme_family: 'DRAWBACK', obligation_type: 'NONE', recognition_point: 'ON_SANCTION' },
  ];
  for (const r of rows) {
    const id = await ins('scheme', { ...r, valid_from: '2020-04-01' });
    schemeId[r.code] = id;
  }
}

async function seedTenancy(t: { code: string; name: string; entityCode: string; iec: string; pan: string }) {
  await ins('legal_entity', {
    id: ENTITY, code: t.entityCode, name: t.name, country_code: 'IN',
    functional_ccy: 'INR', group_ccy: 'INR', gaap_framework: 'IND_AS', iec: t.iec, pan: t.pan,
  });
  await ins('site', { id: 1, entity_id: ENTITY, code: 'PUN1', name: 'Pune Unit I', gstin: '27AABCH1234K1Z8', state_code: '27', is_bonded: 0 });
  await ins('site', { id: 2, entity_id: ENTITY, code: 'PUN2', name: 'Pune Unit II (bonded)', gstin: '27AABCH1234K1Z8', state_code: '27', is_bonded: 1, bond_licence: 'MOOWR/2025/0009' });

  for (let i = 0; i < 4; i += 1) {
    const [code, name, basis, gaap] = [['PRIMARY', 'Primary book (Ind AS)', 'PRIMARY', 'IND_AS'], ['TAX', 'Tax book', 'TAX', 'TAX'], ['GROUP', 'Group reporting (IFRS)', 'GROUP', 'IFRS'], ['MEMO', 'Memorandum', 'MEMORANDUM', 'NA']][i];
    await ins('book', { id: i + 1, entity_id: ENTITY, code, name, basis, gaap });
  }
  // periods for the primary book
  const periods: [number, string, string, string, string][] = [
    [202604, '2026-27', '2026-04-01', '2026-04-30', 'HARD_CLOSED'],
    [202605, '2026-27', '2026-05-01', '2026-05-31', 'HARD_CLOSED'],
    [202606, '2026-27', '2026-06-01', '2026-06-30', 'SOFT_CLOSED'],
    [202607, '2026-27', '2026-07-01', '2026-07-31', 'OPEN'],
    [202608, '2026-27', '2026-08-01', '2026-08-31', 'OPEN'],
  ];
  for (const [key, fy, s, e, st] of periods) {
    await ins('accounting_period', { entity_id: ENTITY, book_id: 1, period_key: key, fiscal_year: fy, starts_on: s, ends_on: e, status: st });
  }
}

/**
 * Seed the CONTROL database: the global RBAC model, the tenant registry, and a
 * full set of demo users FOR EACH tenant (username is unique per tenant, so both
 * businesses can have their own `controller`, `admin`, …). Returns each tenant's
 * name→userId map for denormalising voucher actor names in the tenant seed.
 */
async function seedControl(): Promise<Record<string, Record<string, number>>> {
  await wipeControl();
  const roleId: Record<string, number> = {};
  for (const r of ROLES) roleId[r.code] = await cins('role', { code: r.code, name: r.name, description: r.description });
  const permId: Record<string, number> = {};
  for (const p of allPermissions()) permId[p.code] = await cins('permission', { code: p.code, resource: p.resource, action: p.action });
  for (const r of ROLES) for (const p of r.perms) await cexec('INSERT INTO role_permission (role_id, permission_id) VALUES (?, ?)', [roleId[r.code], permId[p]]);
  for (const s of SOD) await cins('sod_conflict', { code: s.code, role_a_id: roleId[s.a], role_b_id: roleId[s.b], risk: s.risk });

  const hash = bcrypt.hashSync(DEMO_PASSWORD, config.auth.bcryptRounds);
  const userIdByTenant: Record<string, Record<string, number>> = {};
  for (const t of TENANTS) {
    const tenantId = await cins('tenant', { code: t.code, name: t.name, db_name: t.db, status: 'ACTIVE' });
    const userId: Record<string, number> = {};
    for (const u of SEED_USERS) {
      const id = await cins('app_user', { tenant_id: tenantId, username: u.username, email: `${u.username}@${t.code.toLowerCase()}.example`, full_name: u.fullName, password_hash: hash, is_external: u.external ? 1 : 0 });
      userId[u.username] = id;
      await cexec('INSERT INTO user_role (user_id, role_id) VALUES (?, ?)', [id, roleId[u.role]]);
      await cexec('INSERT INTO user_entity_access (user_id, entity_id) VALUES (?, ?)', [id, ENTITY]);
    }
    userIdByTenant[t.code] = userId;
  }
  return userIdByTenant;
}

// map a person's display name (as used in seed vouchers/tasks) to a user id
function nameToUser(userId: Record<string, number>): Record<string, number> {
  const byName: Record<string, string> = {
    'S. Menon': 'controller', 'A. Kulkarni': 'imports', 'R. Iyer': 'exports', 'D. Rao': 'compliance',
    'M. Shah': 'costing', 'P. Nair': 'accounts', 'K. Bose': 'treasury', 'V. Menon': 'tradefinance',
    'G. Pillai': 'tax', 'N. Fernandes': 'audit',
  };
  const out: Record<string, number> = {};
  for (const [name, uname] of Object.entries(byName)) if (userId[uname]) out[name] = userId[uname];
  return out;
}

let accountId: Record<string, number> = {};
async function seedAccounts() {
  for (const a of S.accounts) {
    const id = await ins('gl_account', {
      entity_id: ENTITY, code: a.code, name: a.name, account_class: UP(a.class), account_type: UP(a.type),
      account_group: a.group, schedule_iii_group: a.scheduleIIIGroup, cash_flow_class: UP(a.cashFlow) ?? 'NONE',
      subledger: a.subledger ? UP(a.subledger) : 'NONE', is_monetary: a.monetary ? 1 : 0,
      manual_posting_allowed: a.manualPostingAllowed ? 1 : 0, mandatory_dimensions: (a.mandatoryDimensions ?? []).join(','),
      recon_frequency: a.reconFrequency ? UP(a.reconFrequency) : 'NONE', currency: a.currency ?? null, valid_from: '2020-04-01',
    });
    accountId[a.code] = id;
    // rollup row that the trial balance reads
    await ins('account_period_balance', {
      entity_id: ENTITY, book_id: 1, account_id: id, period_key: config.server.defaultPeriodKey,
      opening_dr: a.openingDr, opening_cr: a.openingCr, period_dr: a.periodDr, period_cr: a.periodCr, line_count: 0,
    });
  }
}

async function seedRules() {
  for (const [key, a] of Object.entries(ACCOUNT_DETERMINATION)) {
    if (!accountId[a.code]) continue;
    await ins('account_determination', { entity_id: ENTITY, account_key: key, qualifier: '*', account_id: accountId[a.code], valid_from: '2020-04-01' });
  }
  for (const r of POSTING_RULES) {
    const id = await ins('posting_rule', {
      entity_id: ENTITY, code: r.code, version: r.version, business_event: r.event, voucher_type_code: r.voucherType,
      book_code: UP(r.book) ?? 'PRIMARY', description: r.description, standard_ref: r.standardRef ?? null,
      gaap_dependent: r.standardRef && /Ind AS|IFRS/.test(r.standardRef) ? 1 : 0, effective_from: r.effectiveFrom, test_result: 'PASSED',
    });
    let seq = 1;
    for (const l of r.lines) {
      await ins('posting_rule_line', {
        rule_id: id, seq_no: seq, dr_cr: UP(l.drCr), account_key: l.accountKey, amount_key: l.amountKey,
        tax_code: l.taxCode ?? null, condition_expr: l.condition ?? null, branch_note: l.treatmentBranch ?? null,
      });
      seq += 1;
    }
  }
}

let partyId: Record<string, number> = {};
let partyByName: Record<string, number> = {};
async function seedParties() {
  for (const p of S.parties) {
    const id = await ins('trade_party', {
      entity_id: ENTITY, contact_code: p.contactCode, name: p.name, legal_name: p.legalName, country_code: p.country,
      currency: p.currency, gstin: p.gstin ?? null, pan: p.pan ?? null, iec: p.iec ?? null, ledger_group: p.ledgerGroup ?? null,
      default_incoterm: p.incoterm ?? null, default_payment_term: p.paymentTerm ?? null, is_related_party: p.relatedParty ? 1 : 0,
      bank_verified: p.bankVerified ? 1 : 0, screening_status: UP(p.screeningStatus) === 'CLEAR' ? 'CLEAR' : UP(p.screeningStatus) === 'REVIEW' ? 'REVIEW' : 'MATCH',
      screened_at: p.screenedOn ? `${p.screenedOn} 09:00:00` : null,
    });
    partyId[p.id] = id;
    partyByName[p.name] = id;
    for (const role of p.roles) await exec('INSERT INTO trade_party_role (party_id, role) VALUES (?, ?)', [id, UP(role)]);
  }
  // correspondent banks referenced by instruments (parties with role BANK)
  for (const [name, cc] of [['State Bank of India, Mumbai', 'IN'], ['Woori Bank, Seoul', 'KR'], ['Commerzbank AG, Hamburg', 'DE'], ['HDFC Bank, Mumbai', 'IN']] as [string, string][]) {
    const id = await ins('trade_party', { entity_id: ENTITY, contact_code: `BANK-${name.slice(0, 6).toUpperCase().replace(/\W/g, '')}`, name, legal_name: name, country_code: cc, currency: 'INR', screening_status: 'CLEAR' });
    partyByName[name] = id;
    await exec('INSERT INTO trade_party_role (party_id, role) VALUES (?, ?)', [id, 'BANK']);
  }
}

let itemId: Record<string, number> = {};
async function seedItems() {
  const seen: Record<string, any> = {};
  for (const o of S.orders) for (const l of o.lines) if (!seen[l.itemCode]) seen[l.itemCode] = { code: l.itemCode, description: l.description, uom: l.uom, hs: l.hsCode, nw: l.netWeightKg };
  for (const d of S.declarations) for (const l of d.lines) if (!seen[l.itemCode]) seen[l.itemCode] = { code: l.itemCode, description: l.description, uom: l.stockUom, hs: l.hsCode, nw: l.netWeightKg };
  for (const it of Object.values(seen)) {
    const id = await ins('item', { entity_id: ENTITY, item_code: it.code, description: it.description, stock_uom: it.uom === 'PCS' ? 'EA' : it.uom, valuation_method: 'WAVG', net_weight_kg: it.nw ?? null });
    itemId[it.code] = id;
  }
}

let chargeId: Record<string, number> = {};
async function seedCharges() {
  const charges: [string, string, string, string, string][] = [
    ['FRT-OCN', 'Ocean freight', 'FREIGHT', 'CAPITALISE', 'GROSS_WEIGHT'],
    ['FRT-INL', 'Inland freight to site', 'INLAND', 'CAPITALISE', 'GROSS_WEIGHT'],
    ['THC', 'Terminal handling and port charges', 'PORT', 'CAPITALISE', 'CONTAINER'],
    ['DUTY', 'Customs duty and levies', 'DUTY', 'CAPITALISE', 'DIRECT'],
    ['IGST-IMP', 'Integrated tax on import', 'DUTY', 'RECOVERABLE', 'DIRECT'],
    ['BRK', 'Customs brokerage fee', 'BROKERAGE', 'CAPITALISE', 'EQUAL'],
    ['INS', 'Marine insurance premium', 'INSURANCE', 'CAPITALISE', 'VALUE'],
    ['DET', 'Demurrage and detention', 'PENALTY', 'EXPENSE', 'DIRECT'],
  ];
  for (const [code, name, cat, treat, basis] of charges) {
    chargeId[code] = await ins('charge_type', { entity_id: ENTITY, code, name, category: cat, treatment: treat, allocation_basis: basis, credit_eligible: treat === 'RECOVERABLE' ? 1 : 0, tolerance_pct: 5 });
  }
}

let voucherTypeId: Record<string, number> = {};
async function seedVoucherTypes() {
  for (const v of S.voucherTypes) {
    const id = await ins('voucher_type', {
      entity_id: ENTITY, code: v.code, name: v.name, document_class: UP(v.documentClass), statutory_series: v.statutorySeries ? 1 : 0,
      posts_on: UP(v.postsOn), reversible: v.reversible ? 1 : 0, required_evidence: (v.requiredEvidence ?? []).join('; '),
      approval_matrix: v.approvalMatrix ?? null, print_format: v.printFormat ?? null, retention_years: v.retentionYears ?? 8,
      books: (v.books ?? ['Primary']).map((b) => UP(b)).join(','),
    });
    voucherTypeId[v.code] = id;
  }
  // number series per voucher type, continuing past the seeded documents
  for (const v of S.voucherTypes) {
    const used = S.vouchers.filter((x) => x.voucherType === v.code).map((x) => Number(x.number.split('/').pop()) || 0);
    const next = (used.length ? Math.max(...used) : 0) + 1;
    await ins('number_series', { entity_id: ENTITY, voucher_type_id: voucherTypeId[v.code], fiscal_year: '2026-27', prefix: `${v.code}/2026-27/`, width: 5, next_no: next });
  }
}

/** Reset the per-run id maps so seeding a second tenant doesn't see the first's. */
function resetMaps() {
  schemeId = {}; accountId = {}; partyId = {}; partyByName = {}; itemId = {}; chargeId = {}; voucherTypeId = {};
  orderId = {}; shipmentId = {}; shipmentByNo = {}; declarationId = {}; declarationByNo = {}; licenceId = {}; instrumentId = {}; costSheetId = {};
}

/** Seed one tenant's business database. Runs inside runWithTenant so every
 *  q()/exec() call routes to THIS tenant's database. */
async function seedTenant(t: typeof TENANTS[number], userId: Record<string, number>) {
  const nameUser = nameToUser(userId);
  await runWithTenant(t.db, async () => {
    resetMaps();
    // eslint-disable-next-line no-console
    console.log(`  [${t.code}] wiping ${t.db}…`);
    await wipeTenant();
    await seedReference();
    await seedSchemes();
    await seedTenancy(t);
    await seedAccounts();
    await seedRules();
    await seedParties();
    await seedItems();
    await seedCharges();
    await seedVoucherTypes();
    await seedTrade(userId, nameUser);
    await seedAccountingDocs(userId, nameUser);
    await seedOpsQueues(userId);
    await seedOperations();
    await seedOperations2();
    await verify(t.code);
  });
}

export async function seed() {
  // eslint-disable-next-line no-console
  console.log('  control plane (tenants, users, RBAC)…');
  const userIdByTenant = await seedControl();
  for (const t of TENANTS) {
    // eslint-disable-next-line no-console
    console.log(`  seeding tenant ${t.name} → ${t.db}`);
    await seedTenant(t, userIdByTenant[t.code]);
  }
}

// ---- trade documents ------------------------------------------------------
let orderId: Record<string, number> = {};
let shipmentId: Record<string, number> = {};
let shipmentByNo: Record<string, number> = {};
let declarationId: Record<string, number> = {};
let declarationByNo: Record<string, number> = {};
let licenceId: Record<string, number> = {};
let instrumentId: Record<string, number> = {};
let costSheetId: Record<string, number> = {};

async function seedTrade(userId: Record<string, number>, nameUser: Record<string, number>) {
  // instruments first (orders reference them)
  for (const inst of S.instruments) {
    const typeIsImport = /Import/i.test(inst.type);
    const id = await ins('instrument', {
      entity_id: ENTITY, instrument_no: inst.number, instrument_type: typeIsImport ? 'LC_IMPORT' : 'LC_EXPORT',
      governing_rules: inst.governingRules ?? null,
      issuing_bank_id: partyByName[inst.issuingBank] ?? null, issuing_bank_name: inst.issuingBank,
      advising_bank_id: inst.advisingBank ? partyByName[inst.advisingBank] ?? null : null, advising_bank_name: inst.advisingBank ?? null,
      applicant_party_id: partyByName[inst.applicant] ?? null, applicant_name: inst.applicant,
      beneficiary_party_id: partyByName[inst.beneficiary] ?? null, beneficiary_name: inst.beneficiary,
      currency: inst.currency, face_value: inst.value, tolerance_pct: inst.tolerancePct, drawn_value: inst.drawnValue,
      available_value: inst.availableValue, charges_to_date: inst.charges, latest_shipment_date: inst.latestShipmentDate,
      expiry_date: inst.expiryDate, presentation_days: inst.presentationDays, payment_terms: inst.paymentTerms,
      status: 'ISSUED', type_label: inst.type, status_label: inst.status, payment_note: inst.paymentTerms,
    });
    instrumentId[inst.id] = id;
    let seq = 1;
    for (const d of inst.documentRequirements) {
      await ins('instrument_doc_requirement', { instrument_id: id, entity_id: ENTITY, seq, doc_type: d.doc, originals: d.originals, copies: d.copies, issuer: d.issuer ?? null, required_wording: d.wording ?? null, is_held: d.held ? 1 : 0 });
      seq += 1;
    }
    for (const dc of inst.discrepancies ?? []) {
      await ins('instrument_discrepancy', { instrument_id: id, entity_id: ENTITY, code: dc.code, description: dc.description, disposition: 'OPEN', outcome: dc.disposition ?? null });
    }
  }

  // orders
  for (const o of S.orders) {
    const id = await ins('trade_order', {
      entity_id: ENTITY, site_id: 1, order_no: o.number, direction: UP(o.type), order_date: o.date, party_id: partyId[o.partyId],
      currency: o.currency, incoterm: o.incoterm, named_place: o.namedPlace, transport_mode: o.mode,
      port_of_loading: o.portOfLoading, port_of_discharge: o.portOfDischarge, payment_term: o.paymentTerm,
      instrument_id: o.instrumentRef ? instrumentId[o.instrumentRef] ?? null : null,
      shipment_window_from: o.shipmentWindowFrom ?? null, shipment_window_to: o.shipmentWindowTo ?? null,
      zero_rating_route: o.zeroRatingRoute ?? 'NA', order_value: o.value, status: 'APPROVED',
    });
    orderId[o.id] = id;
    let ln = 1;
    for (const l of o.lines) {
      await ins('trade_order_line', {
        order_id: id, entity_id: ENTITY, line_no: ln, item_id: itemId[l.itemCode] ?? null, item_code: l.itemCode, description: l.description,
        hs_code: l.hsCode, qty: l.qty, uom: l.uom, unit_price: l.unitPrice, line_value: Math.round(l.qty * l.unitPrice * 100) / 100,
        currency: l.currency, origin_country: l.originCountry ?? null, net_weight_kg: l.netWeightKg ?? 0,
        preference_agreement: l.preferenceIntent ?? null, scheme_intent: (l.schemeIntent ?? []).join(','),
        est_landed_unit_cost: l.estLandedCost ? Math.round((l.estLandedCost / l.qty) * 1e6) / 1e6 : null,
      });
      ln += 1;
    }
  }

  // shipments (+ containers, milestones, order links)
  for (const s of S.shipments) {
    const id = await ins('shipment', {
      entity_id: ENTITY, site_id: 1, shipment_no: s.number, direction: UP(s.direction), transport_mode: s.mode, party_id: partyId[s.partyId],
      forwarder_id: partyByName[s.forwarder] ?? null, broker_id: partyByName[s.broker] ?? null, carrier: s.carrier ?? null,
      vessel: s.vessel ?? null, voyage: s.voyage ?? null, transport_doc_no: s.blNumber ?? null, transport_doc_date: s.blDate ?? null,
      transport_doc_type: s.mode === 'AIR' ? 'AWB' : 'BL', port_of_loading: s.portOfLoading, port_of_discharge: s.portOfDischarge,
      incoterm: s.incoterm, etd: s.etd ?? null, atd: s.atd ?? null, eta: s.eta ?? null, ata: s.ata ?? null,
      stage: mapStage(s.stage), stage_label: s.stage, status: s.status, currency: s.currency, goods_value: s.value,
      gross_weight_kg: s.grossKg ?? 0, net_weight_kg: s.netKg ?? 0, container_count: s.containers.length,
      docs_required: s.docsRequired, docs_received: s.docsReceived, open_exceptions: s.exceptions.filter((e) => e.open).length,
      free_time_expires_on: s.containers.find((c) => c.freeFrom) ? addDays(s.containers[0].freeFrom, s.containers[0].freeDays) : null,
    });
    shipmentId[s.id] = id;
    shipmentByNo[s.number] = id;
    for (const oid of s.orderIds) if (orderId[oid]) await exec('INSERT INTO shipment_order (shipment_id, order_id) VALUES (?, ?)', [id, orderId[oid]]);
    for (const c of s.containers) {
      await ins('container', { shipment_id: id, entity_id: ENTITY, container_no: c.number, container_type: c.type, seal_no: c.sealNumber, tare_kg: c.tareKg, gross_kg: c.grossKg, free_from: c.freeFrom ?? null, free_days: c.freeDays, days_used: c.daysUsed, projected_charge: c.projectedCharge });
    }
    let seq = 1;
    for (const m of s.milestones) {
      await ins('shipment_milestone', { shipment_id: id, entity_id: ENTITY, seq, milestone_key: m.key, label: m.label, planned_on: m.planned ?? null, revised_on: m.revised ?? null, actual_on: m.actual ?? null, source: 'MANUAL' });
      seq += 1;
    }
  }

  // declarations (+ lines + levies + entitlements)
  for (const d of S.declarations) {
    const period = pk(d.filedOn);
    const id = await ins('declaration', {
      period_key: period, entity_id: ENTITY, site_id: 1, declaration_no: d.number, declaration_type: d.type.slice(0, 40), type_label: d.type,
      direction: UP(d.direction), jurisdiction: 'IN', shipment_id: shipmentId[d.shipmentId] ?? null, party_id: partyId[d.partyId],
      port_code: d.portCode, filing_channel: 'ICEGATE', authority_ref: d.authorityRef ?? null, declaration_date: d.filedOn ?? '2026-07-01',
      filed_on: d.filedOn ?? null, cleared_on: d.clearedOn ?? null, paid_on: d.paidOn ?? null, leo_ref: d.leoRef ?? null, egm_matched: d.egmMatched ? 1 : 0,
      status: mapDeclStatus(d.status), status_label: d.status, is_provisional: d.provisional ? 1 : 0, currency: d.currency,
      statutory_fx_rate: d.statutoryFxRate, accounting_fx_rate: d.statutoryFxRate, assessable_value: d.assessableValue,
      duty_total: d.dutyTotal, duty_recoverable: d.dutyRecoverable, duty_inventoriable: d.dutyInventoriable,
      duty_assessed: d.assessedDuty ?? null, duty_saved: d.lines.reduce((a, l) => a + (l.dutySaved || 0), 0),
      duty_blocked: d.lines.reduce((a, l) => a + (l.dutyForegoneBlocked || 0), 0), fob_value: d.direction === 'export' ? d.assessableValue : 0,
      error_count: (d.validations ?? []).filter((v) => v.severity === 'error').length, warning_count: (d.validations ?? []).filter((v) => v.severity === 'warning').length,
      computed_at: '2026-07-07 10:00:00',
    });
    declarationId[d.id] = id;
    declarationByNo[d.number] = id;
    let ln = 1;
    for (const l of d.lines) {
      const lid = await ins('declaration_line', {
        period_key: period, declaration_id: id, entity_id: ENTITY, line_no: ln, item_id: itemId[l.itemCode] ?? null, item_code: l.itemCode,
        description: l.description, hs_code: l.hsCode, qty_statutory: l.qty, statutory_uom: l.statutoryUom, qty_stock: l.qty * (l.conversion || 1),
        stock_uom: l.stockUom, uom_conversion: l.conversion || 1, unit_price_fc: l.qty ? Math.round((l.invoiceValueFc / l.qty) * 1e6) / 1e6 : 0,
        invoice_value_fc: l.invoiceValueFc, freight_fc: l.freightFc || 0, insurance_fc: l.insuranceFc || 0, currency: l.currency,
        assessable_value: l.assessableValue, origin_country: l.originCountry ?? null, preference_agreement: l.preferenceAgreement ?? null,
        preference_claimed: l.preferenceAgreement ? 1 : 0, preference_proof_ref: l.preferenceProofRef ?? null,
        duty_total: l.levies.reduce((a, x) => a + x.amount, 0), duty_recoverable: l.levies.filter((x) => x.recoverable).reduce((a, x) => a + x.amount, 0),
        duty_inventoriable: l.levies.filter((x) => !x.recoverable).reduce((a, x) => a + x.amount, 0), duty_saved: l.dutySaved || 0,
        duty_blocked: l.dutyForegoneBlocked || 0, net_weight_kg: l.netWeightKg || 0,
      });
      let sq = 1;
      for (const lv of l.levies) {
        await ins('declaration_levy', {
          period_key: period, declaration_line_id: lid, declaration_id: id, entity_id: ENTITY, seq: sq, levy_code: lv.code, levy_name: lv.name,
          base_expression: lv.basis, base_amount: lv.base, rate_type: 'AD_VALOREM', rate_pct: lv.rate, amount: lv.amount,
          rate_source: (lv.rateSource || '').toLowerCase().includes('pref') ? 'PREFERENCE' : (lv.rateSource || '').toLowerCase().includes('exempt') ? 'EXEMPTION' : 'SCHEDULE',
          rate_source_ref: lv.exemptionRef ?? null, is_recoverable: lv.recoverable ? 1 : 0, gl_account_id: null,
        });
        sq += 1;
      }
      ln += 1;
    }
    for (const v of d.validations ?? []) {
      await ins('declaration_validation', { declaration_id: id, entity_id: ENTITY, rule_id: v.rule, severity: UP(v.severity), field_ref: v.field ?? null, line_no: v.lineNo ?? null, message: v.message, remedy: v.remedy });
    }
    for (const ent of d.entitlements ?? []) {
      await ins('entitlement_claim', {
        entity_id: ENTITY, scheme_id: schemeId[ent.scheme === 'RoDTEP' ? 'RODTEP' : ent.scheme === 'Drawback' ? 'DRAWBACK' : 'RODTEP'] ?? schemeId.RODTEP,
        claim_no: ent.id, declaration_id: id, declaration_no: ent.declarationNumber, declaration_date: d.filedOn ?? null,
        fob_value: ent.fobValue, rate_pct: ent.ratePct, cap_amount: ent.cap ?? null, computed_amount: ent.computed, claimed_amount: ent.claimed,
        sanctioned_amount: ent.sanctioned ?? null, received_amount: ent.received ?? null, shortfall_amount: ent.claimed - (ent.sanctioned ?? ent.claimed),
        shortfall_cause: ent.shortfallCause ?? null, scrip_ref: ent.scripRef ?? null, stage: mapEntStage(ent.stage),
        recognition_point: /sanction/i.test(ent.recognitionPoint) ? 'AT_SANCTION' : 'AT_EXPORT', is_recognised: ent.recognised ? 1 : 0, filed_on: ent.filedOn ?? null,
      });
    }
  }

  // licences (+ blocks, utilisation, fulfilment, conditions)
  for (const l of S.licences) {
    const sc = l.scheme === 'EPCG' ? 'EPCG' : l.scheme.startsWith('Advance') ? 'AA' : 'MOOWR';
    const fulfilled = l.fulfilment.reduce((a, f) => a + f.value, 0);
    const id = await ins('licence', {
      entity_id: ENTITY, scheme_id: schemeId[sc], licence_no: l.number, issued_on: l.issuedOn, import_valid_to: l.importValidTo,
      export_valid_to: l.exportValidTo, status: mapLicStatus(l.status), scheme_label: l.scheme, obligation_label: l.obligationType, status_label: l.status,
      cif_entitlement: l.utilisation.reduce((a, u) => a + u.value, 0), cif_utilised: l.utilisation.reduce((a, u) => a + u.value, 0),
      duty_saved: l.dutySaved, obligation_type: l.obligationAmount > 0 ? (l.minValueAddition ? 'VALUE_ADDITION' : 'VALUE') : 'NONE',
      obligation_amount: l.obligationAmount, obligation_fulfilled: fulfilled, average_obligation: l.averageObligation ?? null,
      average_maintained: l.averageMaintained === undefined ? null : l.averageMaintained ? 1 : 0, min_value_addition_pct: l.minValueAddition ?? null,
      bg_waived: l.bgWaived ? 1 : 0, exposure_duty: l.status.includes('risk') ? Math.round(l.dutySaved * 0.15) : 0, exposure_interest: 0,
      contingent_disclosed: l.obligationAmount > 0 ? 1 : 0,
    });
    licenceId[l.id] = id;
    let bn = 1;
    for (const b of l.blocks) {
      await ins('licence_block', { licence_id: id, entity_id: ENTITY, block_no: bn, label: b.label, share_pct: b.sharePct, due_on: b.dueOn, obligation_amount: 0, fulfilled_amount: b.fulfilled, status: b.fulfilled >= 100 ? 'MET' : 'OPEN' });
      bn += 1;
    }
    for (const u of l.utilisation) {
      await ins('licence_utilisation', { licence_id: id, entity_id: ENTITY, entry_date: u.date, declaration_id: declarationByNo[u.ref] ?? null, reference: u.ref, description: u.description, qty: u.qty ?? null, value: u.value, running_value: u.value });
    }
    for (const f of l.fulfilment) {
      await ins('licence_fulfilment', { licence_id: id, entity_id: ENTITY, entry_date: f.date, declaration_id: declarationByNo[f.ref] ?? null, reference: f.ref, description: f.description, fob_value: f.value, counted_value: f.value, running_value: f.value, evidence_complete: f.evidenceComplete ? 1 : 0 });
    }
    for (const c of l.conditions) {
      await ins('licence_condition', { licence_id: id, entity_id: ENTITY, name: c.name, detail: c.detail, is_satisfied: c.satisfied ? 1 : 0 });
    }
  }

  // cost sheets (+ lines)
  for (const cs of S.costSheets) {
    const est = cs.lines.reduce((a, l) => a + l.estimate, 0);
    const acc = cs.lines.reduce((a, l) => a + l.accrued, 0);
    const act = cs.lines.reduce((a, l) => a + (l.actual ?? 0), 0);
    const invoicedVar = cs.lines.filter((l) => l.actual != null).reduce((a, l) => a + (l.actual! - l.estimate), 0);
    const uninvoiced = cs.lines.filter((l) => l.actual == null).reduce((a, l) => a + l.accrued, 0);
    const id = await ins('cost_sheet', {
      entity_id: ENTITY, cost_sheet_no: cs.id, shipment_id: shipmentId[cs.shipmentId], declaration_id: null, direction: 'IMPORT', currency: 'INR',
      goods_value: cs.goodsValue, total_estimate: est, total_accrued: acc, total_actual: act, variance_invoiced: invoicedVar, uninvoiced_accrual: uninvoiced,
      capitalised_amount: cs.lines.filter((l) => l.treatment === 'capitalise').reduce((a, l) => a + (l.actual ?? l.accrued), 0),
      expensed_amount: cs.lines.filter((l) => l.treatment === 'expense').reduce((a, l) => a + (l.actual ?? l.accrued), 0),
      recoverable_amount: cs.lines.filter((l) => l.treatment === 'recoverable').reduce((a, l) => a + (l.actual ?? l.accrued), 0),
      allocation_basis: 'VALUE', stock_on_hand_pct: cs.stockOnHandPct, status: 'PART_ACTUAL',
      tolerance_breaches: cs.lines.filter((l) => l.actual != null && l.estimate > 0 && Math.abs(l.actual! - l.estimate) / l.estimate * 100 > l.tolerancePct).length,
    });
    costSheetId[cs.id] = id;
    let ln = 1;
    for (const l of cs.lines) {
      const breached = l.actual != null && l.estimate > 0 && Math.abs(l.actual - l.estimate) / l.estimate * 100 > l.tolerancePct;
      await ins('cost_line', {
        cost_sheet_id: id, entity_id: ENTITY, line_no: ln, charge_type_id: chargeId[l.chargeCode] ?? chargeId.DUTY, provider_id: l.providerId ? partyId[l.providerId] ?? null : null,
        basis: UP(l.basis) === 'GROSSWEIGHT' ? 'GROSS_WEIGHT' : UP(l.basis), treatment: UP(l.treatment), currency: l.currency, fx_rate: l.fxRate,
        estimate_fc: l.estimate, estimate: l.estimate, accrued: l.accrued, actual_fc: l.actual ?? null, actual: l.actual ?? null, invoice_ref: l.invoiceRef ?? null,
        tolerance_pct: l.tolerancePct, tolerance_breached: breached ? 1 : 0,
        status: l.actual != null ? (breached ? 'DISPUTED' : 'MATCHED') : l.accrued > 0 ? 'ACCRUED' : 'ESTIMATED', status_label: l.status,
      });
      ln += 1;
    }
  }
}

// ---- accounting documents (vouchers + posting lines + evidence) -----------
async function seedAccountingDocs(userId: Record<string, number>, nameUser: Record<string, number>) {
  for (const v of S.vouchers) {
    const period = pk(v.date);
    const vid = await ins('voucher', {
      period_key: period, entity_id: ENTITY, book_id: 1, voucher_type_id: voucherTypeId[v.voucherType], voucher_no: v.number, voucher_date: v.date,
      narration: v.narration, status: mapVoucherStatus(v.status), source_type: v.sourceType ?? null, business_event: v.sourceType ?? null,
      posting_rule_code: v.postingRule && v.postingRule !== 'MANUAL' && v.postingRule !== '—' ? v.postingRule : null,
      posting_rule_version: v.postingRuleVersion && v.postingRuleVersion !== '—' ? v.postingRuleVersion : null,
      currency: v.currency, total_dr: v.totalDr, total_cr: v.totalCr, book_label: v.book,
      prepared_by: nameUser[v.preparedBy] ?? userId.accounts, prepared_by_name: v.preparedBy ?? null,
      approved_by: v.approvedBy ? nameUser[v.approvedBy] ?? userId.controller : null, approved_by_name: v.approvedBy ?? null,
      posted_at: v.postedAt ? v.postedAt.replace('T', ' ') : null, evidence_complete: (v.evidence ?? []).every((e) => !e.mandatory || e.attached) ? 1 : 0,
    });
    let ln = 1;
    for (const l of v.lines) {
      await ins('posting_line', {
        period_key: period, voucher_id: vid, entity_id: ENTITY, book_id: 1, line_no: ln, account_id: accountId[l.accountCode] ?? null, dr_cr: UP(l.drCr),
        amount_txn: l.amountTxn, amount_func: l.amountFunc, amount_group: l.amountFunc, currency: l.currency, fx_rate: l.fxRate, fx_rate_type: rateType(l.rateType),
        voucher_date: v.date, shipment_id: l.dimensions?.shipment ? shipmentByNo[l.dimensions.shipment] ?? null : null,
        declaration_id: l.dimensions?.declaration ? declarationByNo[l.dimensions.declaration] ?? null : null,
        tax_code: l.taxCode ?? null, subledger_key: l.subledgerKey ?? null, rule_branch: l.ruleBranch ?? null,
      });
      ln += 1;
    }
    for (const e of v.evidence ?? []) {
      await ins('voucher_evidence', { voucher_id: vid, period_key: period, doc_type: e.docType, file_name: e.name ?? null, issuer: e.issuer ?? null, doc_ref: e.ref ?? null, doc_date: e.date ?? null, is_mandatory: e.mandatory ? 1 : 0, is_attached: e.attached ? 1 : 0, version_no: e.version, size_kb: e.sizeKb ?? null });
    }
  }
}

// ---- exceptions, tasks, close, reconciliations ----------------------------
async function seedOpsQueues(userId: Record<string, number>) {
  for (const e of S.allExceptions) {
    const objId = resolveObj(e.objectType, e.objectId);
    await ins('exception_item', {
      entity_id: ENTITY, rule_id: e.ruleId, severity: UP(e.severity), exception_type: e.type.slice(0, 40), title: e.title, detail: e.detail,
      object_type: e.objectType, object_id: objId ?? 0, object_ref: e.objectId, exposure: e.exposure ?? 0, deadline_on: e.deadline ?? null,
      first_seen_on: addDays('2026-08-04', -e.ageDays), age_days: e.ageDays, is_open: e.open ? 1 : 0,
    });
  }
  for (const t of S.tasks) {
    const objId = resolveObj(t.objectType, t.objectId);
    await ins('work_task', {
      entity_id: ENTITY, task_kind: t.kind, title: t.title, detail: t.detail, severity: UP(t.severity), object_type: t.objectType,
      object_id: objId ?? 0, route: t.route, due_on: t.dueOn ?? null, status: 'OPEN',
    });
  }
  let seq = 1;
  for (const c of S.closeTasks) {
    await ins('close_task', {
      entity_id: ENTITY, period_key: config.server.defaultPeriodKey, day_offset: c.day, area: c.area, step: c.step, owner_role: c.owner,
      is_mandatory: c.mandatory ? 1 : 0, status: mapCloseStatus(c.status), blocking_count: c.blockingCount, blocking_detail: c.blockingDetail ?? null,
      evidence_ref: c.evidence ?? null, seq_no: seq,
    });
    seq += 1;
  }
  for (const r of S.reconciliations) {
    const rid = await ins('reconciliation', {
      entity_id: ENTITY, code: r.id, name: r.name, source_a: r.sourceA, source_b: r.sourceB, frequency: UP(r.frequency), owner_role: r.owner,
      as_of: r.asOf, matched_count: r.matched, unmatched_a: r.unmatchedA, unmatched_b: r.unmatchedB, value_at_risk: r.valueAtRisk,
      oldest_days: r.oldestDays, status: UP(r.status),
    });
    for (const it of r.items) {
      await ins('reconciliation_item', {
        reconciliation_id: rid, entity_id: ENTITY, item_ref: it.ref, item_date: it.date, description: it.description,
        amount_a: it.amountA ?? null, amount_b: it.amountB ?? null, difference: it.difference, cause: it.cause, age_days: it.ageDays,
        limitation_date: it.limitationDate ?? null, status: mapReconItemStatus(it.status),
      });
    }
  }
}

// ---- operational registers (migration 009) --------------------------------
async function seedOperations() {
  const rows: Record<string, Record<string, any>[]> = {
    indent: [
      { indent_no: 'IND-2026-0412', indent_date: '2026-05-20', item_desc: 'HPB-4410 Precision bearing, sealed', qty: 4000, uom: 'PCS', required_by: '2026-07-15', cost_centre: 'CC-PROD-01', precheck_status: 'ALLOWED', status: 'CONVERTED' },
      { indent_no: 'IND-2026-0455', indent_date: '2026-06-28', item_desc: 'NC-2208 Servo controller card', qty: 120, uom: 'PCS', required_by: '2026-08-10', cost_centre: 'CC-MAINT-02', precheck_status: 'WARNING', status: 'CONVERTED' },
      { indent_no: 'IND-2026-0478', indent_date: '2026-07-14', item_desc: 'ZF-1100 Hex bolt, grade 8.8', qty: 240000, uom: 'PCS', required_by: '2026-08-30', cost_centre: 'CC-PROD-02', precheck_status: 'BLOCKED', status: 'SUBMITTED' },
      { indent_no: 'IND-2026-0490', indent_date: '2026-07-30', item_desc: 'HPB-4430 Spindle assembly', qty: 600, uom: 'PCS', required_by: '2026-09-15', cost_centre: 'CC-PROD-01', precheck_status: 'ALLOWED', status: 'APPROVED' },
    ],
    goods_receipt: [
      { grn_no: 'GRN-2026-0331', grn_date: '2026-07-18', shipment_no: 'SHP-2026-04471', supplier: 'Hanwha Precision Co', warehouse: 'Pune Unit I', line_count: 5, value: 1846500, currency: 'INR', status: 'POSTED' },
      { grn_no: 'GRN-2026-0342', grn_date: '2026-07-26', shipment_no: 'SHP-2026-04488', supplier: 'Zhejiang Fastener Works', warehouse: 'Pune Unit I', line_count: 2, value: 512000, currency: 'INR', status: 'DISCREPANCY' },
      { grn_no: 'GRN-2026-0350', grn_date: '2026-08-01', shipment_no: 'SHP-2026-04502', supplier: 'Bosch Rexroth AG', warehouse: 'Chakan Store', line_count: 3, value: 2210400, currency: 'INR', status: 'DRAFT' },
    ],
    document_set: [
      { set_no: 'DS-2026-0771', shipment_no: 'SHP-2026-04471', doc_type: 'Import clearance set', party: 'Hanwha Precision Co', received_on: '2026-07-12', completeness_pct: 100, status: 'CLEARED' },
      { set_no: 'DS-2026-0782', shipment_no: 'SHP-2026-04488', doc_type: 'Import clearance set', party: 'Zhejiang Fastener Works', received_on: '2026-07-22', completeness_pct: 80, status: 'PARTIAL' },
      { set_no: 'DS-2026-0790', shipment_no: 'SHP-2026-04502', doc_type: 'Import clearance set', party: 'Bosch Rexroth AG', received_on: null, completeness_pct: 40, status: 'OPEN' },
    ],
    booking: [
      { booking_no: 'BKG-2026-1201', booking_date: '2026-07-05', carrier: 'Maersk Line', transport_mode: 'SEA', origin_port: 'Busan', dest_port: 'Nhava Sheva', container_type: '40HC', containers: 2, status: 'CONFIRMED' },
      { booking_no: 'BKG-2026-1215', booking_date: '2026-07-19', carrier: 'Hapag-Lloyd', transport_mode: 'SEA', origin_port: 'Ningbo', dest_port: 'Nhava Sheva', container_type: '20GP', containers: 1, status: 'REQUESTED' },
      { booking_no: 'BKG-2026-1230', booking_date: '2026-07-28', carrier: 'Emirates SkyCargo', transport_mode: 'AIR', origin_port: 'Frankfurt', dest_port: 'Mumbai', container_type: 'ULD', containers: 0, status: 'SHIPPED' },
    ],
    freight_container: [
      { container_no: 'MSKU7788112', size_type: '40HC', shipment_no: 'SHP-2026-04471', seal_no: 'SL-449120', gross_weight_kg: 21450, free_time_days: 7, demurrage: 0, status: 'GATED_OUT' },
      { container_no: 'HLXU5540221', size_type: '20GP', shipment_no: 'SHP-2026-04488', seal_no: 'SL-551903', gross_weight_kg: 9800, free_time_days: 5, demurrage: 18500, status: 'AT_PORT' },
      { container_no: 'TCLU9903471', size_type: '40GP', shipment_no: 'SHP-2026-04502', seal_no: 'SL-660145', gross_weight_kg: 18320, free_time_days: 10, demurrage: 0, status: 'IN_TRANSIT' },
    ],
    enquiry: [
      { enquiry_no: 'ENQ-2026-0501', enquiry_date: '2026-07-02', customer: 'Meridian Industries', country_code: 'US', item_desc: 'Machined spindle housings', qty: 5000, target_price: 42.5, currency: 'USD', status: 'QUOTED' },
      { enquiry_no: 'ENQ-2026-0512', enquiry_date: '2026-07-16', customer: 'Nordic Components AB', country_code: 'SE', item_desc: 'Precision bearings, sealed', qty: 12000, target_price: 8.9, currency: 'EUR', status: 'OPEN' },
      { enquiry_no: 'ENQ-2026-0525', enquiry_date: '2026-07-29', customer: 'Gulf Machinery LLC', country_code: 'AE', item_desc: 'Hydraulic valve blocks', qty: 800, target_price: 130, currency: 'USD', status: 'WON' },
    ],
    export_invoice: [
      { invoice_no: 'EXP/2026/0441', invoice_date: '2026-07-24', customer: 'Meridian Industries', currency: 'USD', fob_value: 395000, incoterm: 'FOB', shipment_no: 'SHP-2026-04512', status: 'SHIPPED' },
      { invoice_no: 'EXP/2026/0448', invoice_date: '2026-07-30', customer: 'Gulf Machinery LLC', currency: 'USD', fob_value: 104000, incoterm: 'CIF', shipment_no: 'SHP-2026-04520', status: 'ISSUED' },
      { invoice_no: 'EXP/2026/0455', invoice_date: '2026-08-02', customer: 'Nordic Components AB', currency: 'EUR', fob_value: 61200, incoterm: 'FCA', shipment_no: null, status: 'DRAFT' },
    ],
    provider_invoice: [
      { invoice_no: 'FF-INV-88213', invoice_date: '2026-07-20', provider: 'BlueDart Aviation', service_type: 'FREIGHT', currency: 'INR', amount: 214000, shipment_no: 'SHP-2026-04471', status: 'APPROVED' },
      { invoice_no: 'CHA-2026-0912', invoice_date: '2026-07-25', provider: 'Seahorse Clearing', service_type: 'CHA', currency: 'INR', amount: 46800, shipment_no: 'SHP-2026-04488', status: 'VERIFIED' },
      { invoice_no: 'TR-55120', invoice_date: '2026-07-31', provider: 'GATI Logistics', service_type: 'TRANSPORT', currency: 'INR', amount: 31500, shipment_no: 'SHP-2026-04502', status: 'RECEIVED' },
    ],
    bank_charge: [
      { charge_ref: 'BC-2026-0771', charge_date: '2026-07-15', bank: 'HDFC Bank', instrument_no: 'LC-IMP-2026-011', charge_type: 'COMMISSION', currency: 'INR', amount: 27600, status: 'RECOVERED' },
      { charge_ref: 'BC-2026-0779', charge_date: '2026-07-22', bank: 'ICICI Bank', instrument_no: 'LC-EXP-2026-004', charge_type: 'NEGOTIATION', currency: 'INR', amount: 18400, status: 'POSTED' },
      { charge_ref: 'BC-2026-0788', charge_date: '2026-07-29', bank: 'HDFC Bank', instrument_no: 'BG-2026-002', charge_type: 'SWIFT', currency: 'INR', amount: 2200, status: 'POSTED' },
    ],
    insurance_policy: [
      { policy_no: 'MOP-2026-0031', insurer: 'New India Assurance', cover_type: 'MARINE_OPEN', currency: 'INR', sum_insured: 50000000, premium: 185000, valid_from: '2026-04-01', valid_to: '2027-03-31', status: 'ACTIVE' },
      { policy_no: 'MSP-2026-0442', insurer: 'ICICI Lombard', cover_type: 'MARINE_SPECIFIC', currency: 'INR', sum_insured: 2100000, premium: 8400, valid_from: '2026-07-05', valid_to: '2026-09-05', status: 'ACTIVE' },
      { policy_no: 'AIR-2026-0119', insurer: 'Tata AIG', cover_type: 'AIR', currency: 'INR', sum_insured: 950000, premium: 5200, valid_from: '2026-07-20', valid_to: '2026-08-20', status: 'CLAIMED' },
    ],
  };
  for (const [table, list] of Object.entries(rows)) {
    for (const r of list) await ins(table, { entity_id: ENTITY, ...r });
  }
}

// ---- operational registers, batch 2 (migration 010) -----------------------
async function seedOperations2() {
  const rows: Record<string, Record<string, any>[]> = {
    sourcing_quote: [
      { rfq_no: 'RFQ-2026-0301', rfq_date: '2026-06-15', item_desc: 'Precision bearings, sealed', supplier: 'Hanwha Precision Co', country_code: 'KR', currency: 'USD', unit_price: 6.8, lead_time_days: 35, landed_estimate: 1846500, status: 'AWARDED' },
      { rfq_no: 'RFQ-2026-0312', rfq_date: '2026-07-02', item_desc: 'Hex bolts, grade 8.8', supplier: 'Zhejiang Fastener Works', country_code: 'CN', currency: 'USD', unit_price: 0.09, lead_time_days: 28, landed_estimate: 512000, status: 'REJECTED' },
      { rfq_no: 'RFQ-2026-0320', rfq_date: '2026-07-18', item_desc: 'Servo controller cards', supplier: 'Bosch Rexroth AG', country_code: 'DE', currency: 'EUR', unit_price: 210, lead_time_days: 45, landed_estimate: 2210400, status: 'SHORTLISTED' },
    ],
    post_clearance_case: [
      { case_no: 'PCC-2026-011', opened_on: '2026-07-08', declaration_no: 'BOE-4471', case_type: 'SVB', authority: 'Customs SVB Cell', exposure: 340000, currency: 'INR', due_on: '2026-08-20', status: 'OPEN' },
      { case_no: 'PCC-2026-014', opened_on: '2026-07-21', declaration_no: 'BOE-4488', case_type: 'AMENDMENT', authority: 'Customs Appraising', exposure: 0, currency: 'INR', due_on: '2026-08-10', status: 'REPLIED' },
    ],
    realisation: [
      { realisation_no: 'RLS-2026-0221', invoice_no: 'EXP/2026/0441', customer: 'Meridian Industries', currency: 'USD', invoice_value: 395000, realised_value: 0, due_date: '2026-10-22', edpms_status: 'OUTSTANDING', status: 'PENDING' },
      { realisation_no: 'RLS-2026-0225', invoice_no: 'EXP/2026/0448', customer: 'Gulf Machinery LLC', currency: 'USD', invoice_value: 104000, realised_value: 104000, due_date: '2026-09-30', realised_on: '2026-08-01', edpms_status: 'REALISED', status: 'REALISED' },
    ],
    stuffing: [
      { stuffing_no: 'STF-2026-0091', stuffing_date: '2026-07-22', shipment_no: 'SHP-2026-04512', container_no: 'MSKU7788112', location: 'Pune ICD', supervisor: 'R. Iyer', packages: 220, gross_weight_kg: 18400, status: 'COMPLETED' },
      { stuffing_no: 'STF-2026-0095', stuffing_date: '2026-07-30', shipment_no: 'SHP-2026-04520', container_no: 'HLXU5540221', location: 'JNPT CFS', supervisor: 'K. Menon', packages: 96, gross_weight_kg: 9100, status: 'SEALED' },
    ],
    presentation: [
      { presentation_no: 'PRS-2026-0044', presented_on: '2026-07-25', instrument_no: 'LC-EXP-2026-004', bank: 'ICICI Bank', currency: 'USD', amount: 104000, discrepancies: 0, deadline: '2026-08-05', status: 'ACCEPTED' },
      { presentation_no: 'PRS-2026-0048', presented_on: null, instrument_no: 'LC-EXP-2026-006', bank: 'HDFC Bank', currency: 'USD', amount: 395000, discrepancies: 2, deadline: '2026-08-18', status: 'DRAFT' },
    ],
    collection_bill: [
      { bill_no: 'COL-2026-0132', bill_date: '2026-07-15', drawee: 'Nordic Components AB', bank: 'ICICI Bank', collection_type: 'DA', currency: 'EUR', amount: 61200, tenor_days: 60, maturity_on: '2026-09-13', status: 'ACCEPTED' },
      { bill_no: 'COL-2026-0140', bill_date: '2026-07-28', drawee: 'Gulf Machinery LLC', bank: 'HDFC Bank', collection_type: 'DP', currency: 'USD', amount: 104000, tenor_days: 0, maturity_on: null, status: 'PAID' },
    ],
    fx_position: [
      { ref_no: 'FX-2026-0071', as_of: '2026-07-31', currency: 'USD', exposure_type: 'RECEIVABLE', gross_exposure: 499000, hedged_amount: 300000, forward_rate: 84.15, maturity_on: '2026-10-31', status: 'PART_HEDGED' },
      { ref_no: 'FX-2026-0072', as_of: '2026-07-31', currency: 'EUR', exposure_type: 'RECEIVABLE', gross_exposure: 61200, hedged_amount: 61200, forward_rate: 92.4, maturity_on: '2026-09-13', status: 'HEDGED' },
      { ref_no: 'FX-2026-0073', as_of: '2026-07-31', currency: 'USD', exposure_type: 'PAYABLE', gross_exposure: 220000, hedged_amount: 0, forward_rate: 0, maturity_on: '2026-09-05', status: 'OPEN' },
    ],
    bonded_entry: [
      { entry_no: 'BND-2026-0021', entry_date: '2026-07-05', warehouse_code: 'MOOWR-PUNE-01', goods_desc: 'CNC turning centre (capital good)', bond_type: 'MOOWR', duty_deferred: 3452336, currency: 'INR', rewarehouse_by: '2027-07-05', status: 'IN_BOND' },
      { entry_no: 'BND-2026-0024', entry_date: '2026-07-19', warehouse_code: 'PVT-BOND-02', goods_desc: 'Servo controller cards', bond_type: 'PRIVATE', duty_deferred: 286140, currency: 'INR', rewarehouse_by: '2027-01-19', status: 'PART_CLEARED' },
    ],
    regulatory_change: [
      { ref_no: 'REG-2026-118', published_on: '2026-07-10', authority: 'CBIC', title: 'Revised AIDC rate on specified capital goods', category: 'CUSTOMS', effective_from: '2026-08-01', impact: 'HIGH', owner_role: 'Compliance officer', status: 'ASSESSING' },
      { ref_no: 'REG-2026-124', published_on: '2026-07-22', authority: 'DGFT', title: 'RoDTEP rate schedule amendment', category: 'FTP', effective_from: '2026-08-15', impact: 'MEDIUM', owner_role: 'Compliance officer', status: 'NEW' },
    ],
    credential: [
      { credential_no: '0507012345', credential_type: 'IEC', holder: 'HB Manufacturing Ltd', authority: 'DGFT', issued_on: '2019-04-01', valid_to: '2027-03-31', status: 'ACTIVE' },
      { credential_no: '27AABCH1234K1Z5', credential_type: 'GSTIN', holder: 'HB Manufacturing Ltd', authority: 'GSTN', issued_on: '2017-07-01', valid_to: null, status: 'ACTIVE' },
      { credential_no: 'AEO-T2-2024-8891', credential_type: 'AEO', holder: 'HB Manufacturing Ltd', authority: 'CBIC', issued_on: '2024-02-15', valid_to: '2027-02-14', status: 'EXPIRING' },
    ],
    filing: [
      { filing_ref: 'GSTR-1', filing_name: 'GSTR-1 — outward supplies incl. exports', authority: 'GST', frequency: 'MONTHLY', period: 'Jul 2026', due_on: '2026-08-11', preparer: 'Tax executive', approver: 'Finance controller', status: 'IN_PROGRESS' },
      { filing_ref: 'SOFTEX', filing_name: 'Softex / services realisation statement', authority: 'RBI via AD bank', frequency: 'MONTHLY', period: 'Jul 2026', due_on: '2026-08-15', preparer: 'Trade finance officer', approver: 'Finance controller', status: 'NOT_STARTED' },
      { filing_ref: 'IEC-CONF', filing_name: 'IEC annual confirmation', authority: 'DGFT', frequency: 'ANNUAL', period: 'FY27', due_on: '2026-06-30', preparer: 'Compliance officer', approver: 'Compliance officer', status: 'FILED' },
    ],
    origin_determination: [
      { ref_no: 'ORG-2026-0051', item_desc: 'Precision bearings, sealed', hs_code: '84821011', agreement: 'CEPA', origin_country: 'KR', rule_applied: 'CTH + 35% value addition', value_addition_pct: 41.2, coo_ref: 'KCCI/2026/88120', status: 'CERTIFIED' },
      { ref_no: 'ORG-2026-0058', item_desc: 'Hydraulic valve blocks', hs_code: '84129090', agreement: 'AIFTA', origin_country: 'IN', rule_applied: 'RVC 40%', value_addition_pct: 46.0, coo_ref: null, status: 'DETERMINED' },
    ],
    checklist: [
      { code: 'CHK-IMP-STD', name: 'Standard import clearance set', applies_to: 'Import declaration', direction: 'IMPORT', item_count: 9, mandatory_count: 6, status: 'ACTIVE' },
      { code: 'CHK-EXP-LC', name: 'Export under LC document set', applies_to: 'Export shipment', direction: 'EXPORT', item_count: 11, mandatory_count: 8, status: 'ACTIVE' },
      { code: 'CHK-EPCG', name: 'EPCG capital goods checklist', applies_to: 'Licence', direction: 'IMPORT', item_count: 7, mandatory_count: 5, status: 'DRAFT' },
    ],
    compliance_pack: [
      { code: 'PACK-IN-CUSTOMS', name: 'India customs tariff & rules', jurisdiction: 'IN', version: '2026.2', rule_count: 1840, effective_from: '2026-07-01', status: 'ACTIVE' },
      { code: 'PACK-IN-FTP', name: 'Foreign Trade Policy content', jurisdiction: 'IN', version: '2026.1', rule_count: 420, effective_from: '2026-04-01', status: 'ACTIVE' },
      { code: 'PACK-SANCTIONS', name: 'Consolidated restricted-party lists', jurisdiction: 'GLOBAL', version: '2026-08-03', rule_count: 96000, effective_from: '2026-08-03', status: 'ACTIVE' },
    ],
  };
  for (const [table, list] of Object.entries(rows)) {
    for (const r of list) await ins(table, { entity_id: ENTITY, ...r });
  }
}

function resolveObj(type: string, ref: string): number | null {
  switch (type) {
    case 'declaration': return declarationId[ref] ?? null;
    case 'shipment': return shipmentId[ref] ?? null;
    case 'instrument': return instrumentId[ref] ?? null;
    case 'party': return partyId[ref] ?? null;
    case 'licence': return licenceId[ref] ?? null;
    case 'costSheet': return costSheetId[ref] ?? null;
    default: return null;
  }
}

// ---- enum mappers ---------------------------------------------------------
function mapStage(s: string): string {
  const m: Record<string, string> = { Planned: 'PLANNED', Booked: 'BOOKED', 'In transit': 'IN_TRANSIT', Arrived: 'ARRIVED', 'Under clearance': 'UNDER_CLEARANCE', Cleared: 'CLEARED', Costed: 'CLEARED', Delivered: 'DELIVERED', 'Documents with bank': 'CLEARED' };
  return m[s] ?? 'PLANNED';
}
function mapDeclStatus(s: string): string {
  const t = s.toLowerCase();
  if (t.includes('cleared')) return 'CLEARED';
  if (t.includes('permitted')) return 'CLEARED';
  if (t.includes('assessment')) return 'ASSESSED';
  if (t.includes('query')) return 'QUERIED';
  if (t.includes('paid')) return 'PAID';
  return 'TRANSMITTED';
}
function mapVoucherStatus(s: string): string {
  return ({ posted: 'POSTED', pendingApproval: 'PENDING_APPROVAL', parked: 'PARKED', reversed: 'REVERSED', cancelled: 'CANCELLED' } as Record<string, string>)[s] ?? 'PARKED';
}
function mapLicStatus(s: string): string {
  const t = s.toLowerCase();
  if (t.includes('redeem')) return 'REDEEMED';
  if (t.includes('met')) return 'OBLIGATION_MET';
  return 'ACTIVE';
}
function mapEntStage(s: string): string {
  const t = s.toLowerCase();
  if (t.includes('reconcil')) return 'RECEIVED';
  if (t.includes('short')) return 'RECEIVED';
  if (t.includes('processing')) return 'FILED';
  if (t.includes('sanction')) return 'SANCTIONED';
  return 'ACCRUED';
}
function mapCloseStatus(s: string): string {
  return ({ complete: 'COMPLETE', inProgress: 'IN_PROGRESS', blocked: 'BLOCKED', notStarted: 'NOT_STARTED' } as Record<string, string>)[s] ?? 'NOT_STARTED';
}
function mapReconItemStatus(s: string): string {
  return ({ unmatched: 'UNMATCHED', matchedManual: 'MATCHED_MANUAL', disputed: 'DISPUTED' } as Record<string, string>)[s] ?? 'UNMATCHED';
}
function addDays(iso: string, days: number): string {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

async function verify(tenantCode: string) {
  const checks: [string, string][] = [
    ['legal_entity', 'SELECT COUNT(*) c FROM legal_entity'],
    ['gl_account', 'SELECT COUNT(*) c FROM gl_account'],
    ['trade_party', 'SELECT COUNT(*) c FROM trade_party'],
    ['declaration', 'SELECT COUNT(*) c FROM declaration'],
    ['declaration_levy', 'SELECT COUNT(*) c FROM declaration_levy'],
    ['voucher', 'SELECT COUNT(*) c FROM voucher'],
    ['posting_line', 'SELECT COUNT(*) c FROM posting_line'],
    ['licence', 'SELECT COUNT(*) c FROM licence'],
    ['cost_line', 'SELECT COUNT(*) c FROM cost_line'],
    ['reconciliation_item', 'SELECT COUNT(*) c FROM reconciliation_item'],
  ];
  const counts: string[] = [];
  for (const [name, sql] of checks) { const r = await q<{ c: number }>(sql); counts.push(`${name} ${n(r[0].c)}`); }
  const tb = await q<{ dr: string; cr: string }>(
    `SELECT SUM(opening_dr + period_dr) dr, SUM(opening_cr + period_cr) cr FROM account_period_balance WHERE entity_id = ${ENTITY} AND period_key = ${config.server.defaultPeriodKey}`,
  );
  const diff = Math.round((n(tb[0].dr) - n(tb[0].cr)) * 100) / 100;
  // eslint-disable-next-line no-console
  console.log(`    [${tenantCode}] ${counts.join(', ')} | TB diff ${diff}`);
  if (diff !== 0) throw new Error(`[${tenantCode}] Trial balance does not balance: difference ${diff}`);
}

seed().then(
  async () => { await closeAllPools(); process.exit(0); },
  async (e) => { console.error('seed failed:', e); await closeAllPools(); process.exit(1); },
);
