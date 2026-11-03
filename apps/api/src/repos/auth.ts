import { cq, cq1, cexec, n } from '../db/pool.js';
import { config } from '../db/env.js';
import { comparePassword, signAccess, newRefreshToken, hashRefresh, type AccessClaims } from '../auth/jwt.js';
import { HttpError } from '../http/context.js';

/**
 * Authentication runs entirely in the CONTROL database. A login resolves the
 * user's tenant, and the issued token carries the tenant's business database
 * name so every subsequent request routes to the right database.
 */
interface UserRow {
  id: number; tenant_id: number; username: string; full_name: string; password_hash: string;
  is_active: number; is_external: number; failed_logins: number; locked_until: string | null;
}

export async function loadClaims(userId: number): Promise<AccessClaims> {
  const u = await cq1<UserRow>('SELECT * FROM app_user WHERE id = ?', [userId]);
  if (!u) throw new HttpError(404, 'User not found');
  const tenant = await cq1<{ id: number; code: string; db_name: string; status: string }>('SELECT id, code, db_name, status FROM tenant WHERE id = ?', [n(u.tenant_id)]);
  if (!tenant) throw new HttpError(403, 'User has no tenant');
  if (tenant.status !== 'ACTIVE') throw new HttpError(403, `Tenant ${tenant.code} is ${tenant.status.toLowerCase()}`, 'TENANT_INACTIVE');

  const roles = (await cq<{ code: string }>('SELECT r.code FROM user_role ur JOIN role r ON r.id = ur.role_id WHERE ur.user_id = ?', [userId])).map((r) => r.code);
  const perms = (await cq<{ code: string }>(
    `SELECT DISTINCT p.code FROM user_role ur
       JOIN role_permission rp ON rp.role_id = ur.role_id
       JOIN permission p ON p.id = rp.permission_id
      WHERE ur.user_id = ?`, [userId])).map((r) => r.code);
  const entities = (await cq<{ entity_id: number }>('SELECT entity_id FROM user_entity_access WHERE user_id = ?', [userId])).map((r) => n(r.entity_id));

  return {
    sub: userId, username: u.username, fullName: u.full_name,
    tenantId: n(tenant.id), tenantCode: tenant.code, tenantDb: tenant.db_name,
    roles, perms, entities, external: !!u.is_external,
  };
}

export async function login(username: string, password: string, tenantCode?: string) {
  // username is unique per tenant, so disambiguate by tenant when given
  const u = tenantCode
    ? await cq1<UserRow>('SELECT au.* FROM app_user au JOIN tenant t ON t.id = au.tenant_id WHERE au.username = ? AND t.code = ?', [username, tenantCode])
    : await cq1<UserRow>('SELECT * FROM app_user WHERE username = ? LIMIT 1', [username]);
  if (!u || !u.is_active) throw new HttpError(401, 'Invalid credentials', 'BAD_CREDENTIALS');
  if (u.locked_until && new Date(u.locked_until) > new Date()) throw new HttpError(423, 'Account locked after repeated failures. Try later.', 'LOCKED');
  if (!comparePassword(password, u.password_hash)) {
    const failed = n(u.failed_logins) + 1;
    const lock = failed >= 5 ? 'DATE_ADD(NOW(3), INTERVAL 15 MINUTE)' : 'NULL';
    await cexec(`UPDATE app_user SET failed_logins = ?, locked_until = ${lock} WHERE id = ?`, [failed, u.id]);
    throw new HttpError(401, 'Invalid credentials', 'BAD_CREDENTIALS');
  }
  await cexec('UPDATE app_user SET failed_logins = 0, locked_until = NULL, last_login_at = NOW(3) WHERE id = ?', [u.id]);
  return issueTokens(u.id);
}

export async function issueTokens(userId: number) {
  const claims = await loadClaims(userId);
  const access = signAccess(claims);
  const { token: refresh, hash } = newRefreshToken();
  const expires = new Date(Date.now() + config.auth.refreshTtlSeconds * 1000);
  await cexec('INSERT INTO refresh_token (user_id, token_hash, expires_at) VALUES (?, ?, ?)', [userId, hash, expires.toISOString().slice(0, 23).replace('T', ' ')]);
  return {
    accessToken: access, refreshToken: refresh, expiresIn: config.auth.accessTtlSeconds,
    user: {
      id: claims.sub, username: claims.username, fullName: claims.fullName,
      tenantId: claims.tenantId, tenantCode: claims.tenantCode,
      roles: claims.roles, perms: claims.perms, entities: claims.entities, external: claims.external,
    },
  };
}

export async function refresh(presented: string) {
  const hash = hashRefresh(presented);
  const row = await cq1<{ id: number; user_id: number; expires_at: string; revoked_at: string | null }>(
    'SELECT id, user_id, expires_at, revoked_at FROM refresh_token WHERE token_hash = ?', [hash]);
  if (!row || row.revoked_at || new Date(row.expires_at) < new Date()) throw new HttpError(401, 'Refresh token invalid or expired', 'BAD_REFRESH');
  await cexec('UPDATE refresh_token SET revoked_at = NOW(3) WHERE id = ?', [row.id]);
  return issueTokens(n(row.user_id));
}

export async function logout(presented: string) {
  await cexec('UPDATE refresh_token SET revoked_at = NOW(3) WHERE token_hash = ? AND revoked_at IS NULL', [hashRefresh(presented)]);
}
