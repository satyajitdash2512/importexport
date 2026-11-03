import { q, q1, exec, n } from '../db/pool.js';
import { HttpError } from '../http/context.js';
import { writeAudit } from './audit.js';

/**
 * External connectors — SIMULATED. Real gateways (ICEGATE customs, EDPMS export
 * realisation, the bank SWIFT host) need credentials and endpoints this build
 * does not have. Rather than fake success, these move a message through the
 * SAME lifecycle a real gateway would (QUEUED → SENT → ACKED → ACCEPTED /
 * QUERIED / REJECTED), record every step in integration_log, and return the
 * gateway's (simulated) reference. The API shape is production-ready; swapping
 * the simulate() call for a real HTTP client is the only change needed.
 */
function gatewayRef(prefix: string, seed: number): string {
  // deterministic pseudo-id (no Math.random — keep it reproducible)
  const n2 = ((seed * 2654435761) % 900000 + 100000) | 0;
  return `${prefix}${Math.abs(n2)}`;
}

async function logMessage(entityId: number, m: {
  channel: string; direction: 'OUT' | 'IN'; objectType: string; objectId?: number | null; objectRef?: string | null;
  messageType: string; requestRef?: string; gatewayRef?: string; status: string; statusDetail?: string;
  requestSummary?: string; responseSummary?: string; userId?: number;
}) {
  const info = await exec(
    `INSERT INTO integration_log (entity_id, channel, direction, object_type, object_id, object_ref, message_type, request_ref, gateway_ref, status, status_detail, request_summary, response_summary, created_by)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [entityId, m.channel, m.direction, m.objectType, m.objectId ?? null, m.objectRef ?? null, m.messageType, m.requestRef ?? null, m.gatewayRef ?? null, m.status, m.statusDetail ?? null, m.requestSummary ?? null, m.responseSummary ?? null, m.userId ?? null],
  );
  return n(info.insertId);
}

/** Transmit a declaration (shipping bill / bill of entry) to ICEGATE. */
export async function transmitDeclaration(entityId: number, declIdStr: string, actor: { userId?: number; username?: string }) {
  const id = Number(String(declIdStr).replace(/\D/g, ''));
  const d = await q1<any>('SELECT id, period_key, declaration_no, direction, status FROM declaration WHERE entity_id = ? AND id = ?', [entityId, id]);
  if (!d) throw new HttpError(404, 'Declaration not found');
  const msgType = d.direction === 'EXPORT' ? 'SB_TRANSMIT' : 'BOE_TRANSMIT';
  const gw = gatewayRef('ICE', id + n(d.period_key));
  // simulate the gateway accepting the message and returning a job number
  await logMessage(entityId, { channel: 'ICEGATE', direction: 'OUT', objectType: 'declaration', objectId: id, objectRef: d.declaration_no, messageType: msgType, requestRef: `REQ-${id}`, gatewayRef: gw, status: 'SENT', statusDetail: 'Message accepted by gateway (simulated)', requestSummary: `${msgType} ${d.declaration_no}`, userId: actor.userId });
  await exec('UPDATE declaration SET status = ?, authority_ref = ? WHERE entity_id = ? AND id = ? AND period_key = ?', ['TRANSMITTED', gw, entityId, id, n(d.period_key)]);
  await writeAudit({ entityId, userId: actor.userId, username: actor.username, action: 'TRANSMIT', objectType: 'declaration', objectId: id, objectRef: d.declaration_no, newValue: gw });
  return { declaration: declIdStr, channel: 'ICEGATE', gatewayRef: gw, status: 'TRANSMITTED', simulated: true };
}

/** Poll a declaration's status from ICEGATE (simulated progression). */
export async function pollDeclarationStatus(entityId: number, declIdStr: string) {
  const id = Number(String(declIdStr).replace(/\D/g, ''));
  const last = await q1<any>("SELECT * FROM integration_log WHERE entity_id = ? AND object_type='declaration' AND object_id = ? AND channel='ICEGATE' ORDER BY id DESC LIMIT 1", [entityId, id]);
  if (!last) throw new HttpError(409, 'Nothing transmitted for this declaration yet', 'NOT_TRANSMITTED');
  // simulate the next state in the lifecycle
  const progression: Record<string, string> = { SENT: 'ACKED', ACKED: 'ACCEPTED', ACCEPTED: 'ACCEPTED' };
  const nextStatus = progression[last.status] ?? 'ACCEPTED';
  const detail = nextStatus === 'ACKED' ? 'Gateway acknowledged; under assessment' : 'Assessed and accepted (LEO/OOC issued) — simulated';
  await logMessage(entityId, { channel: 'ICEGATE', direction: 'IN', objectType: 'declaration', objectId: id, objectRef: last.object_ref, messageType: 'BOE_STATUS', gatewayRef: last.gateway_ref, status: nextStatus, statusDetail: detail, responseSummary: detail });
  return { declaration: declIdStr, status: nextStatus, detail, simulated: true };
}

/** Query EDPMS for realisation status of an export declaration (simulated). */
export async function edpmsStatus(entityId: number, declIdStr: string, actor: { userId?: number }) {
  const id = Number(String(declIdStr).replace(/\D/g, ''));
  const d = await q1<any>('SELECT id, declaration_no FROM declaration WHERE entity_id = ? AND id = ?', [entityId, id]);
  if (!d) throw new HttpError(404, 'Declaration not found');
  const gw = gatewayRef('EDPMS', id);
  const outcome = id % 3 === 0 ? { status: 'QUERIED', detail: 'Realisation overdue beyond the permitted period (simulated)' } : { status: 'ACCEPTED', detail: 'Realisation matched against inward remittance (simulated)' };
  await logMessage(entityId, { channel: 'EDPMS', direction: 'IN', objectType: 'declaration', objectId: id, objectRef: d.declaration_no, messageType: 'IRM_MATCH', gatewayRef: gw, status: outcome.status, statusDetail: outcome.detail, responseSummary: outcome.detail, userId: actor.userId });
  return { declaration: declIdStr, channel: 'EDPMS', ...outcome, simulated: true };
}

/** Send an instrument (LC/guarantee) message to the bank host (simulated SWIFT). */
export async function bankSend(entityId: number, instrIdStr: string, actor: { userId?: number; username?: string }) {
  const id = Number(String(instrIdStr).replace(/\D/g, ''));
  const i = await q1<any>('SELECT id, instrument_no, instrument_type FROM instrument WHERE entity_id = ? AND id = ?', [entityId, id]);
  if (!i) throw new HttpError(404, 'Instrument not found');
  const mt = i.instrument_type?.startsWith('LC') ? 'MT700' : 'MT760';
  const gw = gatewayRef('SWIFT', id);
  await logMessage(entityId, { channel: 'BANK_HOST', direction: 'OUT', objectType: 'instrument', objectId: id, objectRef: i.instrument_no, messageType: mt, gatewayRef: gw, status: 'SENT', statusDetail: `${mt} despatched to issuing bank (simulated)`, requestSummary: `${mt} ${i.instrument_no}`, userId: actor.userId });
  await writeAudit({ entityId, userId: actor.userId, username: actor.username, action: 'BANK_SEND', objectType: 'instrument', objectId: id, objectRef: i.instrument_no, newValue: `${mt}/${gw}` });
  return { instrument: instrIdStr, channel: 'BANK_HOST', messageType: mt, gatewayRef: gw, status: 'SENT', simulated: true };
}

export async function listIntegrationLog(entityId: number, channel?: string) {
  const where = ['entity_id = ?']; const params: any[] = [entityId];
  if (channel) { where.push('channel = ?'); params.push(channel); }
  const rows = await q<any>(`SELECT * FROM integration_log WHERE ${where.join(' AND ')} ORDER BY id DESC LIMIT 200`, params);
  return rows.map((r) => ({
    id: n(r.id), channel: r.channel, direction: r.direction, objectType: r.object_type, objectRef: r.object_ref,
    messageType: r.message_type, gatewayRef: r.gateway_ref, status: r.status, detail: r.status_detail,
    at: r.created_at, simulated: n(r.simulated) === 1,
  }));
}
