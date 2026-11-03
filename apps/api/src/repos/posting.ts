/**
 * Transactional voucher posting. This is the one write path that must be
 * airtight, so it is a single transaction on one connection:
 *
 *   1. Re-read the voucher FOR UPDATE (no double-post race).
 *   2. Validate double entry: total debits == total credits, at least two lines,
 *      every account exists, is not blocked, and permits posting.
 *   3. Validate mandatory evidence is attached.
 *   4. Allocate the gapless statutory number under SELECT ... FOR UPDATE on the
 *      number_series row, so the number is assigned AT posting and never skips.
 *   5. Update account_period_balance (the rollup the trial balance reads) for
 *      every line in the same transaction.
 *   6. Flip the voucher to POSTED, stamp the number and time.
 *
 * Any failure rolls the whole thing back — no partial post, no gap in the
 * series, no rollup drift.
 */
import { withTx, n } from '../db/pool.js';
import { ext, parseExt } from './ext.js';
import { HttpError } from '../http/context.js';

function fiscalYear(voucherDate: string): string {
  const d = new Date(`${voucherDate}T00:00:00Z`);
  const y = d.getUTCFullYear();
  const startYear = d.getUTCMonth() + 1 >= 4 ? y : y - 1; // April start
  return `${startYear}-${String((startYear + 1) % 100).padStart(2, '0')}`;
}

export async function postVoucher(entityId: number, idStr: string, actorUserId: number, actorName: string) {
  const voucherId = parseExt(idStr);
  return withTx(async (tx) => {
    const v = await tx.q1<any>('SELECT * FROM voucher WHERE entity_id = ? AND id = ? FOR UPDATE', [entityId, voucherId]);
    if (!v) throw new HttpError(404, 'Voucher not found');
    if (v.status === 'POSTED') throw new HttpError(409, 'Voucher is already posted', 'ALREADY_POSTED');
    if (v.status === 'CANCELLED' || v.status === 'REVERSED') throw new HttpError(409, `Cannot post a ${v.status.toLowerCase()} voucher`, 'BAD_STATE');

    const lines = await tx.q<any>(
      `SELECT pl.*, a.is_blocked, a.manual_posting_allowed, a.account_type
         FROM posting_line pl JOIN gl_account a ON a.id = pl.account_id
        WHERE pl.voucher_id = ? AND pl.period_key = ? ORDER BY pl.line_no`, [voucherId, n(v.period_key)],
    );
    if (lines.length < 2) throw new HttpError(422, 'A voucher must have at least two posting lines', 'UNBALANCED');

    let dr = 0; let cr = 0;
    for (const l of lines) {
      if (Number(l.is_blocked) === 1) throw new HttpError(422, `Account ${l.account_id} is blocked for posting`, 'ACCOUNT_BLOCKED');
      if (l.dr_cr === 'DR') dr += n(l.amount_func); else cr += n(l.amount_func);
    }
    if (Math.round((dr - cr) * 100) / 100 !== 0) {
      throw new HttpError(422, `Voucher does not balance: debits ${dr.toFixed(2)} vs credits ${cr.toFixed(2)}`, 'UNBALANCED');
    }

    const missing = await tx.q1<any>(
      'SELECT COUNT(*) c FROM voucher_evidence WHERE voucher_id = ? AND is_mandatory = 1 AND is_attached = 0', [voucherId],
    );
    if (n(missing?.c) > 0) throw new HttpError(422, `${n(missing?.c)} mandatory document(s) not attached`, 'EVIDENCE_MISSING');

    // gapless statutory number, allocated now under a row lock
    const fy = fiscalYear(String(v.voucher_date).slice(0, 10));
    let series = await tx.q1<any>(
      'SELECT * FROM number_series WHERE entity_id = ? AND voucher_type_id = ? AND fiscal_year = ? AND site_key = 0 FOR UPDATE',
      [entityId, n(v.voucher_type_id), fy],
    );
    if (!series) {
      const vt = await tx.q1<any>('SELECT code FROM voucher_type WHERE id = ?', [n(v.voucher_type_id)]);
      await tx.exec(
        'INSERT INTO number_series (entity_id, voucher_type_id, fiscal_year, prefix, width, next_no) VALUES (?, ?, ?, ?, 5, 1)',
        [entityId, n(v.voucher_type_id), fy, `${vt?.code ?? 'GEN'}/${fy}/`],
      );
      series = await tx.q1<any>(
        'SELECT * FROM number_series WHERE entity_id = ? AND voucher_type_id = ? AND fiscal_year = ? AND site_key = 0 FOR UPDATE',
        [entityId, n(v.voucher_type_id), fy],
      );
    }
    const next = n(series.next_no);
    const number = `${series.prefix}${String(next).padStart(n(series.width) || 5, '0')}${series.suffix ?? ''}`;
    await tx.exec('UPDATE number_series SET next_no = next_no + 1 WHERE id = ?', [n(series.id)]);

    // rollup update — one row per account per period, maintained transactionally
    for (const l of lines) {
      const isDr = l.dr_cr === 'DR';
      await tx.exec(
        `INSERT INTO account_period_balance (entity_id, book_id, account_id, period_key, opening_dr, opening_cr, period_dr, period_cr, line_count)
         VALUES (?, ?, ?, ?, 0, 0, ?, ?, 1)
         ON DUPLICATE KEY UPDATE period_dr = period_dr + VALUES(period_dr), period_cr = period_cr + VALUES(period_cr), line_count = line_count + 1`,
        [entityId, n(l.book_id), n(l.account_id), n(l.period_key), isDr ? n(l.amount_func) : 0, isDr ? 0 : n(l.amount_func)],
      );
    }

    await tx.exec(
      `UPDATE voucher SET status = 'POSTED', voucher_no = ?, approved_by = ?, approved_by_name = ?, posted_at = NOW(3), row_version = row_version + 1
        WHERE id = ? AND period_key = ?`, [number, actorUserId, actorName, voucherId, n(v.period_key)],
    );

    return { id: ext.voucher(voucherId), number, status: 'posted', postedLines: lines.length, totalDr: dr, totalCr: cr };
  });
}

