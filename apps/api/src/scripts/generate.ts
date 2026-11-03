/**
 * High-volume generator. Fills the partitioned fact tables with synthetic —
 * but internally consistent — documents so the heavy queries can be benchmarked
 * against a realistic slice, and so partition pruning and covering indexes can
 * be shown working.
 *
 *   tsx src/scripts/generate.ts [vouchers] [declarations]
 *   tsx src/scripts/generate.ts 200000 100000
 *
 * Data lands in future periods 202701..202712 under entity 1, so it never
 * touches the hand-built demo period (202607). Every generated voucher balances
 * (debits == credits), so the trial balance for those periods balances too; the
 * rollup (account_period_balance) is accumulated in memory and written once.
 *
 * Fixed shape for predictable AUTO_INCREMENT id math:
 *   voucher      → 4 posting lines (2 Dr, 2 Cr, balanced)
 *   declaration  → 4 lines, each with 3 levies
 */
import mysql from 'mysql2/promise';
import { config } from '../db/env.js';

const ENTITY = 1;
const BOOK = 1;
const PERIODS = [202701, 202702, 202703, 202704, 202705, 202706, 202707, 202708, 202709, 202710, 202711, 202712];

// small deterministic PRNG so runs are reproducible
let _s = 123456789;
function rnd() { _s = (_s * 1103515245 + 12345) & 0x7fffffff; return _s / 0x7fffffff; }
const ri = (a: number, b: number) => a + Math.floor(rnd() * (b - a + 1));
const pick = <T>(arr: T[]) => arr[Math.floor(rnd() * arr.length)];

async function conn(database: string) {
  return mysql.createConnection({
    host: config.db.host, port: config.db.port, user: config.db.user, password: config.db.password,
    database, multipleStatements: true,
  });
}

