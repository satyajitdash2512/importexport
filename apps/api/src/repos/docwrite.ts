/**
 * Document writes that involve child rows (posting lines, order lines) and so
 * can't go through the generic single-table CRUD. Vouchers are created PARKED
 * (posting/numbering happens later via POST /vouchers/:id/post); a parked or
 * pending voucher can be edited or deleted, a posted one cannot.
 */
import { q, q1, exec, withTx, n } from '../db/pool.js';
import { ext, parseExt } from './ext.js';
import { HttpError } from '../http/context.js';

const pk = (d: string) => Number(d.slice(0, 4)) * 100 + Number(d.slice(5, 7));

interface VoucherLineInput { accountCode: string; drCr: 'Dr' | 'Cr'; amount: number; narration?: string; }
interface VoucherInput {
  voucherType: string; date: string; narration: string; book?: string; currency?: string;
  lines: VoucherLineInput[];
}

async function resolveAccounts(entityId: number, codes: string[]) {
  if (!codes.length) return new Map<string, number>();
  const rows = await q<any>(`SELECT id, code FROM gl_account WHERE entity_id = ? AND code IN (${codes.map(() => '?').join(',')})`, [entityId, ...codes]);
  return new Map(rows.map((r) => [r.code, n(r.id)]));
}

export async function createVoucher(entityId: number, body: VoucherInput, userId: number, userName: string) {
  if (!body?.voucherType) throw new HttpError(422, 'voucherType is required');
  if (!body?.date) throw new HttpError(422, 'date is required');
  const lines = body.lines ?? [];
  if (lines.length < 2) throw new HttpError(422, 'A voucher needs at least two lines');

  const vt = await q1<any>('SELECT id, name, books FROM voucher_type WHERE entity_id = ? AND code = ?', [entityId, body.voucherType]);
  if (!vt) throw new HttpError(422, `Unknown voucher type ${body.voucherType}`);

  const accts = await resolveAccounts(entityId, [...new Set(lines.map((l) => l.accountCode))]);
  let dr = 0; let cr = 0;
  for (const l of lines) {
    if (!accts.has(l.accountCode)) throw new HttpError(422, `Unknown account ${l.accountCode}`);
    const amt = Number(l.amount) || 0;
    if (amt <= 0) throw new HttpError(422, 'Every line needs a positive amount');
    if (l.drCr === 'Dr') dr += amt; else cr += amt;
  }
  if (Math.round((dr - cr) * 100) / 100 !== 0) throw new HttpError(422, `Voucher does not balance: debits ${dr.toFixed(2)} vs credits ${cr.toFixed(2)}`, 'UNBALANCED');

  const period = pk(body.date);
  const currency = body.currency ?? 'INR';
  return withTx(async (tx) => {
    const info = await tx.exec(
      `INSERT INTO voucher (period_key, entity_id, book_id, voucher_type_id, voucher_date, narration, status, currency, total_dr, total_cr, prepared_by, prepared_by_name, book_label)
       VALUES (?, ?, 1, ?, ?, ?, 'PARKED', ?, ?, ?, ?, ?, ?)`,
      [period, entityId, n(vt.id), body.date, body.narration ?? '', currency, dr, cr, userId, userName, body.book ?? 'Primary'],
    );
    const vid = info.insertId;
    let ln = 1;
    for (const l of lines) {
      const amt = Number(l.amount);
      await tx.exec(
        `INSERT INTO posting_line (period_key, voucher_id, entity_id, book_id, line_no, account_id, dr_cr, amount_txn, amount_func, amount_group, currency, fx_rate, fx_rate_type, voucher_date)
         VALUES (?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, 1, 'ACCOUNTING', ?)`,
        [period, vid, entityId, ln, accts.get(l.accountCode), l.drCr === 'Dr' ? 'DR' : 'CR', amt, amt, amt, currency, body.date],
      );
      ln += 1;
    }
    return { id: ext.voucher(vid), status: 'parked', totalDr: dr, totalCr: cr, lines: lines.length };
  });
}

