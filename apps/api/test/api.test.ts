/**
 * Integration tests for the HB Trade API.
 *
 * These exercise the running stack end-to-end against the seeded control and
 * tenant databases: authentication, database-per-tenant isolation, RBAC and
 * segregation-of-duties enforcement, the generic CRUD lifecycle, the voucher
 * park → post → reverse lifecycle with a balanced trial balance, and
 * server-side pagination + search.
 *
 * The Express app is imported in-process (HB_TEST=1 suppresses its own listen)
 * and bound to an ephemeral port, so the suite is self-contained and does not
 * collide with a dev server on :4000. It does require MySQL to be up and the
 * databases seeded (npm run db:reset).
 */
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import type { AddressInfo } from 'node:net';

// must be set before the app module is evaluated
process.env.HB_TEST = '1';

let server: Server;
let base = '';

before(async () => {
  const { app } = await import('../src/index.js');
  await new Promise<void>((resolve) => {
    server = app.listen(0, () => {
      const { port } = server.address() as AddressInfo;
      base = `http://127.0.0.1:${port}`;
      resolve();
    });
  });
});

after(async () => {
  await new Promise<void>((resolve) => server.close(() => resolve()));
  // release DB pools so the process can exit cleanly
  try { const { closeAllPools } = await import('../src/db/pools.js'); await closeAllPools(); } catch { /* ignore */ }
});