async function main() {
  // args: [vouchers] [declarations] [tenantDb]
  const nVouchers = Number(process.argv[2] || 200000);
  const nDeclarations = Number(process.argv[3] || 100000);
  const dbName = process.argv[4] || `${config.db.tenantDbPrefix}hbml`;
  // eslint-disable-next-line no-console
  console.log(`  target database: ${dbName}`);
  const c = await conn(dbName);
  const cq = async <T = any>(sql: string, p: any[] = []): Promise<T[]> => { const [r] = await c.query(sql, p); return r as T[]; };
  await c.query('SET autocommit=1');
  await c.query('SET unique_checks=0');
  await c.query('SET foreign_key_checks=0');

  // reference ids to reference realistically
  const accounts = await cq<any>('SELECT id, account_class, account_type FROM gl_account WHERE entity_id = ?', [ENTITY]);
  const drAccts = accounts.filter((a) => ['ASSET', 'EXPENSE'].includes(a.account_class)).map((a) => Number(a.id));
  const crAccts = accounts.filter((a) => ['LIABILITY', 'INCOME', 'EQUITY'].includes(a.account_class)).map((a) => Number(a.id));
  const clearing = accounts.filter((a) => a.account_type === 'CLEARING').map((a) => Number(a.id));
  const vtId = Number((await cq<any>('SELECT id FROM voucher_type WHERE entity_id = ? AND code = ?', [ENTITY, 'JVM']))[0].id);
  const parties = (await cq<any>('SELECT id FROM trade_party WHERE entity_id = ?', [ENTITY])).map((p) => Number(p.id));
  const items = await cq<any>('SELECT item_code, description, stock_uom FROM item WHERE entity_id = ?', [ENTITY]);
  const hsCodes = ['84821020', '84821010', '40169390', '84831099', '84839000', '73181500', '85371000', '84811000'];
  const levyDefs = [
    { code: 'BCD', name: 'Basic customs duty', rate: 7.5 },
    { code: 'SWS', name: 'Social welfare surcharge', rate: 10 },
    { code: 'IGST', name: 'Integrated GST on import', rate: 18 },
  ];

  // in-memory rollup: key `${accountId}:${period}` -> [dr, cr, count]
  const rollup = new Map<string, [number, number, number]>();
  const addRoll = (acct: number, period: number, dr: number, cr: number) => {
    const k = `${acct}:${period}`;
    const cur = rollup.get(k) ?? [0, 0, 0];
    cur[0] += dr; cur[1] += cr; cur[2] += 1; rollup.set(k, cur);
  };

  const dayOf = (period: number) => `${String(period).slice(0, 4)}-${String(period).slice(4)}-${String(ri(1, 28)).padStart(2, '0')}`;
  const BATCH = 1000;
  const t0 = Date.now();

  // ---- vouchers + posting lines ----
  let madeV = 0; let madePL = 0;
  for (let done = 0; done < nVouchers; done += BATCH) {
    const size = Math.min(BATCH, nVouchers - done);
    const vRows: any[] = [];
    const meta: { period: number; date: string; lines: [number, 'DR' | 'CR', number][] }[] = [];
    for (let i = 0; i < size; i += 1) {
      const period = PERIODS[(done + i) % PERIODS.length];
      const date = dayOf(period);
      const a = ri(1000, 500000); const b = ri(1000, 500000);
      const c1 = Math.round((a + b) * 0.4); const c2 = a + b - c1;
      // ~6% of vouchers touch a clearing account (for the ageing benchmark)
      const drAcc1 = rnd() < 0.06 && clearing.length ? pick(clearing) : pick(drAccts);
      const lines: [number, 'DR' | 'CR', number][] = [
        [drAcc1, 'DR', a], [pick(drAccts), 'DR', b], [pick(crAccts), 'CR', c1], [pick(crAccts), 'CR', c2],
      ];
      meta.push({ period, date, lines });
      vRows.push([period, ENTITY, BOOK, vtId, `JVM/GEN/${done + i + 1}`, date, 'Synthetic balanced journal (generated)', 'POSTED', 'INR', a + b, a + b, 1]);
    }
    const vSql = `INSERT INTO voucher (period_key, entity_id, book_id, voucher_type_id, voucher_no, voucher_date, narration, status, currency, total_dr, total_cr, prepared_by) VALUES ${vRows.map(() => '(?,?,?,?,?,?,?,?,?,?,?,?)').join(',')}`;
    const [vres]: any = await c.query(vSql, vRows.flat());
    const baseId = vres.insertId;
    // posting lines referencing the consecutive voucher ids
    const plRows: any[] = [];
    for (let i = 0; i < size; i += 1) {
      const vId = baseId + i; const m = meta[i];
      let ln = 1;
      for (const [acc, drcr, amt] of m.lines) {
        const shipmentId = clearing.includes(acc) ? ri(1, 5) : null;
        plRows.push([m.period, vId, ENTITY, BOOK, ln, acc, drcr, amt, amt, amt, 'INR', m.date, shipmentId]);
        addRoll(acc, m.period, drcr === 'DR' ? amt : 0, drcr === 'CR' ? amt : 0);
        ln += 1;
      }
    }
    const plSql = `INSERT INTO posting_line (period_key, voucher_id, entity_id, book_id, line_no, account_id, dr_cr, amount_txn, amount_func, amount_group, currency, voucher_date, shipment_id) VALUES ${plRows.map(() => '(?,?,?,?,?,?,?,?,?,?,?,?,?)').join(',')}`;
    await c.query(plSql, plRows.flat());
    madeV += size; madePL += plRows.length;
    if (madeV % 20000 === 0) process.stdout.write(`\r  vouchers ${madeV}/${nVouchers}  posting_lines ${madePL}`);
  }
  process.stdout.write(`\r  vouchers ${madeV}  posting_lines ${madePL}                    \n`);

  // ---- declarations + lines + levies ----
  let madeD = 0; let madeDL = 0; let madeLV = 0;
  for (let done = 0; done < nDeclarations; done += BATCH) {
    const size = Math.min(BATCH, nDeclarations - done);
    const dRows: any[] = [];
    const dmeta: { period: number; date: string }[] = [];
    for (let i = 0; i < size; i += 1) {
      const period = PERIODS[(done + i) % PERIODS.length];
      const date = dayOf(period);
      const direction = rnd() < 0.6 ? 'IMPORT' : 'EXPORT';
      const av = ri(200000, 9000000);
      const duty = direction === 'IMPORT' ? Math.round(av * 0.28) : 0;
      dmeta.push({ period, date });
      dRows.push([period, ENTITY, 1, `GEN-${done + i + 1}`, direction === 'IMPORT' ? 'BOE_HOME' : 'SB', direction, 'IN', pick(parties), 'INNSA1', date, date, direction === 'IMPORT' ? 'ASSESSED' : 'CLEARED', 'USD', 82.5, av, duty, Math.round(duty * 0.7), Math.round(duty * 0.3)]);
    }
    const dSql = `INSERT INTO declaration (period_key, entity_id, site_id, declaration_no, declaration_type, direction, jurisdiction, party_id, port_code, declaration_date, filed_on, status, currency, statutory_fx_rate, assessable_value, duty_total, duty_recoverable, duty_inventoriable) VALUES ${dRows.map(() => '(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)').join(',')}`;
    const [dres]: any = await c.query(dSql, dRows.flat());
    const baseD = dres.insertId;
    // 4 lines per declaration
    const dlRows: any[] = [];
    for (let i = 0; i < size; i += 1) {
      const dId = baseD + i; const m = dmeta[i];
      for (let ln = 1; ln <= 4; ln += 1) {
        const it = pick(items); const qty = ri(50, 5000); const val = ri(50000, 2000000);
        dlRows.push([m.period, dId, ENTITY, ln, it.item_code, it.description, pick(hsCodes), qty, 'PCS', qty, it.stock_uom, 1, val, 'USD', Math.round(val * 0.9)]);
      }
    }
    const dlSql = `INSERT INTO declaration_line (period_key, declaration_id, entity_id, line_no, item_code, description, hs_code, qty_statutory, statutory_uom, qty_stock, stock_uom, uom_conversion, invoice_value_fc, currency, assessable_value) VALUES ${dlRows.map(() => '(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)').join(',')}`;
    const [dlres]: any = await c.query(dlSql, dlRows.flat());
    const baseDL = dlres.insertId;
    // 3 levies per line
    const lvRows: any[] = [];
    for (let i = 0; i < dlRows.length; i += 1) {
      const lineId = baseDL + i; const period = dlRows[i][0]; const declId = dlRows[i][1]; const av = dlRows[i][14];
      let base = av; let seq = 1;
      for (const ld of levyDefs) {
        const amt = Math.round(base * ld.rate) / 100;
        lvRows.push([period, lineId, declId, ENTITY, seq, ld.code, ld.name, seq === 1 ? 'AV' : 'AV + prior', base, ld.rate, amt, ld.code === 'IGST' ? 1 : 0]);
        base += amt; seq += 1;
      }
    }
    const lvSql = `INSERT INTO declaration_levy (period_key, declaration_line_id, declaration_id, entity_id, seq, levy_code, levy_name, base_expression, base_amount, rate_pct, amount, is_recoverable) VALUES ${lvRows.map(() => '(?,?,?,?,?,?,?,?,?,?,?,?)').join(',')}`;
    await c.query(lvSql, lvRows.flat());
    madeD += size; madeDL += dlRows.length; madeLV += lvRows.length;
    if (madeD % 20000 === 0) process.stdout.write(`\r  declarations ${madeD}/${nDeclarations}  lines ${madeDL}  levies ${madeLV}`);
  }
  process.stdout.write(`\r  declarations ${madeD}  lines ${madeDL}  levies ${madeLV}            \n`);

  // ---- write the accumulated rollup ----
  process.stdout.write('  writing account_period_balance rollup…\n');
  const rr = [...rollup.entries()];
  for (let i = 0; i < rr.length; i += 500) {
    const chunk = rr.slice(i, i + 500);
    const rows = chunk.map(([k, v]) => { const [acc, period] = k.split(':').map(Number); return [ENTITY, BOOK, acc, period, v[0], v[1], v[2]]; });
    await c.query(
      `INSERT INTO account_period_balance (entity_id, book_id, account_id, period_key, period_dr, period_cr, line_count)
       VALUES ${rows.map(() => '(?,?,?,?,?,?,?)').join(',')}
       ON DUPLICATE KEY UPDATE period_dr = period_dr + VALUES(period_dr), period_cr = period_cr + VALUES(period_cr), line_count = line_count + VALUES(line_count)`,
      rows.flat(),
    );
  }
  await c.query('SET unique_checks=1');
  await c.query('SET foreign_key_checks=1');
  await c.query('ANALYZE TABLE posting_line, declaration, declaration_line, declaration_levy, account_period_balance');
  await c.end();
  const secs = ((Date.now() - t0) / 1000).toFixed(1);
  // eslint-disable-next-line no-console
  console.log(`  done in ${secs}s — ${madePL + madeDL + madeLV + madeV} rows across fact tables`);
}

main().then(() => process.exit(0), (e) => { console.error('generate failed:', e); process.exit(1); });
