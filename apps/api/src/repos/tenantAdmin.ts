import bcrypt from 'bcryptjs';
import { cq, cq1, cexec, n } from '../db/pool.js';
import { runWithTenant } from '../db/pools.js';
import { ensureDatabase, applyDir, tenantDir } from '../db/migrator.js';
import { config } from '../db/env.js';
import { HttpError } from '../http/context.js';
import * as S from '../seed.js';

const UP = (s?: string) => (s ? s.toUpperCase() : s);

export async function listTenants() {
  const rows = await cq<any>('SELECT id, code, name, db_name, status, created_at FROM tenant ORDER BY id');
  const out: any[] = [];
  for (const t of rows) {
    const users = n((await cq<any>('SELECT COUNT(*) c FROM app_user WHERE tenant_id = ?', [n(t.id)]))[0]?.c);
    out.push({ id: n(t.id), code: t.code, name: t.name, db: t.db_name, status: t.status, createdAt: t.created_at, users });
  }
  return out;
}

/**
 * Provision a new business: register it, create its own database, migrate it,
 * and seed a usable baseline (reference data, chart of accounts, voucher types)
 * plus an administrator. Database creation needs a privileged admin connection
 * (works under Docker Compose); where that is unavailable the database must
 * already exist. Migration + seed then run against it.
 */
export async function provisionTenant(body: any) {
  const code = String(body?.code ?? '').trim().toUpperCase();
  const name = String(body?.name ?? '').trim();
  if (!/^[A-Z0-9]{2,20}$/.test(code)) throw new HttpError(422, 'code must be 2–20 letters/digits');
  if (!name) throw new HttpError(422, 'name is required');
  const existing = await cq1<any>('SELECT id FROM tenant WHERE code = ?', [code]);
  if (existing) throw new HttpError(409, `Tenant ${code} already exists`, 'DUPLICATE');
  const dbName = `${config.db.tenantDbPrefix}${code.toLowerCase()}`;

  const logs: string[] = [];
  const log = (s: string) => logs.push(s.trim());

  // 1) create + migrate the database
  await ensureDatabase(dbName, false, log);
  try {
    const r = await applyDir(dbName, tenantDir(), { log });
    log(`migrations: ${r.applied.length} applied, ${r.skipped} current`);
  } catch (e: any) {
    throw new HttpError(500, `Could not migrate ${dbName}: ${e.message}. Ensure the database exists and is grantable to the app user.`, 'MIGRATE_FAILED');
  }

  // 2) register the tenant
  const tenantId = await (async () => {
    const info = await cexec('INSERT INTO tenant (code, name, db_name, status) VALUES (?, ?, ?, ?)', [code, name, dbName, 'ACTIVE']);
    return info.insertId;
  })();

  // 3) seed a usable baseline into the new database
  await runWithTenant(dbName, async () => { await seedBaseline(name, code); });

  // 4) create an administrator for the new tenant (control plane)
  const hash = bcrypt.hashSync('hbtrade123', config.auth.bcryptRounds);
  const role = await cq1<any>('SELECT id FROM role WHERE code = ?', ['system_admin']);
  const uinfo = await cexec('INSERT INTO app_user (tenant_id, username, email, full_name, password_hash) VALUES (?, ?, ?, ?, ?)', [tenantId, 'admin', `admin@${code.toLowerCase()}.example`, 'System Administrator', hash]);
  if (role) await cexec('INSERT INTO user_role (user_id, role_id) VALUES (?, ?)', [n(uinfo.insertId), n(role.id)]);
  await cexec('INSERT INTO user_entity_access (user_id, entity_id) VALUES (?, ?)', [n(uinfo.insertId), 1]);

  return { id: n(tenantId), code, name, db: dbName, status: 'ACTIVE', adminUser: 'admin', adminPassword: 'hbtrade123', log: logs };
}

/** A lean but working baseline: reference data, entity, books, periods, the
 *  standard chart of accounts and voucher types, and number series. */