/* --------------------------------------------------------------- helpers -- */
async function api(method: string, path: string, opts: { token?: string; entity?: number; body?: unknown } = {}) {
  const res = await fetch(`${base}${path}`, {
    method,
    headers: {
      Accept: 'application/json',
      ...(opts.body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(opts.token ? { Authorization: `Bearer ${opts.token}` } : {}),
      ...(opts.entity ? { 'X-Entity-Id': String(opts.entity) } : {}),
    },
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });
  let json: any = null;
  try { json = await res.json(); } catch { /* no body */ }
  return { status: res.status, json };
}

async function login(username: string, tenant: string, password = 'hbtrade123') {
  const r = await api('POST', '/api/auth/login', { body: { username, password, tenant } });
  assert.equal(r.status, 200, `login ${username}@${tenant} should succeed`);
  return r.json.data.accessToken as string;
}

const uniq = (p: string) => `${p}${Date.now().toString().slice(-7)}`;

/* ----------------------------------------------------------------- tests -- */

test('health endpoint reports the control database', async () => {
  const r = await api('GET', '/api/health');
  assert.equal(r.status, 200);
  assert.equal(r.json.data.status, 'up');
  assert.equal(r.json.data.model, 'database-per-tenant');
});

test('login succeeds with valid credentials and fails with a bad password', async () => {
  const token = await login('controller', 'HBML');
  assert.ok(token && token.length > 20);

  const bad = await api('POST', '/api/auth/login', { body: { username: 'controller', password: 'wrong', tenant: 'HBML' } });
  assert.equal(bad.status, 401, 'a wrong password must be rejected');
});

test('database-per-tenant isolation: a party created in HBML is invisible to ACME', async () => {
  const hbml = await login('controller', 'HBML');
  const acme = await login('controller', 'ACME');

  const code = uniq('ISO');
  const created = await api('POST', '/api/crud/parties', {
    token: hbml, entity: 1,
    body: { contact_code: code, name: `Isolation Marker ${code}`, legal_name: `Isolation Marker ${code} Pvt Ltd`, country_code: 'IN', currency: 'INR' },
  });
  assert.equal(created.status, 201, 'party create should succeed in HBML');

  // HBML sees it
  const hbmlList = await api('GET', `/api/crud/parties?paged=1&limit=200&offset=0&q=${code}`, { token: hbml, entity: 1 });
  assert.ok(hbmlList.json.data.some((p: any) => p.contact_code === code), 'HBML must see its own party');

  // ACME must NOT see it — different physical database
  const acmeList = await api('GET', `/api/crud/parties?paged=1&limit=200&offset=0&q=${code}`, { token: acme, entity: 1 });
  assert.ok(!acmeList.json.data.some((p: any) => p.contact_code === code), 'ACME must not see a party from HBML');

  // cleanup
  await api('DELETE', `/api/crud/parties/${created.json.data.id}`, { token: hbml, entity: 1 });
});

test('RBAC: a role without voucher:write cannot create a voucher', async () => {
  const auditor = await login('audit', 'HBML'); // internal_auditor: audit:read only
  const r = await api('POST', '/api/vouchers', {
    token: auditor, entity: 1,
    body: { voucherType: 'JVM', date: '2026-07-15', narration: 'should be blocked', currency: 'INR', lines: [] },
  });
  assert.equal(r.status, 403, 'the auditor role must be denied voucher creation');
});

test('generic CRUD lifecycle: create → list → update → get → delete', async () => {
  const token = await login('controller', 'HBML');
  const code = uniq('CRD');

  const created = await api('POST', '/api/crud/parties', {
    token, entity: 1,
    body: { contact_code: code, name: `Crud Co ${code}`, legal_name: `Crud Co ${code} Ltd`, country_code: 'IN', currency: 'INR' },
  });
  assert.equal(created.status, 201);
  const id = created.json.data.id;

  const listed = await api('GET', `/api/crud/parties?paged=1&limit=200&offset=0&q=${code}`, { token, entity: 1 });
  assert.ok(listed.json.data.some((p: any) => p.contact_code === code), 'new party appears in the list');

  const upd = await api('PUT', `/api/crud/parties/${id}`, { token, entity: 1, body: { name: `Crud Co ${code} RENAMED` } });
  assert.equal(upd.status, 200);

  const got = await api('GET', `/api/crud/parties/${id}`, { token, entity: 1 });
  assert.equal(got.status, 200);
  assert.equal(got.json.data.name, `Crud Co ${code} RENAMED`, 'update is persisted');

  const del = await api('DELETE', `/api/crud/parties/${id}`, { token, entity: 1 });
  assert.equal(del.status, 200);

  const gone = await api('GET', `/api/crud/parties/${id}`, { token, entity: 1 });
  assert.equal(gone.status, 404, 'deleted party is no longer retrievable');
});

test('voucher lifecycle: park → post → trial balance balances → reverse', async () => {
  const token = await login('controller', 'HBML');

  // pick two manually-postable, unblocked accounts
  const accts = await api('GET', '/api/crud/accounts?paged=1&limit=500&offset=0', { token, entity: 1 });
  const usable = accts.json.data.filter((a: any) => Number(a.manual_posting_allowed) === 1 && Number(a.is_blocked ?? 0) === 0);
  assert.ok(usable.length >= 2, 'need at least two manually-postable accounts');
  const [dr, cr] = usable;

  const created = await api('POST', '/api/vouchers', {
    token, entity: 1,
    body: {
      voucherType: 'JVM', date: '2026-07-20', currency: 'INR',
      narration: `Test JV ${uniq('JV')}`,
      lines: [
        { accountCode: dr.code, drCr: 'Dr', amount: 5000 },
        { accountCode: cr.code, drCr: 'Cr', amount: 5000 },
      ],
    },
  });
  assert.equal(created.status, 200, 'balanced JV parks successfully');
  assert.equal(created.json.data.status, 'parked');
  const vid = created.json.data.id;

  const posted = await api('POST', `/api/vouchers/${vid}/post`, { token, entity: 1 });
  assert.equal(posted.status, 200, 'controller can post');
  assert.equal(posted.json.data.status, 'posted');
  assert.match(posted.json.data.number, /JVM\//, 'a gapless series number is allocated at posting');

  const tb = await api('GET', '/api/trial-balance', { token, entity: 1 });
  assert.equal(tb.status, 200);
  assert.equal(tb.json.data.balanced, true, 'the trial balance must remain balanced after posting');

  const reversed = await api('POST', `/api/vouchers/${vid}/reverse`, { token, entity: 1 });
  assert.equal(reversed.status, 200, 'a posted voucher can be reversed');

  const after = await api('GET', `/api/vouchers/${vid}`, { token, entity: 1 });
  assert.equal(after.json.data.status, 'reversed', 'the original voucher is marked reversed');

  const tb2 = await api('GET', '/api/trial-balance', { token, entity: 1 });
  assert.equal(tb2.json.data.balanced, true, 'the trial balance stays balanced after reversal');
});

test('unbalanced vouchers are refused', async () => {
  const token = await login('controller', 'HBML');
  const accts = await api('GET', '/api/crud/accounts?paged=1&limit=500&offset=0', { token, entity: 1 });
  const usable = accts.json.data.filter((a: any) => Number(a.manual_posting_allowed) === 1);
  const [dr, cr] = usable;
  const r = await api('POST', '/api/vouchers', {
    token, entity: 1,
    body: { voucherType: 'JVM', date: '2026-07-20', currency: 'INR', narration: 'unbalanced', lines: [
      { accountCode: dr.code, drCr: 'Dr', amount: 5000 },
      { accountCode: cr.code, drCr: 'Cr', amount: 4000 },
    ] },
  });
  assert.equal(r.status, 422, 'an unbalanced voucher never reaches the ledger');
});

test('server-side pagination: page windows differ and totals are reported', async () => {
  const token = await login('controller', 'HBML');

  const p1 = await api('GET', '/api/vouchers?limit=3&offset=0', { token, entity: 1 });
  assert.equal(p1.status, 200);
  assert.ok(p1.json.page && typeof p1.json.page.total === 'number', 'a page envelope with a total is returned');
  assert.ok(p1.json.data.length <= 3, 'the page window is honoured');

  if (p1.json.page.total > 3) {
    const p2 = await api('GET', '/api/vouchers?limit=3&offset=3', { token, entity: 1 });
    const firstPageIds = new Set(p1.json.data.map((v: any) => v.id));
    const overlap = p2.json.data.filter((v: any) => firstPageIds.has(v.id));
    assert.equal(overlap.length, 0, 'the second page does not repeat rows from the first');
  }
});

test('server-side search narrows the result set', async () => {
  const token = await login('controller', 'HBML');
  const all = await api('GET', '/api/vouchers?limit=500&offset=0', { token, entity: 1 });
  const total = all.json.page.total;
  const filtered = await api('GET', '/api/vouchers?limit=500&offset=0&q=PJV', { token, entity: 1 });
  assert.ok(filtered.json.page.total <= total, 'a search never returns more than the unfiltered total');
  assert.ok(filtered.json.data.every((v: any) => `${v.number} ${v.narration} ${v.voucherType}`.includes('PJV')), 'every returned row matches the search term');
});

test('segregation of duties: conflicting role grants are refused', async () => {
  const admin = await login('admin', 'HBML'); // system_admin holds user:admin / role:admin

  // find a fresh user to experiment on, or create one
  const username = uniq('sod');
  const created = await api('POST', '/api/admin/users', {
    token: admin, entity: 1,
    body: { username, fullName: 'SoD Probe', email: `${username}@example.com`, roleCode: 'accounts_executive' },
  });
  assert.equal(created.status, 200, 'admin can create a user with an initial role');
  const userId = created.json.data.id;

  // granting a conflicting role (finance_controller conflicts with accounts_executive, SOD-01) must be refused
  const conflict = await api('POST', `/api/admin/users/${userId}/roles`, {
    token: admin, entity: 1, body: { roleCode: 'finance_controller' },
  });
  assert.equal(conflict.status, 409, 'a grant that breaches segregation of duties is refused');

  // a non-conflicting role is accepted
  const ok = await api('POST', `/api/admin/users/${userId}/roles`, {
    token: admin, entity: 1, body: { roleCode: 'tax_executive' },
  });
  assert.ok(ok.status === 200 || ok.status === 201, 'a non-conflicting role is accepted');

  // cleanup
  await api('PUT', `/api/admin/users/${userId}/active`, { token: admin, entity: 1, body: { active: false } });
});

test('period lock and audit trail: soft-closing a period is recorded', async () => {
  const token = await login('controller', 'HBML');
  const periods = await api('GET', '/api/periods', { token, entity: 1 });
  assert.equal(periods.status, 200);
  assert.ok(Array.isArray(periods.json.data) && periods.json.data.length > 0, 'periods are listed');

  const open = periods.json.data.find((p: any) => p.status === 'OPEN') ?? periods.json.data[0];
  const key = open.periodKey;

  const soft = await api('PUT', `/api/periods/${key}/status`, { token, entity: 1, body: { status: 'SOFT_CLOSED', reason: 'test soft close' } });
  assert.equal(soft.status, 200, 'a period can be soft-closed');

  // restore for idempotency
  await api('PUT', `/api/periods/${key}/status`, { token, entity: 1, body: { status: 'OPEN', reason: 'test reopen' } });

  const audit = await api('GET', '/api/audit?limit=50', { token, entity: 1 });
  assert.equal(audit.status, 200);
  assert.ok(audit.json.data.some((a: any) => String(a.objectType).toLowerCase().includes('period')), 'the period change is journalled to the audit trail');
});
