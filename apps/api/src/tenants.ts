import { config } from './db/env.js';

/**
 * The businesses (tenants) provisioned in this build. Each has its OWN database.
 * In a real deployment this list is the `tenant` table in the control database
 * and new tenants are provisioned at runtime; here it is the fixed demo set that
 * the migrator and seed share.
 */
export interface TenantDef {
  code: string; name: string; db: string; entityCode: string; iec: string; pan: string;
}

export const TENANTS: TenantDef[] = [
  { code: 'HBML', name: 'HB Manufacturing Ltd', db: `${config.db.tenantDbPrefix}hbml`, entityCode: 'HBML', iec: '0507088123', pan: 'AABCH1234K' },
  { code: 'ACME', name: 'Acme Trading Ltd', db: `${config.db.tenantDbPrefix}acme`, entityCode: 'ACME', iec: '0611022233', pan: 'AACCA5678M' },
];
