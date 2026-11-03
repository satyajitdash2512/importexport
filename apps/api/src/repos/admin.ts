/**
 * User / role administration — runs in the CONTROL database and is scoped to
 * the caller's tenant, so an admin manages only their own business's users.
 * Segregation of duties is enforced on role assignment.
 */
import { cq, cq1, cexec, q, n } from '../db/pool.js';
import { HttpError } from '../http/context.js';
import { hashPassword } from '../auth/jwt.js';

export async function listUsers(tenantId: number) {
  const users = await cq<any>(
    `SELECT id, username, full_name, email, is_external, is_active, last_login_at
       FROM app_user WHERE tenant_id = ? ORDER BY id`, [tenantId],
  );
  const out: any[] = [];
  for (const u of users) {
    const roles = await cq<{ code: string; name: string }>(
      'SELECT r.code, r.name FROM user_role ur JOIN role r ON r.id = ur.role_id WHERE ur.user_id = ?', [n(u.id)]);
    const entities = (await cq<{ entity_id: number }>('SELECT entity_id FROM user_entity_access WHERE user_id = ?', [n(u.id)])).map((e) => n(e.entity_id));
    out.push({
      id: n(u.id), username: u.username, fullName: u.full_name, email: u.email, external: Number(u.is_external) === 1,
      active: Number(u.is_active) === 1, lastLoginAt: u.last_login_at ?? null, roles: roles.map((r) => r.code), roleNames: roles.map((r) => r.name), entities,
    });
  }
  return out;
}

export async function listRoles() {
  const roles = await cq<any>('SELECT id, code, name, description FROM role ORDER BY id');
  const out: any[] = [];
  for (const r of roles) {
    const perms = (await cq<{ code: string }>('SELECT p.code FROM role_permission rp JOIN permission p ON p.id = rp.permission_id WHERE rp.role_id = ? ORDER BY p.code', [n(r.id)])).map((p) => p.code);
    out.push({ id: n(r.id), code: r.code, name: r.name, description: r.description, permissions: perms });
  }
  return out;
}

export async function listSod() {
  return cq<any>(
    `SELECT s.code, ra.code role_a, ra.name role_a_name, rb.code role_b, rb.name role_b_name, s.risk
       FROM sod_conflict s JOIN role ra ON ra.id = s.role_a_id JOIN role rb ON rb.id = s.role_b_id ORDER BY s.code`);
}

/** Grant a role within the caller's tenant, refusing a segregation-of-duties breach. */
export async function assignRole(tenantId: number, userId: number, roleCode: string) {
  const user = await cq1<any>('SELECT id, tenant_id, full_name FROM app_user WHERE id = ?', [userId]);
  if (!user) throw new HttpError(404, 'User not found');
  if (n(user.tenant_id) !== tenantId) throw new HttpError(403, 'User belongs to another tenant', 'CROSS_TENANT');
  const role = await cq1<any>('SELECT id, code, name FROM role WHERE code = ?', [roleCode]);
  if (!role) throw new HttpError(404, `Role ${roleCode} not found`);

  const already = await cq1<any>('SELECT 1 x FROM user_role WHERE user_id = ? AND role_id = ?', [userId, n(role.id)]);
  if (already) return { assigned: false, reason: 'already held', roles: await rolesOf(userId) };

  const held = await cq<{ role_id: number; code: string; name: string }>(
    'SELECT ur.role_id, r.code, r.name FROM user_role ur JOIN role r ON r.id = ur.role_id WHERE ur.user_id = ?', [userId]);
  for (const hr of held) {
    const conflict = await cq1<any>(
      `SELECT s.code, s.risk FROM sod_conflict s
        WHERE (s.role_a_id = ? AND s.role_b_id = ?) OR (s.role_a_id = ? AND s.role_b_id = ?) LIMIT 1`,
      [n(role.id), n(hr.role_id), n(hr.role_id), n(role.id)]);
    if (conflict) throw new HttpError(409, `Segregation of duties (${conflict.code}): "${role.name}" cannot be held with "${hr.name}". ${conflict.risk}`, 'SOD_CONFLICT');
  }

  await cexec('INSERT INTO user_role (user_id, role_id) VALUES (?, ?)', [userId, n(role.id)]);
  return { assigned: true, roleCode, roles: await rolesOf(userId) };
}

