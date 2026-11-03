#!/usr/bin/env bash
# Restore the HB Import & Export databases (control first, then each tenant).
# Credentials come from the environment; sensible defaults use local root.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER="${DB_USER:-root}"
ARGS=(-u "$USER")
[ -n "${DB_PASSWORD:-}" ] && ARGS+=("-p${DB_PASSWORD}")
[ -n "${DB_HOST:-}" ] && ARGS+=(-h "${DB_HOST}")
[ -n "${DB_PORT:-}" ] && ARGS+=(-P "${DB_PORT}")

for db in hb_control hb_tenant_hbml hb_tenant_acme; do
  echo "Loading ${db} …"
  mysql "${ARGS[@]}" < "${DIR}/${db}.sql"
done

echo "Done. All three databases restored."
