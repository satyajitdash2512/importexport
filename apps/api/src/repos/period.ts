import { q, q1, exec, n } from '../db/pool.js';
import { HttpError } from '../http/context.js';
import { writeAudit } from './audit.js';

/** Accounting periods for the primary book, with lock/unlock. */
export async function listPeriods(entityId: number) {
  const rows = await q<any>('SELECT period_key, fiscal_year, starts_on, ends_on, status, lock_override_reason FROM accounting_period WHERE entity_id = ? AND book_id = 1 ORDER BY period_key', [entityId]);
  return rows.map((r) => ({
    periodKey: n(r.period_key), fiscalYear: r.fiscal_year, startsOn: String(r.starts_on).slice(0, 10), endsOn: String(r.ends_on).slice(0, 10),
    status: r.status, lockReason: r.lock_override_reason ?? null,
  }));
}

export async function setPeriodStatus(entityId: number, periodKey: number, status: 'OPEN' | 'SOFT_CLOSED' | 'HARD_CLOSED', actor: { userId?: number; username?: string }, reason?: string) {
  const p = await q1<any>('SELECT status FROM accounting_period WHERE entity_id = ? AND book_id = 1 AND period_key = ?', [entityId, periodKey]);
  if (!p) throw new HttpError(404, 'Period not found');
  if (p.status === 'HARD_CLOSED' && status !== 'OPEN') throw new HttpError(409, 'Period is hard-closed', 'LOCKED');
  await exec(
    'UPDATE accounting_period SET status = ?, lock_override_reason = ?, locked_by = ?, locked_at = NOW(3) WHERE entity_id = ? AND book_id = 1 AND period_key = ?',
    [status, reason ?? null, actor.userId ?? null, entityId, periodKey],
  );
  await writeAudit({ entityId, userId: actor.userId, username: actor.username, action: `PERIOD_${status}`, objectType: 'accounting_period', objectRef: String(periodKey), reason });
  return { periodKey, status };
}
