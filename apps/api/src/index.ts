import express, { type Response, type NextFunction } from 'express';
import cors from 'cors';
import { config } from './db/env.js';
import { controlPool } from './db/pools.js';
import { cq } from './db/pool.js';
import { computeDuty, previewPosting } from './engines.js';
import { HttpError, requireAuth, requirePermission, h, pageParams, type AuthedRequest } from './http/context.js';
import * as auth from './repos/auth.js';
import * as read from './repos/read.js';
import * as acct from './repos/accounting.js';
import { postVoucher, reverseVoucher } from './repos/posting.js';
import * as admin from './repos/admin.js';
import { crudRouter } from './http/crud.js';
import * as docs from './repos/docwrite.js';
import * as audit from './repos/audit.js';
import * as period from './repos/period.js';
import * as integ from './repos/integrations.js';
import * as tenants from './repos/tenantAdmin.js';
import * as reports from './repos/reports.js';

export const app = express();
app.use(cors({ exposedHeaders: ['X-Total-Count'] }));
app.use(express.json({ limit: '2mb' }));

// envelope helpers
const ok = (res: Response, data: unknown, page?: unknown) => res.json({ data, ...(page ? { page } : {}), asOf: new Date().toISOString() });
const notFound = (res: Response, what: string) => res.status(404).json({ error: `${what} not found` });

// ---- public --------------------------------------------------------------
app.get('/api/health', (_req, res) => ok(res, { status: 'up', service: 'hb-trade-api', version: '2.0.0', control: config.db.controlDatabase, model: 'database-per-tenant' }));

// public: the list of tenants, so the login screen can offer a business picker
app.get('/api/tenants', h(async (_req, res) => {
  const rows = await cq<any>("SELECT code, name FROM tenant WHERE status = 'ACTIVE' ORDER BY name");
  ok(res, rows.map((r) => ({ code: r.code, name: r.name })));
}));

app.post('/api/auth/login', h(async (req, res) => {
  const { username, password, tenant } = req.body ?? {};
  if (!username || !password) throw new HttpError(400, 'username and password are required');
  ok(res, await auth.login(String(username), String(password), tenant ? String(tenant) : undefined));
}));
app.post('/api/auth/refresh', h(async (req, res) => {
  const { refreshToken } = req.body ?? {};
  if (!refreshToken) throw new HttpError(400, 'refreshToken is required');
  ok(res, await auth.refresh(String(refreshToken)));
}));
app.post('/api/auth/logout', h(async (req, res) => {
  const { refreshToken } = req.body ?? {};
  if (refreshToken) await auth.logout(String(refreshToken));
  ok(res, { ok: true });
}));

// everything below requires a valid token + an authorised entity
app.use('/api', requireAuth as any);

app.get('/api/auth/me', h(async (req: AuthedRequest, res) => {
  ok(res, { ...req.auth, entityId: req.entityId });
}));

