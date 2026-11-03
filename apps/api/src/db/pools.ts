import { AsyncLocalStorage } from 'node:async_hooks';
import mysql from 'mysql2/promise';
import { config } from './env.js';

/**
 * Connection routing for database-per-tenant multitenancy.
 *
 * - The CONTROL pool talks to hb_control (tenants, users, RBAC, refresh tokens).
 * - Each tenant has its OWN pool, opened lazily against that tenant's database
 *   and cached. A business query in one tenant's pool physically cannot reach
 *   another tenant's data — they are different databases.
 * - The active tenant pool for a request is carried in AsyncLocalStorage, set by
 *   the auth middleware, so the repositories keep calling q()/withTx() without
 *   threading a connection through every function; the helpers resolve the
 *   right pool from the request context.
 */

function poolFor(database: string) {
  return mysql.createPool({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database,
    connectionLimit: config.db.connectionLimit,
    waitForConnections: true,
    queueLimit: 0,
    namedPlaceholders: true,
    dateStrings: true,
    timezone: 'Z',
  });
}

/** The control-plane pool (directory + auth). */
export const controlPool = poolFor(config.db.controlDatabase);

const tenantPools = new Map<string, mysql.Pool>();
/** Lazily open (and cache) the pool for a tenant's business database. */
export function getTenantPool(dbName: string): mysql.Pool {
  let p = tenantPools.get(dbName);
  if (!p) { p = poolFor(dbName); tenantPools.set(dbName, p); }
  return p;
}

interface Ctx { pool: mysql.Pool; tenantDb: string }
const als = new AsyncLocalStorage<Ctx>();

/** Run `fn` (and everything it awaits) with this tenant pool as the active one. */
export function runWithTenant<T>(dbName: string, fn: () => T): T {
  return als.run({ pool: getTenantPool(dbName), tenantDb: dbName }, fn);
}

/** The tenant pool for the current request. Throws if called outside one. */
export function activePool(): mysql.Pool {
  const ctx = als.getStore();
  if (!ctx) throw new Error('No active tenant context — a business query ran outside a tenant-scoped request.');
  return ctx.pool;
}
export function activeTenantDb(): string | null { return als.getStore()?.tenantDb ?? null; }

export async function closeAllPools(): Promise<void> {
  await controlPool.end();
  await Promise.all([...tenantPools.values()].map((p) => p.end()));
}
