# Database — schema and data

Everything for the MySQL side of HB Import & Export, in one place.

## Two databases (database-per-tenant)

- **`hb_control`** — directory + auth plane: tenant registry, users, roles,
  permissions, SoD rules, refresh tokens. No business data.
- **`hb_tenant_<code>`** — one per business, holding the full trade + accounting
  schema (102 tables, views and stored routines). The demo ships two:
  `hb_tenant_hbml` and `hb_tenant_acme`.

## What's in this folder

```
database/
  schema/
    01_control_schema.sql   consolidated CREATE for the control database
    02_tenant_schema.sql    consolidated CREATE for ONE business database
                            (migrations 001..010 concatenated, in order)
  full-dump/
    hb_control.sql          schema + seeded data (mysqldump)
    hb_tenant_hbml.sql      schema + seeded data for HB Manufacturing Ltd
    hb_tenant_acme.sql      schema + seeded data for Acme Trading Ltd
    load.sh                 restores all three databases in the right order
```

`schema/` is the structure only (empty tables) — use it to stand up a fresh,
clean database. `full-dump/` is structure **and** the balanced demo data — use it
to get a working system immediately.

## Option A — load the ready-made databases (schema + data)

```bash
cd full-dump
./load.sh                 # uses local root by default
# or: DB_USER=root DB_PASSWORD=secret DB_HOST=127.0.0.1 ./load.sh
```

## Option B — create empty databases from the schema only

```bash
mysql -u root < schema/01_control_schema.sql
mysql -u root -e "CREATE DATABASE hb_tenant_hbml CHARACTER SET utf8mb4;"
mysql -u root hb_tenant_hbml < schema/02_tenant_schema.sql
# repeat 02_tenant_schema.sql against each additional business database
```

## Option C — let the app build and seed it for you

From `apps/api`: `npm run db:reset` (migrate + seed), or just
`docker compose up --build` from the repo root, which does it automatically.

## After loading

The API connects as the application user in `apps/api/.env` (`DB_USER` /
`DB_PASSWORD`), not root. Grant it access once:

```sql
CREATE USER IF NOT EXISTS 'hb_app'@'%' IDENTIFIED BY 'change-me';
GRANT ALL PRIVILEGES ON hb_control.*    TO 'hb_app'@'%';
GRANT ALL PRIVILEGES ON `hb_tenant_%`.* TO 'hb_app'@'%';
FLUSH PRIVILEGES;
```

> The canonical schema is the migration set under
> `apps/api/db/migrations/`. The files here are generated conveniences: the
> `schema/*.sql` are those migrations concatenated, and `full-dump/*.sql` are
> `mysqldump` snapshots of the seeded databases.
