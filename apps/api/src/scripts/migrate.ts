/**
 * Migration runner for database-per-tenant.
 *
 *   tsx src/scripts/migrate.ts control                 # apply control migrations → hb_control
 *   tsx src/scripts/migrate.ts tenant hb_tenant_hbml   # apply tenant migrations → that database
 *   tsx src/scripts/migrate.ts control --status
 *   tsx src/scripts/migrate.ts control --fresh         # DROP + recreate first
 *
 * Migrations live in db/migrations/control and db/migrations/tenant. Each target
 * database tracks what it has applied in its own schema_migration table. DDL
 * runs as DB_ADMIN_USER; if that user can't connect (managed DB, or a sandbox
 * where the database already exists), it falls back to the app user.
 */
import { readdir, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import mysql from 'mysql2/promise';
import { config } from '../db/env.js';
import { TENANTS } from '../tenants.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const MIGRATIONS_ROOT = join(HERE, '..', '..', 'db', 'migrations');

function splitSql(sql: string): string[] {
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

async function ensureDatabase(dbName: string, fresh: boolean) {
  let admin: mysql.Connection | null = null;
  try { admin = await adminConn(); } catch (e: any) {
    // eslint-disable-next-line no-console
    console.log(`  (admin connect failed: ${e.code || e.message}; assuming ${dbName} exists and is grantable)`);
    return;
  }
  try {
    if (fresh) { await admin.query(`DROP DATABASE IF EXISTS \`${dbName}\``); console.log(`  dropped ${dbName}`); }
    await admin.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`);
    await admin.query(`CREATE USER IF NOT EXISTS '${config.db.user}'@'%' IDENTIFIED BY '${config.db.password}'`);
    await admin.query(`GRANT ALL PRIVILEGES ON \`${dbName}\`.* TO '${config.db.user}'@'%'`);
    await admin.query('FLUSH PRIVILEGES');
  } catch (e: any) {
    // eslint-disable-next-line no-console
    console.log(`  (provisioning partially skipped for ${dbName}: ${e.code || e.message})`);
  } finally { await admin.end(); }
}

async function connFor(dbName: string) {
  try { return await adminConn(dbName); } catch { return appConn(dbName); }
}

async function applyDir(dbName: string, dir: string, opts: { statusOnly: boolean }) {
  const conn = await connFor(dbName);
  try {
    await conn.query(`CREATE TABLE IF NOT EXISTS schema_migration (
      filename VARCHAR(200) NOT NULL, checksum CHAR(64) NOT NULL,
      applied_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), ms INT UNSIGNED NOT NULL DEFAULT 0,
      PRIMARY KEY (filename)) ENGINE=InnoDB`);
    const [appliedRows] = await conn.query('SELECT filename, checksum FROM schema_migration');
    const applied = new Map((appliedRows as any[]).map((r) => [r.filename, r.checksum]));
    const files = (await readdir(dir)).filter((f) => f.endsWith('.sql')).sort();

    if (opts.statusOnly) {
      for (const f of files) {
        const c = createHash('sha256').update(await readFile(join(dir, f))).digest('hex');
        const was = applied.get(f);
        console.log(`  ${(!was ? 'PENDING' : was === c ? 'applied' : 'CHANGED').padEnd(10)} ${dbName}/${f}`);
      }
      return;
    }
    let ran = 0;
    for (const f of files) {
      const sql = await readFile(join(dir, f), 'utf8');
      const checksum = createHash('sha256').update(sql).digest('hex');
      if (applied.get(f) === checksum) continue;
      if (applied.has(f)) throw new Error(`${dbName}/${f} changed after being applied. Add a new migration or use --fresh.`);
      const t0 = Date.now();
      process.stdout.write(`  applying ${dbName}/${f} … `);
      for (const stmt of splitSql(sql)) await conn.query(stmt);
      const ms = Date.now() - t0;
      await conn.query('INSERT INTO schema_migration (filename, checksum, ms) VALUES (?, ?, ?)', [f, checksum, ms]);
      console.log(`ok (${ms} ms)`);
      ran += 1;
    }
    console.log(ran === 0 ? `  ${dbName}: current` : `  ${dbName}: applied ${ran}`);
  } finally { await conn.end(); }
}

async function run() {
  const target = process.argv[2];
  const statusOnly = process.argv.includes('--status');
  const fresh = process.argv.includes('--fresh');

  const doControl = async () => {
    if (!statusOnly) await ensureDatabase(config.db.controlDatabase, fresh);
    await applyDir(config.db.controlDatabase, join(MIGRATIONS_ROOT, 'control'), { statusOnly });
  };
  const doTenant = async (dbName: string) => {
    if (!statusOnly) await ensureDatabase(dbName, fresh);
    await applyDir(dbName, join(MIGRATIONS_ROOT, 'tenant'), { statusOnly });
  };

  if (target === 'control') {
    await doControl();
  } else if (target === 'tenant') {
    const dbName = process.argv[3];
    if (!dbName) throw new Error('usage: migrate tenant <db_name>');
    await doTenant(dbName);
  } else if (target === 'all') {
    // control plane + every tenant's business database
    await doControl();
    for (const t of TENANTS) await doTenant(t.db);
  } else {
    throw new Error('usage: migrate <control|tenant <db>|all> [--status] [--fresh]');
  }
}

run().then(() => process.exit(0), (e) => { console.error('migration failed:', e.message); process.exit(1); });
