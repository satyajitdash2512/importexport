/**
 * Role-based access control model — the single source of truth for roles,
 * permissions and segregation-of-duties rules. The seed writes these into
 * role / permission / role_permission / sod_conflict; the API enforces them.
 *
 * A permission code is "resource:action". Endpoints declare the permission
 * they require; the access token carries the union of the caller's permissions
 * so a check is an in-memory set lookup, not a database round-trip.
 *
 * The twelve business roles are those defined in RD section 23 (Security and
 * controls). system_admin is operational, not a business role.
 */

export interface RoleDef {
  code: string;
  name: string;
  description: string;
  perms: string[];
}

// Reusable permission groups ------------------------------------------------
const READ_TRADE = ['order:read', 'shipment:read', 'declaration:read', 'party:read', 'exception:read', 'cockpit:read'];
const READ_FIN = ['voucher:read', 'account:read', 'trialbalance:read', 'costsheet:read', 'reconciliation:read', 'closetask:read'];
const READ_COMPLIANCE = ['licence:read', 'instrument:read', 'entitlement:read', 'screening:read'];
// Every :write permission the generic CRUD layer checks — granted to the
// finance controller so the demo power user can create/edit/delete anywhere.
const WRITE_ALL = [
  'party:write', 'order:write', 'shipment:write', 'declaration:write', 'account:write', 'voucher:write',
  'costsheet:write', 'licence:write', 'instrument:write', 'reconciliation:write', 'cockpit:write', 'exception:write',
  'entitlement:write',
];

export const ROLES: RoleDef[] = [
  {
    code: 'import_executive', name: 'Import executive',
    description: 'Raises and progresses import orders, shipments and declarations.',
    perms: [...READ_TRADE, 'order:create', 'order:update', 'order:write', 'shipment:create', 'shipment:update', 'shipment:write', 'declaration:create', 'declaration:update', 'declaration:write', 'party:write', 'cockpit:write', 'costsheet:read', 'licence:read', 'instrument:read'],
  },
  {
    code: 'export_executive', name: 'Export executive',
    description: 'Raises and progresses export orders, shipments, shipping bills and entitlement claims.',
    perms: [...READ_TRADE, 'order:create', 'order:update', 'order:write', 'shipment:create', 'shipment:update', 'shipment:write', 'declaration:create', 'declaration:update', 'declaration:write', 'party:write', 'cockpit:write', 'entitlement:read', 'entitlement:create', 'entitlement:write', 'licence:read', 'instrument:read'],
  },
  {
    code: 'compliance_officer', name: 'Compliance officer',
    description: 'Owns classification, preference eligibility, screening disposition, licences and the exception queue.',
    perms: [...READ_TRADE, ...READ_COMPLIANCE, 'declaration:update', 'declaration:write', 'declaration:validate', 'licence:create', 'licence:update', 'licence:write', 'party:write', 'screening:disposition', 'exception:resolve', 'exception:write', 'cockpit:write', 'bonded:read'],
  },
  {
    code: 'customs_broker', name: 'Customs broker (external)',
    description: 'External partner: prepares declarations for the entities granted, read-only on finance.',
    perms: ['declaration:read', 'declaration:create', 'declaration:update', 'declaration:write', 'shipment:read', 'party:read'],
  },
  {
    code: 'finance_controller', name: 'Finance controller',
    description: 'Approves vouchers and manual journals, owns the close, may override a period lock with a reason.',
    perms: [...READ_TRADE, ...READ_FIN, ...READ_COMPLIANCE, ...WRITE_ALL, 'voucher:approve', 'voucher:post', 'closetask:update', 'close:override', 'reconciliation:update', 'audit:read'],
  },
  {
    code: 'accounts_executive', name: 'Accounts executive',
    description: 'Captures and parks vouchers, runs subledger and bank reconciliations.',
    perms: [...READ_FIN, 'party:read', 'party:write', 'declaration:read', 'shipment:read', 'voucher:create', 'voucher:update', 'voucher:write', 'reconciliation:update', 'reconciliation:write'],
  },
  {
    code: 'cost_accountant', name: 'Cost accountant',
    description: 'Builds and closes landed-cost sheets, raises landed-cost and goods-receipt vouchers.',
    perms: [...READ_FIN, 'shipment:read', 'declaration:read', 'costsheet:create', 'costsheet:update', 'costsheet:allocate', 'costsheet:close', 'costsheet:write', 'voucher:create', 'voucher:write'],
  },
  {
    code: 'treasury_officer', name: 'Treasury officer',
    description: 'Runs FX revaluation and manages cash and margin positions.',
    perms: [...READ_FIN, 'instrument:read', 'instrument:write', 'voucher:create', 'voucher:write', 'fx:revalue'],
  },
  {
    code: 'trade_finance_officer', name: 'Trade finance officer',
    description: 'Manages letters of credit, guarantees, presentations and export realisation.',
    perms: [...READ_TRADE, 'instrument:read', 'instrument:create', 'instrument:update', 'instrument:write', 'instrument:present', 'reconciliation:read', 'reconciliation:update', 'reconciliation:write', 'entitlement:read'],
  },
  {
    code: 'tax_executive', name: 'Tax executive',
    description: 'Reconciles import tax credit and statutory statements.',
    perms: [...READ_FIN, 'declaration:read', 'reconciliation:update', 'tax:read'],
  },
  {
    code: 'internal_auditor', name: 'Internal auditor',
    description: 'Read-only across the module plus manual-journal and override review.',
    perms: [...READ_TRADE, ...READ_FIN, ...READ_COMPLIANCE, 'audit:read', 'override:review', 'bonded:read'],
  },
  {
    code: 'system_admin', name: 'System administrator',
    description: 'Manages users, roles, entity access and tenants, plus master data.',
    perms: ['user:admin', 'role:admin', 'account:read', 'account:write', 'party:read', 'party:write', 'cockpit:read', 'exception:read', 'audit:read', 'closetask:read', 'trialbalance:read', 'voucher:read', 'declaration:read'],
  },
];