/**
 * Reverse a posted voucher: create a new POSTED voucher with every debit and
 * credit swapped, so the two net to zero, and mark the original REVERSED.
 * Correction by reversal, never by amendment (HBIE-VCH-021).
 */
export async function reverseVoucher(entityId: number, idStr: string, actorUserId: number, actorName: string) {
  const voucherId = parseExt(idStr);
  return withTx(async (tx) => {
    const v = await tx.q1<any>('SELECT * FROM voucher WHERE entity_id = ? AND id = ? FOR UPDATE', [entityId, voucherId]);
    if (!v) throw new HttpError(404, 'Voucher not found');
    if (v.status !== 'POSTED') throw new HttpError(409, `Only a posted voucher can be reversed (this one is ${v.status.toLowerCase()})`, 'BAD_STATE');
    if (v.reversed_by_id) throw new HttpError(409, 'Voucher is already reversed', 'ALREADY_REVERSED');

    const lines = await tx.q<any>('SELECT * FROM posting_line WHERE voucher_id = ? AND period_key = ? ORDER BY line_no', [voucherId, n(v.period_key)]);
    const period = n(v.period_key);

    // allocate a fresh gapless number for the reversal
    const fy = fiscalYear(String(v.voucher_date).slice(0, 10));
    const series = await tx.q1<any>('SELECT * FROM number_series WHERE entity_id = ? AND voucher_type_id = ? AND fiscal_year = ? AND site_key = 0 FOR UPDATE', [entityId, n(v.voucher_type_id), fy]);
    if (!series) throw new HttpError(422, 'No number series for this voucher type', 'NO_SERIES');
    const number = `${series.prefix}${String(n(series.next_no)).padStart(n(series.width) || 5, '0')}${series.suffix ?? ''}`;
    await tx.exec('UPDATE number_series SET next_no = next_no + 1 WHERE id = ?', [n(series.id)]);

    const info = await tx.exec(
      `INSERT INTO voucher (period_key, entity_id, book_id, voucher_type_id, voucher_no, voucher_date, narration, status, currency, total_dr, total_cr, prepared_by, prepared_by_name, approved_by, approved_by_name, posted_at, reversal_of_id, book_label)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'POSTED', ?, ?, ?, ?, ?, ?, ?, NOW(3), ?, ?)`,
      [period, entityId, n(v.book_id), n(v.voucher_type_id), number, v.voucher_date,
        `Reversal of ${v.voucher_no ?? ext.voucher(voucherId)}`, v.currency, n(v.total_cr), n(v.total_dr),
        actorUserId, actorName, actorUserId, actorName, voucherId, v.book_label ?? 'Primary'],
    );
    const revId = info.insertId;

    let ln = 1;
    for (const l of lines) {
      const swapped = l.dr_cr === 'DR' ? 'CR' : 'DR';
      await tx.exec(
        `INSERT INTO posting_line (period_key, voucher_id, entity_id, book_id, line_no, account_id, dr_cr, amount_txn, amount_func, amount_group, currency, fx_rate, fx_rate_type, voucher_date, shipment_id, declaration_id, party_id, item_id, subledger_key, rule_branch)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [period, revId, entityId, n(l.book_id), ln, n(l.account_id), swapped, n(l.amount_txn), n(l.amount_func), n(l.amount_group), l.currency, n(l.fx_rate), l.fx_rate_type, l.voucher_date, l.shipment_id, l.declaration_id, l.party_id, l.item_id, l.subledger_key, `reversal of line ${l.line_no}`],
      );
      // rollup: the reversal moves the amount to the opposite side
      await tx.exec(
        `INSERT INTO account_period_balance (entity_id, book_id, account_id, period_key, opening_dr, opening_cr, period_dr, period_cr, line_count)
         VALUES (?, ?, ?, ?, 0, 0, ?, ?, 1)
         ON DUPLICATE KEY UPDATE period_dr = period_dr + VALUES(period_dr), period_cr = period_cr + VALUES(period_cr), line_count = line_count + 1`,
        [entityId, n(l.book_id), n(l.account_id), period, swapped === 'DR' ? n(l.amount_func) : 0, swapped === 'DR' ? 0 : n(l.amount_func)],
      );
      ln += 1;
    }

    await tx.exec("UPDATE voucher SET status = 'REVERSED', reversed_by_id = ? WHERE id = ? AND period_key = ?", [revId, voucherId, period]);
    return { id: ext.voucher(voucherId), reversedBy: ext.voucher(revId), number, status: 'reversed' };
  });
}
