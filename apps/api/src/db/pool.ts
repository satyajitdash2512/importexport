import mysql from 'mysql2/promise';
import { controlPool, activePool } from './pools.js';

/**
 * Query helpers. The business helpers (q/q1/exec/withTx) run against the ACTIVE
 * TENANT pool resolved from the request context (see pools.ts) — so a repository
 * that calls q() automatically hits the right tenant's database. The control
 * helpers (cq/cq1/cexec) run against hb_control for auth and administration.
 *
 * DECIMAL/BIGINT come back as strings (no float rounding); repositories coerce
 * at the boundary with n()/nOrNull().
 */
export type Row = Record<string, any>;

// ---- tenant (active-request) helpers --------------------------------------
export async function q<T = Row>(sql: string, params?: Record<string, any> | any[]): Promise<T[]> {
  const [rows] = await activePool().query(sql, params as any);
  return rows as T[];
}
export async function q1<T = Row>(sql: string, params?: Record<string, any> | any[]): Promise<T | null> {
  const rows = await q<T>(sql, params);
  return rows.length ? rows[0] : null;
}
export async function exec(sql: string, params?: Record<string, any> | any[]): Promise<mysql.ResultSetHeader> {
  const [res] = await activePool().query(sql, params as any);
  return res as mysql.ResultSetHeader;
}

// ---- control-plane helpers ------------------------------------------------
export async function cq<T = Row>(sql: string, params?: Record<string, any> | any[]): Promise<T[]> {
  const [rows] = await controlPool.query(sql, params as any);
  return rows as T[];
}
export async function cq1<T = Row>(sql: string, params?: Record<string, any> | any[]): Promise<T | null> {
  const rows = await cq<T>(sql, params);
  return rows.length ? rows[0] : null;
}
export async function cexec(sql: string, params?: Record<string, any> | any[]): Promise<mysql.ResultSetHeader> {
  const [res] = await controlPool.query(sql, params as any);
  return res as mysql.ResultSetHeader;
}

// ---- transactions on the active tenant pool -------------------------------
export interface Tx {
  q<T = Row>(sql: string, params?: Record<string, any> | any[]): Promise<T[]>;
  q1<T = Row>(sql: string, params?: Record<string, any> | any[]): Promise<T | null>;
  exec(sql: string, params?: Record<string, any> | any[]): Promise<mysql.ResultSetHeader>;
}

export async function withTx<T>(fn: (tx: Tx) => Promise<T>): Promise<T> {
  const conn = await activePool().getConnection();
  try {
    await conn.beginTransaction();
    const tx: Tx = {
      async q<R = Row>(sql: string, params?: any) { const [r] = await conn.query(sql, params); return r as R[]; },
      async q1<R = Row>(sql: string, params?: any) { const [r] = await conn.query(sql, params); const a = r as R[]; return a.length ? a[0] : null; },
      async exec(sql: string, params?: any) { const [r] = await conn.query(sql, params); return r as mysql.ResultSetHeader; },
    };
    const out = await fn(tx);
    await conn.commit();
    return out;
  } catch (e) {
    try { await conn.rollback(); } catch { /* ignore */ }
    throw e;
  } finally {
    conn.release();
  }
}

export function n(v: unknown): number {
  if (v === null || v === undefined) return 0;
  const x = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(x) ? x : 0;
}
export function nOrNull(v: unknown): number | null {
  if (v === null || v === undefined) return null;
  const x = Number(v);
  return Number.isFinite(x) ? x : null;
}