/** Every distinct permission, with resource/action parsed for the permission table. */
export function allPermissions(): { code: string; resource: string; action: string }[] {
  const seen = new Set<string>();
  const out: { code: string; resource: string; action: string }[] = [];
  for (const r of ROLES) {
    for (const p of r.perms) {
      if (seen.has(p)) continue;
      seen.add(p);
      const [resource, action] = p.split(':');
      out.push({ code: p, resource, action });
    }
  }
  return out.sort((a, b) => a.code.localeCompare(b.code));
}

/**
 * Segregation-of-duties: pairs of roles one user may not hold together. The
 * seed writes these; role assignment (POST /admin/users/:id/roles) blocks a
 * grant that would violate one. Example: whoever creates a voucher must not be
 * the one who approves it.
 */
export const SOD: { code: string; a: string; b: string; risk: string }[] = [
  { code: 'SOD-01', a: 'accounts_executive', b: 'finance_controller', risk: 'Voucher preparation and voucher approval by the same person defeats the four-eyes control on postings.' },
  { code: 'SOD-02', a: 'cost_accountant', b: 'finance_controller', risk: 'Preparing and approving landed-cost closures without independent review.' },
  { code: 'SOD-03', a: 'compliance_officer', b: 'customs_broker', risk: 'Internal compliance sign-off and external declaration filing concentrated in one identity.' },
  { code: 'SOD-04', a: 'treasury_officer', b: 'finance_controller', risk: 'Running FX revaluation and approving its posting is a self-review threat.' },
  { code: 'SOD-05', a: 'internal_auditor', b: 'finance_controller', risk: 'The reviewer of manual journals and overrides must not also be their approver.' },
  { code: 'SOD-06', a: 'trade_finance_officer', b: 'accounts_executive', risk: 'Managing instruments and posting the related settlements should be separated.' },
];

/** The demo user set: one representative per business role, plus an admin. */
export interface SeedUser {
  username: string; fullName: string; email: string; role: string; external?: boolean;
}
export const SEED_USERS: SeedUser[] = [
  { username: 'controller', fullName: 'S. Menon', email: 'controller@hostbooks.example', role: 'finance_controller' },
  { username: 'imports', fullName: 'A. Kulkarni', email: 'imports@hostbooks.example', role: 'import_executive' },
  { username: 'exports', fullName: 'R. Iyer', email: 'exports@hostbooks.example', role: 'export_executive' },
  { username: 'compliance', fullName: 'D. Rao', email: 'compliance@hostbooks.example', role: 'compliance_officer' },
  { username: 'costing', fullName: 'M. Shah', email: 'costing@hostbooks.example', role: 'cost_accountant' },
  { username: 'accounts', fullName: 'P. Nair', email: 'accounts@hostbooks.example', role: 'accounts_executive' },
  { username: 'treasury', fullName: 'K. Bose', email: 'treasury@hostbooks.example', role: 'treasury_officer' },
  { username: 'tradefinance', fullName: 'V. Menon', email: 'tradefinance@hostbooks.example', role: 'trade_finance_officer' },
  { username: 'tax', fullName: 'G. Pillai', email: 'tax@hostbooks.example', role: 'tax_executive' },
  { username: 'audit', fullName: 'N. Fernandes', email: 'audit@hostbooks.example', role: 'internal_auditor' },
  { username: 'broker', fullName: 'Bluewave Clearing', email: 'broker@bluewave.example', role: 'customs_broker', external: true },
  { username: 'admin', fullName: 'System Administrator', email: 'admin@hostbooks.example', role: 'system_admin' },
];

/** All demo users share this password (documented in the README). */
export const DEMO_PASSWORD = 'hbtrade123';
