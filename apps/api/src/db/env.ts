/**
 * Central configuration. Everything is overridable by environment variable so
 * the same build runs against a local MySQL, a Docker Compose service, or a
 * managed instance without a code change. Defaults match the sandbox setup
 * (see db/README and docker-compose.yml).
 */
function env(name: string, fallback: string): string {
  const v = process.env[name];
  return v === undefined || v === '' ? fallback : v;
}
function num(name: string, fallback: number): number {
  const v = process.env[name];
  const n = v === undefined || v === '' ? NaN : Number(v);
  return Number.isFinite(n) ? n : fallback;
}

export const config = {
  db: {
    host: env('DB_HOST', '127.0.0.1'),
    port: num('DB_PORT', 3306),
    user: env('DB_USER', 'hb_app'),
    password: env('DB_PASSWORD', 'hb_app_pw'),
    database: env('DB_NAME', 'hb_trade'),
    // database-per-tenant: the control (directory + auth) database, and the
    // naming convention for a tenant's own business database.
    controlDatabase: env('CONTROL_DB_NAME', 'hb_control'),
    tenantDbPrefix: env('TENANT_DB_PREFIX', 'hb_tenant_'),
    // The pool is sized for the API process. The heavy generator opens its own
    // short-lived connections so it never starves request handlers.
    connectionLimit: num('DB_POOL_SIZE', 20),
    // Admin credentials — used only by the migration runner (DDL) and the
    // reset script. The application never connects as this user.
    adminUser: env('DB_ADMIN_USER', 'root'),
    adminPassword: env('DB_ADMIN_PASSWORD', ''),
  },
  auth: {
    jwtSecret: env('JWT_SECRET', 'dev-only-change-me-hb-trade-access'),
    refreshSecret: env('JWT_REFRESH_SECRET', 'dev-only-change-me-hb-trade-refresh'),
    accessTtlSeconds: num('ACCESS_TTL', 15 * 60), // 15 minutes
    refreshTtlSeconds: num('REFRESH_TTL', 7 * 24 * 3600), // 7 days
    bcryptRounds: num('BCRYPT_ROUNDS', 10),
  },
  server: {
    port: num('PORT', 4000),
    // The demo period the seed data lives in. Registers and the trial balance
    // default to this when the caller does not specify one.
    defaultPeriodKey: num('DEFAULT_PERIOD_KEY', 202607),
  },
};

export type Config = typeof config;
