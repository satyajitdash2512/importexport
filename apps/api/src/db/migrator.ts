import { readdir, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import mysql from 'mysql2/promise';
import { config } from './env.js';

const HERE = dirname(fileURLToPath(import.meta.url));
export const MIGRATIONS_ROOT = join(HERE, '..', '..', 'db', 'migrations');

/** Split a .sql file into statements, honouring `DELIMITER` directives. */
export function splitSql(sql: string): string[] {
  const stmts: string[] = [];
  let delim = ';';
  let buf = '';
  for (const rawLine of sql.split('\n')) {
    const dm = /^\s*DELIMITER\s+(\S+)\s*$/i.exec(rawLine);
    if (dm) { if (buf.trim()) { stmts.push(buf); buf = ''; } delim = dm[1]; continue; }
    buf += `${rawLine}\n`;
    const code = rawLine.replace(/--.*$/, '').trimEnd();
    if (code.length && code.endsWith(delim) && !/^\s*--/.test(rawLine)) {
      const s = buf.trimEnd().slice(0, -delim.length);
      if (s.trim()) stmts.push(s);
      buf = '';
    }
  }
  if (buf.trim()) stmts.push(buf);
  return stmts;
}

async function adminConn(database?: string) {
  return mysql.createConnection({ host: config.db.host, port: config.db.port, user: config.db.adminUser, password: config.db.adminPassword, database, multipleStatements: true });
}
async function appConn(database: string) {
  return mysql.createConnection({ host: config.db.host, port: config.db.port, user: config.db.user, password: config.db.password, database, multipleStatements: true });
}

/** Best-effort create + grant (needs privileged admin; tolerated if unavailable). */
export async function ensureDatabase(dbName: string, fresh = false, log: (s: string) => void = () => {}): Promise<void> {
  let admin: mysql.Connection | null = null;
  try { admin = await adminConn(); } catch (e: any) { log(`  (admin connect failed: ${e.code || e.message}; assuming ${dbName} exists)`); return; }
  try {
    if (fresh) { await admin.query(`DROP DATABASE IF EXISTS \`${dbName}\``); }
    await admin.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`);
    await admin.query(`CREATE USER IF NOT EXISTS '${config.db.user}'@'%' IDENTIFIED BY '${config.db.password}'`);
    await admin.query(`GRANT ALL PRIVILEGES ON \`${dbName}\`.* TO '${config.db.user}'@'%'`);
    await admin.query('FLUSH PRIVILEGES');
  } catch (e: any) { log(`  (provisioning partially skipped for ${dbName}: ${e.code || e.message})`); } finally { await admin.end(); }
}

async function connFor(dbName: string) {
  try { return await adminConn(dbName); } catch { return appConn(dbName); }
}

export interface ApplyResult { applied: string[]; skipped: number }

/** Apply every *.sql in `dir` to `dbName`, tracked in schema_migration. */
export async function applyDir(dbName: string, dir: string, opts: { statusOnly?: boolean; log?: (s: string) => void } = {}): Promise<ApplyResult> {
  const log = opts.log ?? (() => {});
  const conn = await connFor(dbName);
  const applied: string[] = [];
  try {
    await conn.query(`CREATE TABLE IF NOT EXISTS schema_migration (
      filename VARCHAR(200) NOT NULL, checksum CHAR(64) NOT NULL,
      applied_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), ms INT UNSIGNED NOT NULL DEFAULT 0,
      PRIMARY KEY (filename)) ENGINE=InnoDB`);
    const [rows] = await conn.query('SELECT filename, checksum FROM schema_migration');
    const done = new Map((rows as any[]).map((r) => [r.filename, r.checksum]));
    const files = (await readdir(dir)).filter((f) => f.endsWith('.sql')).sort();
    let skipped = 0;
    for (const f of files) {
      const sql = await readFile(join(dir, f), 'utf8');
      const checksum = createHash('sha256').update(sql).digest('hex');
      if (done.get(f) === checksum) { skipped += 1; continue; }
      if (done.has(f)) throw new Error(`${dbName}/${f} changed after being applied`);
      if (opts.statusOnly) { log(`  PENDING ${dbName}/${f}`); continue; }
      const t0 = Date.now();
      for (const stmt of splitSql(sql)) await conn.query(stmt);
      const ms = Date.now() - t0;
      await conn.query('INSERT INTO schema_migration (filename, checksum, ms) VALUES (?, ?, ?)', [f, checksum, ms]);
      log(`  applied ${dbName}/${f} (${ms} ms)`);
      applied.push(f);
    }
    return { applied, skipped };
  } finally { await conn.end(); }
}

export const controlDir = () => join(MIGRATIONS_ROOT, 'control');
export const tenantDir = () => join(MIGRATIONS_ROOT, 'tenant');
