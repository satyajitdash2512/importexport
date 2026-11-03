# HostBooks · Import & Export

An accounting-anchored Import & Export module for HB ERP: a **React + TypeScript
+ MUI** front end over a **Node/Express + MySQL 8** API, implementing the
module specified in **HBERP-RD-TRADE-001 v2.0**.

The product is engineered to run on real data at scale — raw SQL over a
`mysql2` pool, range-partitioned fact tables, maintained rollups, keyset
pagination — and it is secured end to end with **JWT auth, role-based access
control, and database-per-tenant isolation**: each business has its **own
physical database**, and every request is routed to that database, so one
business's data cannot even be *addressed* from another's session.

---

## What's here

```
apps/
  web/    React 18 + TypeScript + MUI + TanStack Query + Recharts   (Vite)
  api/    Express + TypeScript + mysql2 (raw SQL)                   (tsx)
    db/migrations/control/   the control database (tenants, users, RBAC)
    db/migrations/tenant/    the per-business schema (85 tables, views, procs)
    src/db/pools.ts          control pool + per-tenant pool routing (AsyncLocalStorage)
    src/repos/               thin repositories + the transactional posting path
    src/auth/                JWT, RBAC model, password hashing
    src/scripts/             migrate · seed · generate · bench
deploy/   hb-tuning.cnf (the MySQL config used to build & benchmark)
docker-compose.yml
```

### Databases

- **`hb_control`** — the directory + auth plane: the `tenant` registry, all
  users (each belongs to one tenant), roles, permissions, SoD rules, refresh
  tokens. No business data.
- **`hb_tenant_<code>`** — one per business, each holding the full trade +
  accounting schema. The demo provisions two: `hb_tenant_hbml` and
  `hb_tenant_acme`.

A login resolves the user's tenant; the issued token carries that tenant's
database name, and the API routes every business query there (request-scoped
`AsyncLocalStorage`). A user has no way to name another tenant's database, so
isolation is enforced by the database boundary, not a `WHERE` clause.

---

## Run it

### Local (MySQL already installed)

```bash
npm install                         # repo root (npm workspaces)

cd apps/api
cp .env.example .env                # adjust if your MySQL differs
npm run db:reset                    # provision hb_control + hb_tenant_hbml + hb_tenant_acme,
                                    #   apply migrations, and seed all of them
npm run dev:api                     # API on :4000

cd ../web
npm run dev                         # web on :5173  (proxies /api → :4000)
```

Open **http://localhost:5173** and sign in (see **Demo logins** below).

**Prefer a ready-made database?** Instead of `npm run db:reset`, you can load a
complete pre-seeded snapshot of all three databases from **`db-dump/`**
(`./db-dump/load.sh`) — see `db-dump/README.md`. Either path gives you the same
balanced demo data.

### Docker

```bash
docker compose up --build
docker compose run --rm api npm run db:reset
# open http://localhost:5173
```

### Load a large slice and benchmark (optional)

```bash
cd apps/api
npm run generate 250000 120000      # ~3.2M rows into FY2027 partitions
npm run bench                       # writes db/bench/benchmark-results.md
```

Requirements: Node 20+, MySQL 8.

---

## Security & multitenancy

**Database-per-tenant.** Each business is a tenant with its **own database**.
Login resolves the tenant, the access token carries the tenant's database name,
and the API routes every business query to that database. A session for one
business physically cannot reach another's data — there is no request parameter
that names another tenant's database. Proven both directions in the demo: a user
in `hb_tenant_hbml` never sees a row from `hb_tenant_acme`, and vice-versa; each
business runs its own trial balance, number series, and close.

**Authentication** is JWT (short-lived access token + rotating refresh token,
stored only as a SHA-256 hash). Passwords are bcrypt-hashed. **Authorisation** is
a permission model — every endpoint declares the `resource:action` it requires,
and the caller's permissions travel in the token so a check is a set lookup.

