import type { Request, Response, NextFunction } from 'express';
import { verifyAccess, type AccessClaims } from '../auth/jwt.js';
import { runWithTenant } from '../db/pools.js';

/** Augment Express Request with the authenticated principal and active entity. */
export interface AuthedRequest extends Request {
  auth?: AccessClaims;
  /** The legal entity the request operates on — validated against the token's
   *  entity grants, so a caller can never read another tenant's rows. */
  entityId?: number;
}

export class HttpError extends Error {
  constructor(public status: number, message: string, public code?: string) { super(message); }
}

/** Require a valid access token. Populates req.auth and req.entityId. */
export function requireAuth(req: AuthedRequest, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) throw new HttpError(401, 'Authentication required', 'NO_TOKEN');
  let claims: AccessClaims;
  try {
    claims = verifyAccess(header.slice(7));
  } catch (e: any) {
    throw new HttpError(401, e?.name === 'TokenExpiredError' ? 'Access token expired' : 'Invalid token', 'BAD_TOKEN');
  }
  req.auth = claims;

  // Resolve the active legal entity within the tenant: an X-Entity-Id header if
  // given, else the user's first grant. Either way it MUST be one the token
  // authorises.
  const requested = Number(req.header('X-Entity-Id') || req.query.entityId || claims.entities[0]);
  if (!claims.entities.includes(requested)) {
    throw new HttpError(403, `No access to entity ${requested}`, 'ENTITY_FORBIDDEN');
  }
  req.entityId = requested;

  // Route every downstream business query to THIS tenant's database. The store
  // propagates across the async handler chain, so repositories that call q()
  // hit the tenant's own database with no per-call plumbing.
  runWithTenant(claims.tenantDb, () => next());
}

/** Require a specific permission (resource:action). Use after requireAuth. */
export function requirePermission(permission: string) {
  return (req: AuthedRequest, _res: Response, next: NextFunction) => {
    if (!req.auth) throw new HttpError(401, 'Authentication required', 'NO_TOKEN');
    if (!req.auth.perms.includes(permission)) {
      throw new HttpError(403, `Missing permission: ${permission}`, 'FORBIDDEN');
    }
    next();
  };
}

/** Require any one of several permissions. */
export function requireAnyPermission(...permissions: string[]) {
  return (req: AuthedRequest, _res: Response, next: NextFunction) => {
    if (!req.auth) throw new HttpError(401, 'Authentication required', 'NO_TOKEN');
    if (!permissions.some((p) => req.auth!.perms.includes(p))) {
      throw new HttpError(403, `Missing one of: ${permissions.join(', ')}`, 'FORBIDDEN');
    }
    next();
  };
}

/** Wrap an async route so a thrown HttpError (or any error) reaches the error mw. */
export function h(fn: (req: AuthedRequest, res: Response) => Promise<unknown>) {
  return (req: AuthedRequest, res: Response, next: NextFunction) => {
    fn(req, res).catch(next);
  };
}

// ---- pagination helpers ---------------------------------------------------
export interface PageParams { limit: number; offset: number; sort?: string; dir: 'ASC' | 'DESC'; q?: string; }

export function pageParams(req: Request, defaultSort?: string): PageParams {
  const limit = Math.min(Math.max(Number(req.query.limit) || 25, 1), 200);
  const offset = Math.max(Number(req.query.offset) || 0, 0);
  const dir = String(req.query.dir).toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
  const sort = (req.query.sort ? String(req.query.sort) : defaultSort) || undefined;
  const q = req.query.q ? String(req.query.q).trim() : undefined;
  return { limit, offset, sort, dir, q };
}

/** Validate a caller-supplied sort column against an allow-list to stop
 *  injection through ORDER BY (which cannot be parameterised). */
export function safeSort(sort: string | undefined, allowed: Record<string, string>, fallback: string): string {
  if (sort && allowed[sort]) return allowed[sort];
  return fallback;
}
