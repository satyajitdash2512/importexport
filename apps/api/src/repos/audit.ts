import { q, exec, n } from '../db/pool.js';

/** Append-only audit trail (tenant database). Never updated or deleted. */
export interface AuditEntry {
  entityId: number; userId?: number; username?: string; action: string;
  objectType: string; objectId?: number | null; objectRef?: string | null; reason?: string | null;
  fieldName?: string | null; oldValue?: string | null; newValue?: string | null;
}

export async function writeAudit(e: AuditEntry): Promise<void> {
  try {
    await exec(
      `INSERT INTO audit_log (entity_id, user_id, username, action, object_type, object_id, object_ref, field_name, old_value, new_value, reason)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [e.entityId, e.userId ?? null, e.username ?? null, e.action, e.objectType, e.objectId ?? null, e.objectRef ?? null, e.fieldName ?? null, e.oldValue ?? null, e.newValue ?? null, e.reason ?? null],
    );
  } catch { /* auditing must never break the operation it records */ }
}

export async function listAudit(entityId: number, opts: { objectType?: string; limit?: number; offset?: number } = {}) {
  const where = ['entity_id = ?']; const params: any[] = [entityId];
  if (opts.objectType) { where.push('object_type = ?'); params.push(opts.objectType); }
  const limit = Math.min(Math.max(opts.limit ?? 100, 1), 500);
  const offset = Math.max(opts.offset ?? 0, 0);
  const total = n((await q<any>(`SELECT COUNT(*) c FROM audit_log WHERE ${where.join(' AND ')}`, params))[0]?.c);
  const rows = await q<any>(
    `SELECT id, occurred_at, username, action, object_type, object_ref, field_name, old_value, new_value, reason
       FROM audit_log WHERE ${where.join(' AND ')} ORDER BY id DESC LIMIT ? OFFSET ?`, [...params, limit, offset],
  );
  return {
    list: rows.map((r) => ({
      id: n(r.id), at: r.occurred_at, user: r.username ?? '—', action: r.action, objectType: r.object_type,
      objectRef: r.object_ref ?? '', field: r.field_name ?? '', oldValue: r.old_value ?? '', newValue: r.new_value ?? '', reason: r.reason ?? '',
    })),
    total, limit, offset,
  };
}