**Within a tenant**, a user is further scoped to the legal entities they're
granted (a business can have several legal entities), and **segregation of
duties** refuses a role grant that would let one person hold a conflicting pair
(e.g. *prepare* vs *approve* vouchers), citing the risk.

The twelve business roles from RD §23 are seeded for **each** tenant, so both
businesses have their own `controller`, `admin`, etc. (username is unique per
tenant). All demo users share the password **`hbtrade123`**.

### Demo logins

Pick a **business** on the sign-in screen (HB Manufacturing Ltd or Acme Trading
Ltd), then a user:

| Username | Person / role | Can do |
|---|---|---|
| `controller` | S. Menon — Finance controller | approve & **post** vouchers, override lock |
| `imports` | A. Kulkarni — Import executive | orders, shipments, declarations |
| `compliance` | D. Rao — Compliance officer | classification, screening, licences |
| `costing` | M. Shah — Cost accountant | landed-cost sheets, GRN/LCV vouchers |
| `accounts` | P. Nair — Accounts executive | park vouchers, reconciliations |
| `tradefinance` | V. Menon — Trade finance officer | LCs, guarantees, presentations |
| `audit` | N. Fernandes — Internal auditor | **read-only** across the module |
| `admin` | System administrator | manage this tenant's users and roles |

Sign in as `controller` and post a parked voucher to see the transactional write
path; sign in as `audit` and the post button is disabled — the API refuses it too.
Sign in to each business and note the data, trial balance, and admin user list
are entirely separate.

---

## The API

Express + TypeScript, backed by MySQL. Envelope: `{ data, page?, asOf }`.
Auth: `Authorization: Bearer <token>` and `X-Entity-Id: <id>` on every call
below `/api` except the auth and health routes.

```
POST /api/auth/login            {username,password} → {accessToken, refreshToken, user}
POST /api/auth/refresh          {refreshToken}      → new token pair (old one revoked)
POST /api/auth/logout           {refreshToken}
GET  /api/auth/me
GET  /api/health

# permission required in (parens)
GET  /api/cockpit                         (cockpit:read)   live counts + curated panels
GET  /api/parties          /:id           (party:read)
GET  /api/orders           /:id           (order:read)
GET  /api/shipments        /:id           (shipment:read)
GET  /api/declarations     /:id           (declaration:read)
POST /api/declarations/:id/compute        (declaration:read)   recompute a line via the duty engine
POST /api/duty/compute                    (declaration:read)
GET  /api/cost-sheets      /:id           (costsheet:read)
POST /api/cost-sheets/:id/allocate        (costsheet:read)     allocation on a chosen basis
GET  /api/licences         /:id           (licence:read)       with obligation projection
GET  /api/instruments      /:id           (instrument:read)    with presentation deadline
GET  /api/entitlements                    (entitlement:read)
GET  /api/vouchers?status=&voucherType=&q=&limit=&offset=  (voucher:read)  server-paged + search ({page:{total,limit,offset}})
GET  /api/vouchers/:id                    (voucher:read)
POST /api/postings/preview                (voucher:read)       posting-rule engine
POST /api/vouchers/:id/post               (voucher:post)       TRANSACTIONAL posting
POST /api/vouchers/:id/reverse            (voucher:post)       mirror-image reversal
GET  /api/trial-balance?group=            (trialbalance:read)  reads the rollup
GET  /api/voucher-types  /posting-rules  /levy-cascade  /account-determination
GET  /api/close-tasks                     (closetask:read)
GET  /api/reconciliations  /:id           (reconciliation:read)
GET  /api/tasks   /exceptions?severity=   (cockpit/exception:read)

# generic CRUD (every editable resource) — server-side paging + search
GET  /api/crud/:resource?paged=1&limit=&offset=&q=   ({perm}:read)   windowed list + COUNT + LIKE search
GET/POST/PUT/DELETE /api/crud/:resource[/:id]        ({perm}:read|write)
GET/PUT /api/crud/:resource/:id/:child               nested line editing

# administration
GET  /api/admin/users  /roles  /sod       (user:admin)
POST /api/admin/users                     (user:admin)         create user
POST /api/admin/users/:id/roles           (user:admin)         SoD-enforced role grant
DELETE /api/admin/users/:id/roles/:role   (user:admin)
PUT  /api/admin/users/:id/active          (user:admin)         activate/deactivate
PUT  /api/admin/users/:id/password        (user:admin)         reset (revokes sessions)
POST /api/admin/users/:id/entities        (user:admin)         grant/revoke entity access
GET  /api/admin/tenants                   (user:admin)
POST /api/admin/tenants                   (role:admin)         RUNTIME provision: create DB, migrate, seed, admin
GET  /api/periods                         (closetask:read)
PUT  /api/periods/:key/status             (close:override)     open / soft-close / hard-close (audited)
GET  /api/integrations/log                (voucher:read)
POST /api/integrations/icegate/transmit/:id  /poll/:id         customs (ICEGATE) — simulated
POST /api/integrations/edpms/:id  /bank/:id                    realisation / bank host — simulated
GET  /api/audit?objectType=&limit=        (audit:read)         append-only audit trail
GET  /api/print/voucher/:id  /print/trial-balance   (…:read)   print-ready HTML
GET  /api/export/trial-balance.xlsx       (trialbalance:read)  Excel export (exceljs)
```