export async function updateVoucher(entityId: number, idStr: string, body: VoucherInput) {
  const id = parseExt(idStr);
  const v = await q1<any>('SELECT id, period_key, status FROM voucher WHERE entity_id = ? AND id = ?', [entityId, id]);
  if (!v) throw new HttpError(404, 'Voucher not found');
  if (v.status === 'POSTED' || v.status === 'REVERSED' || v.status === 'CANCELLED') {
    throw new HttpError(409, `A ${v.status.toLowerCase()} voucher cannot be edited`, 'IMMUTABLE');
  }
  const period = n(v.period_key);
  const lines = body.lines ?? [];
  if (lines.length && lines.length < 2) throw new HttpError(422, 'A voucher needs at least two lines');

  const accts = lines.length ? await resolveAccounts(entityId, [...new Set(lines.map((l) => l.accountCode))]) : new Map();
  let dr = 0; let cr = 0;
  for (const l of lines) { const a = Number(l.amount) || 0; if (l.drCr === 'Dr') dr += a; else cr += a; if (!accts.has(l.accountCode)) throw new HttpError(422, `Unknown account ${l.accountCode}`); }
  if (lines.length && Math.round((dr - cr) * 100) / 100 !== 0) throw new HttpError(422, `Voucher does not balance: ${dr.toFixed(2)} vs ${cr.toFixed(2)}`, 'UNBALANCED');

  return withTx(async (tx) => {
    const sets: string[] = []; const params: any[] = [];
    if (body.narration !== undefined) { sets.push('narration = ?'); params.push(body.narration); }
    if (body.currency !== undefined) { sets.push('currency = ?'); params.push(body.currency); }
    if (body.date !== undefined) { sets.push('voucher_date = ?'); params.push(body.date); }
    if (lines.length) { sets.push('total_dr = ?', 'total_cr = ?'); params.push(dr, cr); }
    if (sets.length) await tx.exec(`UPDATE voucher SET ${sets.join(', ')} WHERE id = ? AND period_key = ?`, [...params, id, period]);
    if (lines.length) {
      await tx.exec('DELETE FROM posting_line WHERE voucher_id = ? AND period_key = ?', [id, period]);
      let ln = 1;
      for (const l of lines) {
        const amt = Number(l.amount);
        await tx.exec(
          `INSERT INTO posting_line (period_key, voucher_id, entity_id, book_id, line_no, account_id, dr_cr, amount_txn, amount_func, amount_group, currency, fx_rate, fx_rate_type, voucher_date)
           VALUES (?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, 1, 'ACCOUNTING', ?)`,
          [period, id, entityId, ln, accts.get(l.accountCode), l.drCr === 'Dr' ? 'DR' : 'CR', amt, amt, amt, body.currency ?? 'INR', body.date ?? '2026-07-01'],
        );
        ln += 1;
      }
    }
    return { id: ext.voucher(id), updated: true };
  });
}

export async function deleteVoucher(entityId: number, idStr: string) {
  const id = parseExt(idStr);
  const v = await q1<any>('SELECT id, period_key, status FROM voucher WHERE entity_id = ? AND id = ?', [entityId, id]);
  if (!v) throw new HttpError(404, 'Voucher not found');
  if (v.status === 'POSTED' || v.status === 'REVERSED') throw new HttpError(409, `A ${v.status.toLowerCase()} voucher cannot be deleted; reverse it instead`, 'IMMUTABLE');
  const period = n(v.period_key);
  return withTx(async (tx) => {
    await tx.exec('DELETE FROM posting_line WHERE voucher_id = ? AND period_key = ?', [id, period]);
    await tx.exec('DELETE FROM voucher_evidence WHERE voucher_id = ? AND period_key = ?', [id, period]);
    await tx.exec('DELETE FROM voucher WHERE id = ? AND period_key = ?', [id, period]);
    return { id: ext.voucher(id), deleted: true };
  });
}

/** Replace an order's lines wholesale. */
export async function replaceOrderLines(entityId: number, idStr: string, lines: any[]) {
  const id = parseExt(idStr);
  const o = await q1<any>('SELECT id FROM trade_order WHERE entity_id = ? AND id = ?', [entityId, id]);
  if (!o) throw new HttpError(404, 'Order not found');
  return withTx(async (tx) => {
    await tx.exec('DELETE FROM trade_order_line WHERE order_id = ?', [id]);
    let ln = 1; let total = 0;
    for (const l of lines) {
      const qty = Number(l.qty) || 0; const price = Number(l.unitPrice ?? l.unit_price) || 0;
      const val = Math.round(qty * price * 100) / 100; total += val;
      await tx.exec(
        `INSERT INTO trade_order_line (order_id, entity_id, line_no, item_code, description, hs_code, qty, uom, unit_price, line_value, currency, origin_country, net_weight_kg)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [id, entityId, ln, l.itemCode ?? l.item_code ?? '', l.description ?? '', l.hsCode ?? l.hs_code ?? null, qty, l.uom ?? 'PCS', price, val, l.currency ?? 'USD', l.originCountry ?? l.origin_country ?? null, Number(l.netWeightKg ?? l.net_weight_kg) || 0],
      );
      ln += 1;
    }
    await tx.exec('UPDATE trade_order SET order_value = ? WHERE id = ?', [total, id]);
    return { id: ext.order(id), lines: lines.length, orderValue: total };
  });
}