async function rolesOf(userId: number): Promise<string[]> {
  return (await cq<{ code: string }>('SELECT r.code FROM user_role ur JOIN role r ON r.id = ur.role_id WHERE ur.user_id = ?', [userId])).map((r) => r.code);
}

/** Legal entities within the tenant (read from the tenant database). */
export async function listEntities() {
  return (await q<any>('SELECT id, code, name FROM legal_entity ORDER BY id')).map((e) => ({ id: n(e.id), code: e.code, name: e.name }));
}

/** Create a user in the caller's tenant, with an initial role and entity grant. */
export async function createUser(tenantId: number, body: any) {
  const { username, fullName, email, roleCode, external, password, entityId } = body ?? {};
  if (!username || !fullName || !email) throw new HttpError(422, 'username, fullName and email are required');
  const dupe = await cq1<any>('SELECT 1 x FROM app_user WHERE tenant_id = ? AND username = ?', [tenantId, username]);
  if (dupe) throw new HttpError(409, `Username "${username}" already exists in this tenant`, 'DUPLICATE');
  const hash = hashPassword(String(password || 'hbtrade123'));
  const info = await cexec(
    'INSERT INTO app_user (tenant_id, username, email, full_name, password_hash, is_external) VALUES (?, ?, ?, ?, ?, ?)',
    [tenantId, username, email, fullName, hash, external ? 1 : 0],
  );
  const userId = info.insertId;
  if (roleCode) {
    const role = await cq1<any>('SELECT id FROM role WHERE code = ?', [roleCode]);
    if (role) await cexec('INSERT INTO user_role (user_id, role_id) VALUES (?, ?)', [userId, n(role.id)]);
  }
  await cexec('INSERT INTO user_entity_access (user_id, entity_id) VALUES (?, ?)', [userId, Number(entityId) || 1]);
  return { id: userId, username, created: true };
}

export async function setUserActive(tenantId: number, userId: number, active: boolean) {
  const u = await cq1<any>('SELECT tenant_id FROM app_user WHERE id = ?', [userId]);
  if (!u || n(u.tenant_id) !== tenantId) throw new HttpError(404, 'User not found');
  await cexec('UPDATE app_user SET is_active = ? WHERE id = ?', [active ? 1 : 0, userId]);
  return { id: userId, active };
}

export async function resetPassword(tenantId: number, userId: number, password: string) {
  const u = await cq1<any>('SELECT tenant_id FROM app_user WHERE id = ?', [userId]);
  if (!u || n(u.tenant_id) !== tenantId) throw new HttpError(404, 'User not found');
  if (!password || String(password).length < 6) throw new HttpError(422, 'Password must be at least 6 characters');
  await cexec('UPDATE app_user SET password_hash = ?, failed_logins = 0, locked_until = NULL WHERE id = ?', [hashPassword(String(password)), userId]);
  // revoke all refresh tokens so the change takes effect everywhere
  await cexec('UPDATE refresh_token SET revoked_at = NOW(3) WHERE user_id = ? AND revoked_at IS NULL', [userId]);
  return { id: userId, reset: true };
}

export async function revokeRole(tenantId: number, userId: number, roleCode: string) {
  const u = await cq1<any>('SELECT tenant_id FROM app_user WHERE id = ?', [userId]);
  if (!u || n(u.tenant_id) !== tenantId) throw new HttpError(404, 'User not found');
  const role = await cq1<any>('SELECT id FROM role WHERE code = ?', [roleCode]);
  if (!role) throw new HttpError(404, 'Role not found');
  await cexec('DELETE FROM user_role WHERE user_id = ? AND role_id = ?', [userId, n(role.id)]);
  return { id: userId, roles: await rolesOf(userId) };
}

export async function grantEntity(tenantId: number, userId: number, entityId: number) {
  const u = await cq1<any>('SELECT tenant_id FROM app_user WHERE id = ?', [userId]);
  if (!u || n(u.tenant_id) !== tenantId) throw new HttpError(404, 'User not found');
  await cexec('INSERT IGNORE INTO user_entity_access (user_id, entity_id) VALUES (?, ?)', [userId, entityId]);
  return { id: userId, granted: entityId };
}
export async function revokeEntity(tenantId: number, userId: number, entityId: number) {
  await cexec('DELETE FROM user_entity_access WHERE user_id = ? AND entity_id = ?', [userId, entityId]);
  return { id: userId, revoked: entityId };
}