### Transactional posting

`POST /api/vouchers/:id/post` is the one write path that must be airtight, so it
is a single transaction (`src/repos/posting.ts`): re-read the voucher
`FOR UPDATE`; validate double entry (debits == credits, no blocked account);
validate mandatory evidence; allocate the **gapless** statutory number under
`SELECT … FOR UPDATE` on `number_series`; update `account_period_balance` for
every line; flip the voucher to POSTED. Any failure rolls the whole thing back —
no partial post, no gap in the series, no rollup drift.

---

## Handling large data

The schema is built for the RD's 10× non-functional target — **1,000,000
declarations a year, 250,000,000 posting lines** — not merely for the demo.

- **Range partitioning** on `period_key` (`YYYYMM`) for every fact table, so a
  period-scoped query prunes to one monthly partition.
- **Maintained rollups** (`account_period_balance`, `stock_balance`): the trial
  balance and stock valuation read one row per account/item per period and never
  aggregate the fact table.
- **Covering indexes** for the ledger enquiry, registers, and clearing ageing.
- **Keyset pagination** on the hot lists (no growing `OFFSET`).
- **Bulk generator** (`npm run generate`) and a **benchmark harness**
  (`npm run bench`) that captures timings and `EXPLAIN` plans.

### Measured (build sandbox, MySQL 8.0.46, 3 GB buffer pool)

Against a slice of **~1.0M `posting_line`, ~1.44M `declaration_levy`, ~116k
`declaration`** rows across 12 monthly partitions (median of 9 runs):

| Query | Median | Plan |
|---|--:|---|
| Trial balance (one period) | ~1.5 ms | reads the rollup |
| Ledger enquiry (account, month, keyset page) | ~1.9 ms | 1 partition, covering index |
| Declaration register (month, page) | ~1.2 ms | 1 partition |
| Voucher register (month, page) | ~0.7 ms | 1 partition |
| Duty-by-levy register (month, aggregate) | ~74 ms | 1 partition, index-only |
| Clearing-account ageing (all periods) | ~82 ms | completeness control, spans partitions |
| Ledger total (account, all periods) | ~71 ms | multi-partition, indexed |

Full plans in `apps/api/db/bench/benchmark-results.md`.

