import jwt from 'jsonwebtoken';
import { createHash, randomBytes } from 'node:crypto';
import bcrypt from 'bcryptjs';
import { config } from '../db/env.js';

/** What we pack into the access token. Permissions and entity ids travel in the
 *  token so an authorisation check is a set lookup, not a database round-trip. */
export interface AccessClaims {
  sub: number;            // user id (in the control database)
  username: string;
  fullName: string;
  tenantId: number;       // which business
  tenantCode: string;
  tenantDb: string;       // the tenant's business database — every query routes here
  roles: string[];
  perms: string[];
  entities: number[];     // legal_entity ids within the tenant the user may act on
  external: boolean;
}

export function signAccess(claims: AccessClaims): string {
  return jwt.sign(claims, config.auth.jwtSecret, { expiresIn: config.auth.accessTtlSeconds, algorithm: 'HS256' });
}

export function verifyAccess(token: string): AccessClaims {
  return jwt.verify(token, config.auth.jwtSecret, { algorithms: ['HS256'] }) as unknown as AccessClaims;
}

/** Refresh tokens are opaque random strings; only their SHA-256 is stored, so a
 *  database leak does not yield usable tokens. The JWT wrapper carries the user
 *  id and a jti we can revoke. */
export function newRefreshToken(): { token: string; hash: string } {
  const token = randomBytes(48).toString('base64url');
  const hash = createHash('sha256').update(token).digest('hex');
  return { token, hash };
}

export function hashRefresh(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export function comparePassword(plain: string, hash: string): boolean {
  return bcrypt.compareSync(plain, hash);
}

export function hashPassword(plain: string): string {
  return bcrypt.hashSync(plain, config.auth.bcryptRounds);
}