// ---- masters -------------------------------------------------------------
app.get('/api/parties', requirePermission('party:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listParties(req.entityId!))));
app.get('/api/parties/:id', requirePermission('party:read'), h(async (req: AuthedRequest, res) => {
  const p = await read.getParty(req.entityId!, req.params.id); return p ? ok(res, p) : notFound(res, 'Party');
}));
app.get('/api/accounts', requirePermission('account:read'), h(async (req: AuthedRequest, res) => ok(res, await acct.listAccounts(req.entityId!))));
app.get('/api/voucher-types', requirePermission('voucher:read'), h(async (req: AuthedRequest, res) => ok(res, await acct.listVoucherTypes(req.entityId!))));
app.get('/api/posting-rules', requirePermission('voucher:read'), h(async (_req, res) => ok(res, acct.postingRules())));
app.get('/api/levy-cascade', requirePermission('declaration:read'), h(async (_req, res) => ok(res, acct.levyCascade())));
app.get('/api/account-determination', requirePermission('account:read'), h(async (_req, res) => ok(res, acct.accountDetermination())));

// ---- orders --------------------------------------------------------------
app.get('/api/orders', requirePermission('order:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listOrders(req.entityId!, req.query.type ? String(req.query.type) : undefined))));
app.get('/api/orders/:id', requirePermission('order:read'), h(async (req: AuthedRequest, res) => {
  const o = await read.getOrder(req.entityId!, req.params.id); return o ? ok(res, o) : notFound(res, 'Order');
}));

// ---- shipments -----------------------------------------------------------
app.get('/api/shipments', requirePermission('shipment:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listShipments(req.entityId!, req.query.direction ? String(req.query.direction) : undefined))));
app.get('/api/shipments/:id', requirePermission('shipment:read'), h(async (req: AuthedRequest, res) => {
  const s = await read.getShipment(req.entityId!, req.params.id); return s ? ok(res, s) : notFound(res, 'Shipment');
}));

// ---- declarations --------------------------------------------------------
app.get('/api/declarations', requirePermission('declaration:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listDeclarations(req.entityId!, req.query.direction ? String(req.query.direction) : undefined))));
app.get('/api/declarations/:id', requirePermission('declaration:read'), h(async (req: AuthedRequest, res) => {
  const d = await read.getDeclaration(req.entityId!, req.params.id); return d ? ok(res, d.detail) : notFound(res, 'Declaration');
}));
app.post('/api/declarations/:id/compute', requirePermission('declaration:read'), h(async (req: AuthedRequest, res) => {
  const d = await read.getDeclaration(req.entityId!, req.params.id);
  if (!d) return notFound(res, 'Declaration');
  const { lineId, hasPreferenceProof } = req.body ?? {};
  const line = d.declaration.lines.find((l) => l.id === lineId);
  if (!line) return notFound(res, 'Declaration line');
  ok(res, computeDuty({ assessableValue: line.assessableValue, qty: line.qty, hsCode: line.hsCode, preferenceAgreement: line.preferenceAgreement, hasPreferenceProof: hasPreferenceProof ?? Boolean(line.preferenceProofRef) }));
}));
app.post('/api/duty/compute', requirePermission('declaration:read'), h(async (req, res) => ok(res, computeDuty(req.body))));

// ---- cost sheets ---------------------------------------------------------
app.get('/api/cost-sheets', requirePermission('costsheet:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listCostSheets(req.entityId!))));
app.get('/api/cost-sheets/:id', requirePermission('costsheet:read'), h(async (req: AuthedRequest, res) => {
  const c = await read.getCostSheet(req.entityId!, req.params.id); return c ? ok(res, c) : notFound(res, 'Cost sheet');
}));
app.post('/api/cost-sheets/:id/allocate', requirePermission('costsheet:read'), h(async (req: AuthedRequest, res) => {
  const r = await read.allocateCostLine(req.entityId!, req.params.id, req.body?.chargeLineId, req.body?.basis);
  if (!r) return notFound(res, 'Cost sheet');
  if ((r as any).notFound) return notFound(res, 'Charge line');
  ok(res, r);
}));

// ---- licences ------------------------------------------------------------
app.get('/api/licences', requirePermission('licence:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listLicences(req.entityId!))));
app.get('/api/licences/:id', requirePermission('licence:read'), h(async (req: AuthedRequest, res) => {
  const l = await read.getLicence(req.entityId!, req.params.id); return l ? ok(res, l) : notFound(res, 'Licence');
}));

// ---- instruments ---------------------------------------------------------
app.get('/api/instruments', requirePermission('instrument:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listInstruments(req.entityId!))));
app.get('/api/instruments/:id', requirePermission('instrument:read'), h(async (req: AuthedRequest, res) => {
  const i = await read.getInstrument(req.entityId!, req.params.id); return i ? ok(res, i) : notFound(res, 'Instrument');
}));

// ---- accounting ----------------------------------------------------------
app.get('/api/vouchers', requirePermission('voucher:read'), h(async (req: AuthedRequest, res) => {
  const pg = pageParams(req);
  const { list, total, limit, offset } = await acct.listVouchers(req.entityId!, {
    status: req.query.status ? String(req.query.status) : undefined,
    voucherType: req.query.voucherType ? String(req.query.voucherType) : undefined,
    q: req.query.q ? String(req.query.q) : undefined,
    limit: req.query.limit ? pg.limit : undefined, offset: pg.offset,
  });
  res.setHeader('X-Total-Count', String(total));
  ok(res, list, { total, limit, offset });
}));
app.get('/api/vouchers/:id', requirePermission('voucher:read'), h(async (req: AuthedRequest, res) => {
  const v = await acct.getVoucher(req.entityId!, req.params.id); return v ? ok(res, v) : notFound(res, 'Voucher');
}));
app.post('/api/postings/preview', requirePermission('voucher:read'), h(async (req, res) => ok(res, previewPosting(req.body))));
/** The real write path: post a parked/pending voucher in one transaction. */
app.post('/api/vouchers/:id/post', requirePermission('voucher:post'), h(async (req: AuthedRequest, res) => {
  ok(res, await postVoucher(req.entityId!, req.params.id, req.auth!.sub, req.auth!.fullName));
}));
app.post('/api/vouchers/:id/reverse', requirePermission('voucher:post'), h(async (req: AuthedRequest, res) => {
  ok(res, await reverseVoucher(req.entityId!, req.params.id, req.auth!.sub, req.auth!.fullName));
}));

app.get('/api/trial-balance', requirePermission('trialbalance:read'), h(async (req: AuthedRequest, res) => ok(res, await acct.trialBalance(req.entityId!, req.query.group ? String(req.query.group) : undefined))));
app.get('/api/close-tasks', requirePermission('closetask:read'), h(async (req: AuthedRequest, res) => ok(res, await acct.closeTasks(req.entityId!))));
app.get('/api/reconciliations', requirePermission('reconciliation:read'), h(async (req: AuthedRequest, res) => ok(res, await acct.listReconciliations(req.entityId!))));
app.get('/api/reconciliations/:id', requirePermission('reconciliation:read'), h(async (req: AuthedRequest, res) => {
  const r = await acct.getReconciliation(req.entityId!, req.params.id); return r ? ok(res, r) : notFound(res, 'Reconciliation');
}));
app.get('/api/entitlements', requirePermission('entitlement:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listEntitlements(req.entityId!))));

// ---- workflow / dashboard ------------------------------------------------
app.get('/api/tasks', requirePermission('cockpit:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listTasks(req.entityId!))));
app.get('/api/exceptions', requirePermission('exception:read'), h(async (req: AuthedRequest, res) => ok(res, await read.listExceptions(req.entityId!, req.query.severity ? String(req.query.severity) : undefined))));
app.get('/api/cockpit', requirePermission('cockpit:read'), h(async (req: AuthedRequest, res) => ok(res, await acct.cockpit(req.entityId!))));

// ---- generic CRUD (create/read/update/delete on every resource) ----------
app.use('/api/crud', crudRouter);

// ---- document writes with children (voucher/order lines) -----------------
app.post('/api/vouchers', requirePermission('voucher:write'), h(async (req: AuthedRequest, res) => {
  ok(res, await docs.createVoucher(req.entityId!, req.body, req.auth!.sub, req.auth!.fullName));
}));
app.put('/api/vouchers/:id', requirePermission('voucher:write'), h(async (req: AuthedRequest, res) => {
  ok(res, await docs.updateVoucher(req.entityId!, req.params.id, req.body));
}));
app.delete('/api/vouchers/:id', requirePermission('voucher:write'), h(async (req: AuthedRequest, res) => {
  ok(res, await docs.deleteVoucher(req.entityId!, req.params.id));
}));
app.put('/api/orders/:id/lines', requirePermission('order:write'), h(async (req: AuthedRequest, res) => {
  ok(res, await docs.replaceOrderLines(req.entityId!, req.params.id, req.body?.lines ?? []));
}));

// ---- admin (user / role / entity access) ---------------------------------
app.get('/api/admin/users', requirePermission('user:admin'), h(async (req: AuthedRequest, res) => ok(res, await admin.listUsers(req.auth!.tenantId))));
app.get('/api/admin/roles', requirePermission('user:admin'), h(async (_req, res) => ok(res, await admin.listRoles())));
app.get('/api/admin/sod', requirePermission('user:admin'), h(async (_req, res) => ok(res, await admin.listSod())));
app.get('/api/admin/entities', requirePermission('user:admin'), h(async (_req, res) => ok(res, await admin.listEntities())));
app.post('/api/admin/users', requirePermission('user:admin'), h(async (req: AuthedRequest, res) => ok(res, await admin.createUser(req.auth!.tenantId, req.body))));
app.post('/api/admin/users/:id/roles', requirePermission('user:admin'), h(async (req: AuthedRequest, res) => ok(res, await admin.assignRole(req.auth!.tenantId, Number(req.params.id), String(req.body?.roleCode)))));
app.delete('/api/admin/users/:id/roles/:role', requirePermission('user:admin'), h(async (req: AuthedRequest, res) => ok(res, await admin.revokeRole(req.auth!.tenantId, Number(req.params.id), String(req.params.role)))));
app.put('/api/admin/users/:id/active', requirePermission('user:admin'), h(async (req: AuthedRequest, res) => ok(res, await admin.setUserActive(req.auth!.tenantId, Number(req.params.id), !!req.body?.active))));
app.put('/api/admin/users/:id/password', requirePermission('user:admin'), h(async (req: AuthedRequest, res) => ok(res, await admin.resetPassword(req.auth!.tenantId, Number(req.params.id), String(req.body?.password ?? '')))));
app.post('/api/admin/users/:id/entities', requirePermission('user:admin'), h(async (req: AuthedRequest, res) => ok(res, await admin.grantEntity(req.auth!.tenantId, Number(req.params.id), Number(req.body?.entityId)))));
app.delete('/api/admin/users/:id/entities/:eid', requirePermission('user:admin'), h(async (req: AuthedRequest, res) => ok(res, await admin.revokeEntity(req.auth!.tenantId, Number(req.params.id), Number(req.params.eid)))));

// ---- tenant provisioning --------------------------------------------------
app.get('/api/admin/tenants', requirePermission('user:admin'), h(async (_req, res) => ok(res, await tenants.listTenants())));
app.post('/api/admin/tenants', requirePermission('role:admin'), h(async (req, res) => ok(res, await tenants.provisionTenant(req.body))));

// ---- periods (lock / unlock) ---------------------------------------------
app.get('/api/periods', requirePermission('closetask:read'), h(async (req: AuthedRequest, res) => ok(res, await period.listPeriods(req.entityId!))));
app.put('/api/periods/:key/status', requirePermission('close:override'), h(async (req: AuthedRequest, res) => {
  ok(res, await period.setPeriodStatus(req.entityId!, Number(req.params.key), String(req.body?.status) as any, { userId: req.auth!.sub, username: req.auth!.username }, req.body?.reason));
}));

// ---- integrations (simulated connectors) ---------------------------------
app.get('/api/integrations/log', requirePermission('declaration:read'), h(async (req: AuthedRequest, res) => ok(res, await integ.listIntegrationLog(req.entityId!, req.query.channel ? String(req.query.channel) : undefined))));
app.post('/api/integrations/icegate/transmit/:decl', requirePermission('declaration:write'), h(async (req: AuthedRequest, res) => ok(res, await integ.transmitDeclaration(req.entityId!, req.params.decl, { userId: req.auth!.sub, username: req.auth!.username }))));
app.post('/api/integrations/icegate/poll/:decl', requirePermission('declaration:read'), h(async (req: AuthedRequest, res) => ok(res, await integ.pollDeclarationStatus(req.entityId!, req.params.decl))));
app.post('/api/integrations/edpms/:decl', requirePermission('declaration:read'), h(async (req: AuthedRequest, res) => ok(res, await integ.edpmsStatus(req.entityId!, req.params.decl, { userId: req.auth!.sub }))));
app.post('/api/integrations/bank/:instr', requirePermission('instrument:write'), h(async (req: AuthedRequest, res) => ok(res, await integ.bankSend(req.entityId!, req.params.instr, { userId: req.auth!.sub, username: req.auth!.username }))));

// ---- audit log ------------------------------------------------------------
app.get('/api/audit', requirePermission('audit:read'), h(async (req: AuthedRequest, res) => {
  const { list, total } = await audit.listAudit(req.entityId!, { objectType: req.query.objectType ? String(req.query.objectType) : undefined, limit: Number(req.query.limit) || 200 });
  res.setHeader('X-Total-Count', String(total));
  ok(res, list, { total });
}));

// ---- print & report exports ----------------------------------------------
app.get('/api/print/voucher/:id', requirePermission('voucher:read'), h(async (req: AuthedRequest, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(await reports.printVoucher(req.entityId!, req.params.id));
}));
app.get('/api/print/trial-balance', requirePermission('trialbalance:read'), h(async (req: AuthedRequest, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(await reports.printTrialBalance(req.entityId!));
}));
app.get('/api/export/trial-balance.xlsx', requirePermission('trialbalance:read'), h(async (req: AuthedRequest, res) => {
  const buf = await reports.trialBalanceXlsx(req.entityId!);
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', 'attachment; filename="trial-balance.xlsx"');
  res.send(buf);
}));

// ---- fallback + error handler --------------------------------------------
app.use('/api', (_req, res) => res.status(404).json({ error: 'Unknown endpoint' }));
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: any, _req: AuthedRequest, res: Response, _next: NextFunction) => {
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message, code: err.code });
  // eslint-disable-next-line no-console
  console.error('[hb-trade-api] error:', err);
  return res.status(500).json({ error: 'Internal server error' });
});

async function start() {
  // fail fast if the control database is unreachable
  try {
    const conn = await controlPool.getConnection();
    await conn.ping();
    conn.release();
  } catch (e: any) {
    // eslint-disable-next-line no-console
    console.error(`[hb-trade-api] cannot reach control DB ${config.db.controlDatabase} at ${config.db.host}:${config.db.port} — ${e.code || e.message}`);
    process.exit(1);
  }
  app.listen(config.server.port, () => {
    // eslint-disable-next-line no-console
    console.log(`[hb-trade-api] listening on http://localhost:${config.server.port}  (control ${config.db.controlDatabase}, tenant DBs per business)`);
  });
}
// Auto-start only when run as the entry point. Tests import `app` with
// HB_TEST=1 set and listen on an ephemeral port themselves.
if (!process.env.HB_TEST) start();