**Why this holds at 250M rows.** The interactive queries are bounded by an index
and by a single monthly partition, so their cost tracks *rows returned*, not
table size — a month holds ~1/12 of a year whether the table has 1M or 250M rows,
and keyset paging never scans a growing offset. The trial balance is
constant-time in posting volume because it reads the rollup. The two deliberately
unbounded aggregates scale linearly with the rows they touch; in production those
run as scheduled jobs and the screen reads the maintained clearing rollup.

---

## The front end

The visual language is derived from the supplied HostBooks product screenshot,
and **`apps/web/src/context/tokens.ts` is the single file to edit to re-brand** —
no component carries a literal hex value. 64 routes; a dozen flagship screens
taken to full interactive depth, the rest generated from a declarative registry.
The front end runs entirely against the MySQL-backed API, behind login, with
automatic token refresh and permission-gated actions.

### UI Folder and File Structure

Following enterprise React architectural patterns, the frontend codebase in `apps/web/src` is structured to group code by domain features, shared layouts, configurations, and core context providers:

- **`assets/`**
  Stores global static assets such as logos, product images, font files, and SVG icon sets.
- **`components/`**
  Contains generic, reusable atomic UI primitives that form the building blocks of the application layout.
  - `primitives.tsx`: Contains chips (status, severity, deadline), loading animations, error screens, KPI tiles, and basic layout container bands.
  - `DataTable.tsx`: Standard client-side searchable and paginated grid component.
  - `ServerDataTable.tsx`: Server-side paginated and searchable grid component designed for loading high-volume datasets (vouchers, audit logs).
- **`config/`**
  Stores application configurations, static mapping values, and registries.
  - `navigation.ts`: Defines the main sidebar links, icons, routes, and role-based permissions mapping.
  - `crudRegistry.ts`: Maps DB tables to their write whitelists, field layouts, and validation rules.
  - `screenRegistry.ts`: Declarative metadata definitions for all standard screens (KPI tiles, columns, search fields).
- **`context/`**
  Hosts true global context providers and layout constraints.
  - `AuthContext.tsx`: Wraps the application session and authorization helper utilities (`can` check).
  - `hostbooksTheme.ts`: Core Material-UI (MUI) theme configuration (styles, overrides, typography).
  - `tokens.ts`: Style parameters (palette colors, font specs, elevations) imported into the MUI theme.
- **`features/`**
  The domain-driven core of the application. Code is divided into feature modules:
  - `auth/`: Authentication credentials input screens and local session storage handlers.
  - `cockpit/`: Dashboard layout rendering KPI summaries, pending actions, and progress charts.
  - `trade/`: Screens for tracking shipments, ICEGATE declarations, and statutory compliance obligations.
  - `accounting/`: Specialized ledger pages (trial balance, periods close, reconciliation, landed-cost allocation, and voucher entry lines editor).
  - `admin/`: Controls for managing users, SoD role enforcement, audit log inspection, and runtime tenant creation.
  - `generic/`: Generic registry-driven page renderer that dynamically compiles any simple list/edit view.
- **`layouts/`**
  Hosts global structural page shells.
  - `AppShell.tsx`: The main navigation shell wrapper displaying the sidebar, top header, search box, profile menu, and wrapping children inside security boundaries.
- **`lib/`**
  Third-party client integrations and API fetch wrappers.
  - `api.ts`: Central Axios-like fetch client implementing automatic base URLs, request envelopes, error routing, and headers.
  - `crud.ts`: Client endpoints serving CRUD create/read/update/delete operations.
- **`routes/`**
  Routing central control.
  - `AppRoutes.tsx`: Defines the application's URL paths, maps path endpoints to flagship feature pages or registry-driven screens, and enforces auth guards.
- **`utils/`**
  Domain-agnostic utility helper functions.
  - `format.ts`: Robust, defensive formatting utilities converting raw strings/numbers to Indian currency (`inr`), dates, percentages, and deadlines.
- **`App.tsx`**
  The root component mounting the central `AppRoutes`.
- **`main.tsx`**
  Vite entry bundle linking the strict mode wrapper, Material-UI theme provider, QueryClient provider, and mounting it to the DOM.

