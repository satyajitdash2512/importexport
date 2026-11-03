# Database dump — ready-to-load

This folder is a **complete snapshot of all three databases**, seeded and with the
trial balance balancing exactly. Load these if you want the data without running
the migrate + seed pipeline (`npm run db:reset`).

Three MySQL dumps (each begins with `CREATE DATABASE IF NOT EXISTS … / USE …`, so
they restore standalone):

| File | Database | Contents |
|---|---|---|
| `hb_control.sql` | `hb_control` | tenant registry, users, roles, permissions, SoD rules |
| `hb_tenant_hbml.sql` | `hb_tenant_hbml` | HB Manufacturing Ltd — full trade + accounting data |
| `hb_tenant_acme.sql` | `hb_tenant_acme` | Acme Trading Ltd — full trade + accounting data |

## Load

MySQL 8 must be running. From this folder:

```bash
./load.sh                       # uses root by default
# or with explicit credentials / host:
DB_USER=root DB_PASSWORD=secret DB_HOST=127.0.0.1 ./load.sh
```

Or load them by hand, in this order (control first):

```bash
mysql -u root < hb_control.sql
mysql -u root < hb_tenant_hbml.sql
mysql -u root < hb_tenant_acme.sql
```

## After loading

The API connects as the application user configured in `apps/api/.env`
(`DB_USER` / `DB_PASSWORD`), not as root. Grant that user access to all three
databases once:

```sql
CREATE USER IF NOT EXISTS 'hb_app'@'%' IDENTIFIED BY 'change-me';
GRANT ALL PRIVILEGES ON hb_control.*      TO 'hb_app'@'%';
GRANT ALL PRIVILEGES ON `hb_tenant_%`.*   TO 'hb_app'@'%';
FLUSH PRIVILEGES;
```

Then start the API (`npm run dev:api`) and the web app (`npm run dev`) and sign
in — business **HBML**, user `admin` or `controller`, password `hbtrade123`.

> These dumps are the **demo** dataset. On a real deployment you would load
> `hb_control` plus one freshly-provisioned tenant database (Administration →
> Businesses → Provision), not the demo tenants.
