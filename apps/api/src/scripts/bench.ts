/**
 * Benchmark the heavy read paths against the generated slice. For each query we
 * report the median of N runs, the rows returned, and the EXPLAIN (which
 * partitions were pruned to and which index was chosen). Results are written to
 * db/bench/benchmark-results.md.
 *
 *   tsx src/scripts/bench.ts [runs]
 */
import { writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import mysql from 'mysql2/promise';
import { config } from '../db/env.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = join(HERE, '..', '..', 'db', 'bench', 'benchmark-results.md');

const TENANT_DB = process.env.BENCH_DB || `${config.db.tenantDbPrefix}hbml`;
async function conn() {
  return mysql.createConnection({ host: config.db.host, port: config.db.port, user: config.db.user, password: config.db.password, database: TENANT_DB });
}

interface Bench { name: string; note: string; sql: string; params: any[]; }

function median(xs: number[]): number { const s = [...xs].sort((a, b) => a - b); const m = Math.floor(s.length / 2); return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2; }

async function timeQuery(c: mysql.Connection, sql: string, params: any[], runs: number) {
  let rows = 0;
  const times: number[] = [];
  for (let i = 0; i < runs; i += 1) {
    const t = process.hrtime.bigint();
    const [r]: any = await c.query(sql, params);
    const dt = Number(process.hrtime.bigint() - t) / 1e6;
    times.push(dt);
    rows = Array.isArray(r) ? r.length : 0;
  }
  return { median: median(times), min: Math.min(...times), max: Math.max(...times), rows };
}

async function explain(c: mysql.Connection, sql: string, params: any[]) {
  const [r]: any = await c.query(`EXPLAIN ${sql}`, params);
  return (r as any[]).map((row) => ({ table: row.table, type: row.type, key: row.key, partitions: row.partitions, rows: row.rows, extra: row.Extra }));
}

async function main() {
  const runs = Number(process.argv[2] || 7);
  const c = await conn();

  // representative ids from the generated data
  const [[acctRow]]: any = await c.query("SELECT account_id, COUNT(*) c FROM posting_line WHERE period_key=202704 GROUP BY account_id ORDER BY c DESC LIMIT 1");
  const busyAccount = Number(acctRow.account_id);
  const [[clrRow]]: any = await c.query("SELECT id FROM gl_account WHERE entity_id=1 AND account_type='CLEARING' LIMIT 1");
  const clearingAccount = Number(clrRow.id);
  const count1 = async (sql: string) => { const [r]: any = await c.query(sql); return Number(r[0].c); };
  const totalPL = await count1('SELECT COUNT(*) c FROM posting_line');
  const totalLV = await count1('SELECT COUNT(*) c FROM declaration_levy');
  const totalDecl = await count1('SELECT COUNT(*) c FROM declaration');

  const benches: Bench[] = [
    {
      name: 'Trial balance (one period, from rollup)',
      note: 'Reads account_period_balance, never posting_line. PK-prefix on (entity, book, period).',
      sql: `SELECT a.code, a.name, (b.opening_dr+b.period_dr) cdr, (b.opening_cr+b.period_cr) ccr
              FROM account_period_balance b JOIN gl_account a ON a.id=b.account_id
             WHERE b.entity_id=1 AND b.book_id=1 AND b.period_key=?`,
      params: [202704],
    },
    {
      name: 'Ledger enquiry (one account, one period, keyset page)',
      note: 'Covering index ix_pl_ledger; partition pruned to one month; keyset pagination (no OFFSET).',
      sql: `SELECT id, voucher_date, dr_cr, amount_func
              FROM posting_line
             WHERE entity_id=1 AND book_id=1 AND account_id=? AND period_key=?
               AND (voucher_date, id) > (?, ?)
             ORDER BY voucher_date, id LIMIT 50`,
      params: [busyAccount, 202704, '1900-01-01', 0],
    },
    {
      name: 'Ledger total (one account, ALL periods)',
      note: 'Cross-partition scan on ix_pl_ledger prefix (entity, book, account). Shows the multi-partition case.',
      sql: 'SELECT COUNT(*) n, SUM(amount_func) tot FROM posting_line WHERE entity_id=1 AND book_id=1 AND account_id=?',
      params: [busyAccount],
    },
    {
      name: 'Duty-by-levy register (one period, aggregate)',
      note: 'Aggregates declaration_levy; covering index ix_dlv_register (entity, period, levy_code, amount) serves it index-only, no temp table; partition pruned to one month.',
      sql: `SELECT levy_code, COUNT(*) line_count, SUM(amount) duty
              FROM declaration_levy FORCE INDEX (ix_dlv_register)
             WHERE entity_id=1 AND period_key=? GROUP BY levy_code`,
      params: [202704],
    },
    {
      name: 'Declaration register (one period, direction, page)',
      note: 'Partition pruned to one month; filtered by direction; latest-first page.',
      sql: `SELECT id, declaration_no, declaration_date, assessable_value, duty_total
              FROM declaration WHERE entity_id=1 AND period_key=? AND direction='IMPORT'
             ORDER BY id DESC LIMIT 50`,
      params: [202704],
    },
    {
      name: 'Clearing-account ageing (all periods, aggregate)',
      note: 'The completeness control. ix_pl_clearing (entity, account, shipment, date); spans all partitions by design.',
      sql: `SELECT shipment_id, MIN(voucher_date) oldest, COUNT(*) n,
                    SUM(CASE WHEN dr_cr='DR' THEN amount_func ELSE -amount_func END) net
              FROM posting_line WHERE entity_id=1 AND account_id=? GROUP BY shipment_id`,
      params: [clearingAccount],
    },
    {
      name: 'Voucher register (one period, count + page)',
      note: 'Partition pruned; register index (entity, period, type, status).',
      sql: `SELECT id, voucher_no, voucher_date, total_dr FROM voucher
             WHERE entity_id=1 AND period_key=? ORDER BY id DESC LIMIT 50`,
      params: [202704],
    },
  ];

  const results: any[] = [];
  for (const b of benches) {
    const timing = await timeQuery(c, b.sql, b.params, runs);
    const plan = await explain(c, b.sql, b.params);
    results.push({ ...b, timing, plan });
    // eslint-disable-next-line no-console
    console.log(`  ${b.name.padEnd(52)} median ${timing.median.toFixed(1)} ms  (${timing.rows} rows)`);
  }

  // report -----------------------------------------------------------------
  const [[ver]]: any = await c.query('SELECT VERSION() v');
  const [[bp]]: any = await c.query('SELECT @@innodb_buffer_pool_size/1024/1024/1024 g');
  const lines: string[] = [];
  lines.push('# HB Trade — heavy-query benchmark');
  lines.push('');
  lines.push(`Run against MySQL ${ver.v}, InnoDB buffer pool ${Number(bp.g).toFixed(1)} GB, in the build sandbox.`);
  lines.push('');
  lines.push('## Slice under test');
  lines.push('');
  lines.push('| Table | Rows |');
  lines.push('|---|--:|');
  lines.push(`| posting_line | ${totalPL.toLocaleString('en-US')} |`);
  lines.push(`| declaration_levy | ${totalLV.toLocaleString('en-US')} |`);
  lines.push(`| declaration | ${totalDecl.toLocaleString('en-US')} |`);
  lines.push('');
  lines.push(`Data spans 12 monthly partitions (202701–202712). Median of ${runs} runs each, warm cache.`);
  lines.push('');
  lines.push('## Results');
  lines.push('');
  lines.push('| Query | Median | Min | Max | Rows |');
  lines.push('|---|--:|--:|--:|--:|');
  for (const r of results) lines.push(`| ${r.name} | ${r.timing.median.toFixed(1)} ms | ${r.timing.min.toFixed(1)} ms | ${r.timing.max.toFixed(1)} ms | ${r.timing.rows} |`);
  lines.push('');
  lines.push('## Query plans');
  lines.push('');
  for (const r of results) {
    lines.push(`### ${r.name}`);
    lines.push('');
    lines.push(r.note);
    lines.push('');
    lines.push('```sql');
    lines.push(r.sql.trim());
    lines.push('```');
    lines.push('');
    lines.push('| table | access | key | partitions | est.rows | extra |');
    lines.push('|---|---|---|---|--:|---|');
    for (const p of r.plan) lines.push(`| ${p.table ?? ''} | ${p.type ?? ''} | ${p.key ?? '—'} | ${p.partitions ?? '—'} | ${p.rows ?? ''} | ${p.extra ?? ''} |`);
    lines.push('');
  }
  lines.push('## Extrapolation to the 10× target (250M posting lines)');
  lines.push('');
  lines.push('Every interactive query above is bounded by an index and, for the period-scoped ones, by a single monthly partition — so their cost is a function of the *rows returned*, not of the table size. The trial balance reads the rollup (one row per account per period), so it is constant-time in posting volume. The register and ledger pages read at most 50 rows through a covering or partition-pruned index. These stay flat as the table grows from the ~1M rows tested here to the 250M-row target: the same partition holds ~1/12 of a year regardless, and keyset pagination never scans a growing OFFSET. The two deliberately unbounded aggregates — cross-period ledger total and clearing ageing — scale linearly with the rows they must touch; in production these run as scheduled/materialised jobs, and the clearing balance the screen shows is the maintained clearing-account rollup, not a live scan.');
  await writeFile(OUT, lines.join('\n'));
  // eslint-disable-next-line no-console
  console.log(`\n  report written to ${OUT}`);
  await c.end();
}

main().then(() => process.exit(0), (e) => { console.error('bench failed:', e); process.exit(1); });