### Create, edit, delete (the write layer)

The list screens are fully interactive — **New**, **Edit** and **Delete** work
and persist to the database:

- A generic CRUD framework (`/api/crud/:resource`) serves create/read/update/
  delete for every editable resource — parties, items, charge types, accounts,
  voucher types, orders, shipments, declarations, cost sheets, licences,
  instruments, entitlements, reconciliations — entity-scoped and
  permission-checked. The front end drives it from one form drawer
  (`components/CrudForm.tsx`) plus a field registry, so every registry screen
  gets working New/Edit/Delete from shared code.
- **Nested line editing.** A document's child rows are editable in place through
  a generic children API (`/api/crud/:resource/:id/:child`) and one editable-
  table dialog (`components/LinesEditor.tsx`): an order's line items, a cost
  sheet's charge lines, a licence's obligation blocks, an instrument's document
  requirements, a reconciliation's items — add/edit/remove rows and save.
- **Vouchers** have the full lifecycle: the **New voucher** form records a
  business event, shows the posting the rule produces, and **Park** or **Park &
  post** persists it — creating the voucher and its posting lines, validating
  double entry, then allocating the gapless number on post. A posted voucher is
  immutable and is corrected by **Reverse**, which posts a mirror-image voucher
  and marks the original reversed (the trial balance stays balanced).
- Every write is gated by permission: sign in as `audit` and the New/Edit/
  Delete/Reverse controls are disabled, and the API refuses the call.

> **Which screens persist, and which role to use.** Twenty-five list screens are
> backed by the database and their New/Edit/Delete create real rows:
> **orders, shipments, declarations, parties, providers, accounts, voucher
> types, number series, licences, instruments, cost sheets, entitlements**, plus
> the operational registers **indents, goods receipts, document sets, bookings,
> containers, export enquiries, export invoices, provider invoices, bank charges
> and insurance policies** (migration 009). They enable only for a role that
> holds the matching `resource:write` permission, so **sign in as `controller`**
> (the default) to use them; the `admin` role manages users and the `audit` role
> is read-only, so with those most New buttons stay disabled by design.
>
> **Analytical screens** — Trial balance, Financial statements, Ledger enquiry,
> Cockpit, Compliance monitor, Profitability, Duty register — are **live views
> computed from the ledger and transactions**, not editable records (you don't
> "create" a trial balance), so they have no New button by design.
>
> Batch 2 (migration 010) added the remaining record lists: **sourcing
> comparison, post-clearance cases, export realisations, container stuffing,
> bank presentations, collections & bills, FX exposure/hedges, bonded
> operations, regulatory changes, credentials & registrations, the filing
> calendar, origin & preference determinations, document checklists and
> compliance content packs** — all now full create/edit/delete against real
> tables. Every operational register in the navigation is database-backed;
> the only remaining sample-data corners are a couple of bespoke read
> workspaces (broker workspace, roles overview) and the analytical views above.

### Administration & operations

The **Administration** nav group (sign in as `admin`) adds the management
surface that was previously API-only:

- **Users & access** — create users, assign and revoke roles (an SoD-breaching
  grant is refused with its reason), activate/deactivate, reset passwords, view
  each user's roles and entity access.
- **Businesses (tenants)** — provision a new business **at runtime**: one click
  creates the database, applies every migration, seeds a chart of accounts,
  voucher types, number series and open periods, and creates an administrator —
  then shows the credentials to sign in with.
- **Accounting periods** — open, soft-close and hard-close periods; every lock
  change is written to the audit trail.
- **Number series** — administer the gapless statutory series per voucher type.
- **Integrations** — transmit/poll customs declarations (ICEGATE), request
  realisation status (EDPMS) and send bank-host messages, with a live message
  journal. The gateways are **simulated**: the request/response lifecycle and
  journal are production-shaped, so swapping the simulator for a real HTTP
  client is the only remaining change.