async function seedBaseline(name: string, code: string) {
  const { exec } = await import('../db/pool.js');
  const ins = async (table: string, obj: Record<string, any>) => {
    const keys = Object.keys(obj);
    await exec(`INSERT INTO \`${table}\` (${keys.map((k) => `\`${k}\``).join(',')}) VALUES (${keys.map(() => '?').join(',')})`, keys.map((k) => obj[k]));
  };
  // reference
  for (const [c, nm, ccy] of [['IN', 'India', 'INR'], ['US', 'United States', 'USD'], ['DE', 'Germany', 'EUR'], ['CN', 'China', 'CNY'], ['AE', 'UAE', 'AED'], ['GB', 'United Kingdom', 'GBP'], ['KR', 'Korea', 'KRW'], ['SE', 'Sweden', 'SEK']] as any) await ins('country', { code: c, name: nm, default_ccy: ccy });
  for (const [c, nm, dp] of [['INR', 'Indian Rupee', 2], ['USD', 'US Dollar', 2], ['EUR', 'Euro', 2], ['GBP', 'Pound', 2], ['AED', 'Dirham', 2], ['CNY', 'Yuan', 2]] as any) await ins('currency', { code: c, name: nm, precision_dp: dp });
  for (const [c, nm, m, r, f, i2, cl, ov] of [['FOB', 'Free On Board', 'SEA', 'On board', 0, 0, 'BUYER', 'onBoard'], ['CIF', 'Cost Insurance Freight', 'SEA', 'On board', 1, 1, 'BUYER', 'onBoard'], ['FCA', 'Free Carrier', 'ANY', 'On handover', 0, 0, 'BUYER', 'onHandover'], ['EXW', 'Ex Works', 'ANY', 'At premises', 0, 0, 'BUYER', 'atCollection'], ['CFR', 'Cost and Freight', 'SEA', 'On board', 1, 0, 'BUYER', 'onBoard'], ['DAP', 'Delivered At Place', 'ANY', 'At place', 1, 0, 'BUYER', 'atDelivery']] as any) await ins('incoterm', { code: c, name: nm, modes: m, risk_transfer: r, freight_in_value: f, insurance_by_seller: i2, import_cleared_by: cl, ownership_event: ov });
  for (const [c, nm, cls] of [['EA', 'Each', 'count'], ['PCS', 'Pieces', 'count'], ['KG', 'Kilogram', 'mass'], ['MT', 'Tonne', 'mass'], ['NOS', 'Numbers', 'count'], ['SET', 'Set', 'count']] as any) await ins('uom', { code: c, name: nm, uom_class: cls });

  await ins('legal_entity', { id: 1, code, name, country_code: 'IN', functional_ccy: 'INR', group_ccy: 'INR', gaap_framework: 'IND_AS' });
  await ins('site', { id: 1, entity_id: 1, code: 'MAIN', name: `${name} — Main`, state_code: '27' });
  for (let i = 0; i < 4; i += 1) {
    const [c, nm, basis, gaap] = [['PRIMARY', 'Primary book (Ind AS)', 'PRIMARY', 'IND_AS'], ['TAX', 'Tax book', 'TAX', 'TAX'], ['GROUP', 'Group (IFRS)', 'GROUP', 'IFRS'], ['MEMO', 'Memorandum', 'MEMORANDUM', 'NA']][i];
    await ins('book', { id: i + 1, entity_id: 1, code: c, name: nm, basis, gaap });
  }
  for (const [k, s, e, st] of [[202607, '2026-07-01', '2026-07-31', 'OPEN'], [202608, '2026-08-01', '2026-08-31', 'OPEN']] as any) await ins('accounting_period', { entity_id: 1, book_id: 1, period_key: k, fiscal_year: '2026-27', starts_on: s, ends_on: e, status: st });

  // chart of accounts (from the shared demo chart) with zero opening balances
  for (const a of S.accounts) {
    const info = await (await import('../db/pool.js')).exec(
      `INSERT INTO gl_account (entity_id, code, name, account_class, account_type, account_group, schedule_iii_group, cash_flow_class, subledger, is_monetary, manual_posting_allowed, mandatory_dimensions, recon_frequency, currency, valid_from)
       VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '2020-04-01')`,
      [a.code, a.name, UP(a.class), UP(a.type), a.group, a.scheduleIIIGroup, UP(a.cashFlow) ?? 'NONE', a.subledger ? UP(a.subledger) : 'NONE', a.monetary ? 1 : 0, a.manualPostingAllowed ? 1 : 0, (a.mandatoryDimensions ?? []).join(','), a.reconFrequency ? UP(a.reconFrequency) : 'NONE', a.currency ?? null],
    );
    await ins('account_period_balance', { entity_id: 1, book_id: 1, account_id: n(info.insertId), period_key: 202607, opening_dr: 0, opening_cr: 0, period_dr: 0, period_cr: 0, line_count: 0 });
  }
  // voucher types + number series
  for (const v of S.voucherTypes) {
    const info = await (await import('../db/pool.js')).exec(
      `INSERT INTO voucher_type (entity_id, code, name, document_class, statutory_series, posts_on, reversible, required_evidence, approval_matrix, print_format, retention_years, books)
       VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [v.code, v.name, UP(v.documentClass), v.statutorySeries ? 1 : 0, UP(v.postsOn), v.reversible ? 1 : 0, (v.requiredEvidence ?? []).join('; '), v.approvalMatrix ?? null, v.printFormat ?? null, v.retentionYears ?? 8, (v.books ?? ['Primary']).map((b) => UP(b)).join(',')],
    );
    await ins('number_series', { entity_id: 1, voucher_type_id: n(info.insertId), fiscal_year: '2026-27', prefix: `${v.code}/2026-27/`, width: 5, next_no: 1 });
  }
}