- **Audit log** — the append-only record of every create, edit, delete, post,
  reversal, transmission and period change.

**Print & export.** A voucher prints to a formatted HTML document (browser
print-to-PDF); the trial balance prints and **exports to Excel** (`.xlsx` via
exceljs).

**Scale.** The high-volume screens (voucher register, and any generic-CRUD
resource) **page, search and count on the server** — each page is one windowed
SQL query plus a `COUNT`, so a million-row table loads one 50-row page at a time
instead of shipping the whole set to the browser (`components/ServerDataTable.tsx`).

---

## Verification performed

- `tsc --noEmit` clean on both workspaces.
- All six migrations apply clean to an empty database (`db:reset`).
- Seed loads with the trial balance balancing **exactly** (equity is the
  computed residual); every screen's figures are engine-derived so they agree.
- Auth flow, RBAC (permission denial), row-level scoping, and SoD blocking
  verified over the live API.
- Transactional posting verified: gapless number allocated, evidence gate,
  double-entry check, already-posted guard, rollup stays balanced.
- Full browser flow verified headlessly: login → cockpit → flagship routes → the
  six Administration routes → the server-paged voucher register, **zero
  console/page errors**; post-from-UI as controller succeeds and is disabled for
  the read-only auditor.
- **Automated integration test suite** (`cd apps/api && npm test`, node:test):
  **11 passing** — health, login (+ bad-password rejection), database-per-tenant
  isolation, RBAC denial, the full CRUD lifecycle, voucher park→post→reverse with
  the trial balance staying balanced, unbalanced-voucher rejection, server-side
  pagination and search, SoD-enforced role grants, and period lock + audit trail.
- Server-side pagination/search verified end-to-end (distinct page windows, page
  totals, `q` narrowing) against the live API.
- 3.2M-row slice generated and the heavy queries benchmarked with `EXPLAIN`.

---

## Proven vs designed

**Proven here.** The schema, migrations, seed, the full authed API, transactional
posting **and reversal**, RBAC/SoD, **database-per-tenant isolation across two
live tenant databases**, **runtime tenant provisioning** (create DB + migrate +
seed + admin in one call), the **Administration UI** (users/roles/access,
tenants, periods, number series, integrations, audit log), **server-side
pagination + search** on the high-volume grids, **print/HTML + Excel export**,
**simulated external connectors** (ICEGATE/EDPMS/bank host) with a journalled
lifecycle, an **automated integration test suite** (11 tests), the front end
against the real API (with a business picker), and the query performance on a
~1M-`posting_line` / ~1.44M-`levy` slice with partition pruning and rollups.

**Designed for, not physically loaded here.** The full 250M-`posting_line`
target — the sandbox can't hold it. The design targets it (partitioning,
rollups, covering indexes, keyset pagination, monthly partition maintenance) and
the benchmarks are run on the largest feasible slice with the extrapolation
stated above and its assumptions made explicit.

**Newly built (this round).** Runtime tenant-provisioning UI; the full
user/role/entity-access administration UI; server-side pagination + search wired
into the grids (voucher register live; every generic-CRUD resource supported);
print-ready HTML for vouchers and the trial balance plus Excel export; the
period lock/unlock, number-series and audit-log screens; the simulated
ICEGATE/EDPMS/bank-host connectors with a message journal; and an automated
integration test suite (`npm test`).

**Not built.** Declaration line + levy editing in place (the header is full CRUD;
lines are read via the engine); cost-sheet allocation and closure still post as
previews rather than a persisted closure voucher; real file upload for evidence
(attach is a toggle); the "Audit file" builder button on the voucher screen;
**pixel-exact** RD §8 print templates (the current print output is clean and
functional HTML, not the fully-styled statutory stationery); **live** external
gateways (the connectors are simulated behind a production-shaped lifecycle);
and horizontal read-replica routing.
