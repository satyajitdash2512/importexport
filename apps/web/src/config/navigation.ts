/**
 * Information architecture — RD Figure 19.1.
 * Every screen in the RD screen inventory (Table 19.2) plus the accounting
 * screens added by RD v2.0 sections 4 to 9 and 17 to 18.
 */

export interface NavItem {
  label: string;
  path: string;
  /** RD screen id where one exists. */
  screen?: string;
  badge?: 'exceptions' | 'tasks';
}

export interface NavGroup {
  label: string;
  icon: string;
  items: NavItem[];
}

export const navigation: NavGroup[] = [
  {
    label: 'Cockpit', icon: 'dashboard',
    items: [{ label: 'Trade cockpit', path: '/', screen: 'S-01' }],
  },
  {
    label: 'Import', icon: 'download',
    items: [
      { label: 'Indents', path: '/import/indents', screen: 'S-04' },
      { label: 'Purchase orders', path: '/import/orders', screen: 'S-06' },
      { label: 'Sourcing comparison', path: '/import/sourcing', screen: 'S-05' },
      { label: 'Shipments', path: '/import/shipments', screen: 'S-03' },
      { label: 'Declarations', path: '/import/declarations', screen: 'S-07' },
      { label: 'Document sets', path: '/import/documents', screen: 'S-10' },
      { label: 'Goods receipts', path: '/import/receipts', screen: 'S-11' },
      { label: 'Post-clearance cases', path: '/import/post-clearance' },
    ],
  },
  {
    label: 'Export', icon: 'upload',
    items: [
      { label: 'Enquiries & quotations', path: '/export/enquiries', screen: 'S-14' },
      { label: 'Orders', path: '/export/orders', screen: 'S-15' },
      { label: 'Shipments', path: '/export/shipments' },
      { label: 'Invoices & documents', path: '/export/invoices', screen: 'S-16' },
      { label: 'Declarations', path: '/export/declarations', screen: 'S-08' },
      { label: 'Container stuffing', path: '/export/stuffing', screen: 'S-17' },
      { label: 'Realisations', path: '/export/realisations', screen: 'S-20' },
      { label: 'Entitlement claims', path: '/export/entitlements', screen: 'S-21' },
    ],
  },
  {
    label: 'Compliance', icon: 'verified',
    items: [
      { label: 'Compliance monitor', path: '/compliance/monitor', screen: 'S-23', badge: 'exceptions' },
      { label: 'Licences & obligations', path: '/compliance/licences', screen: 'S-22' },
      { label: 'Screening & reviews', path: '/compliance/screening', screen: 'S-24' },
      { label: 'Origin & preference', path: '/compliance/origin', screen: 'S-25' },
      { label: 'Bonded operations', path: '/compliance/bonded', screen: 'S-26' },
      { label: 'Credentials & registrations', path: '/compliance/credentials', screen: 'S-27' },
      { label: 'Filing calendar', path: '/compliance/filings', screen: 'S-28' },
      { label: 'Regulatory changes', path: '/compliance/changes', screen: 'S-34' },
    ],
  },
  {
    label: 'Logistics', icon: 'local_shipping',
    items: [
      { label: 'Bookings', path: '/logistics/bookings', screen: 'S-30' },
      { label: 'Containers & free time', path: '/logistics/containers', screen: 'S-29' },
      { label: 'Providers & rates', path: '/logistics/providers' },
      { label: 'Insurance & claims', path: '/logistics/insurance' },
      { label: 'Provider invoices', path: '/logistics/invoices', screen: 'S-13' },
      { label: 'Performance', path: '/logistics/performance' },
    ],
  },
  {
    label: 'Trade finance', icon: 'account_balance',
    items: [
      { label: 'Instruments', path: '/finance/instruments', screen: 'S-19' },
      { label: 'Bank presentations', path: '/finance/presentations', screen: 'S-18' },
      { label: 'Collections & bills', path: '/finance/collections' },
      { label: 'Exposure & hedges', path: '/finance/exposure', screen: 'S-31' },
      { label: 'Bank charges', path: '/finance/charges' },
    ],
  },
  {
    label: 'Costing', icon: 'calculate',
    items: [
      { label: 'Landed cost sheets', path: '/finance/landed-cost', screen: 'S-12' },
      { label: 'Duty & tax', path: '/finance/duty' },
      { label: 'Profitability', path: '/finance/profitability' },
    ],
  },
  {
    label: 'Accounting', icon: 'menu_book',
    items: [
      { label: 'Vouchers', path: '/accounting/vouchers', screen: 'A-01', badge: 'tasks' },
      { label: 'New voucher', path: '/accounting/vouchers/new', screen: 'A-02' },
      { label: 'Chart of accounts', path: '/accounting/accounts', screen: 'A-03' },
      { label: 'Trial balance', path: '/accounting/trial-balance', screen: 'A-04' },
      { label: 'Ledger enquiry', path: '/accounting/ledger', screen: 'A-05' },
      { label: 'Voucher types', path: '/accounting/voucher-types', screen: 'A-06' },
      { label: 'Posting rules', path: '/accounting/posting-rules', screen: 'A-07' },
      { label: 'Financial statements', path: '/accounting/statements', screen: 'A-08' },
    ],
  },
  {
    label: 'Close', icon: 'task_alt',
    items: [
      { label: 'Close checklist', path: '/close/checklist', screen: 'S-32' },
      { label: 'Reconciliations', path: '/close/reconciliations', screen: 'S-33' },
      { label: 'Audit file builder', path: '/close/audit-file', screen: 'S-36' },
    ],
  },
  {
    label: 'Setup', icon: 'settings',
    items: [
      { label: 'Trade partners', path: '/setup/parties' },
      { label: 'Items & classification', path: '/setup/items' },
      { label: 'Charge types', path: '/setup/charges' },
      { label: 'Document checklists', path: '/setup/checklists' },
      { label: 'Compliance content packs', path: '/setup/packs' },
      { label: 'Roles & permissions', path: '/setup/roles' },
      { label: 'Broker workspace', path: '/setup/broker', screen: 'S-35' },
    ],
  },
  {
    label: 'Administration', icon: 'settings',
    items: [
      { label: 'Users & access', path: '/admin/users' },
      { label: 'Businesses (tenants)', path: '/admin/tenants' },
      { label: 'Accounting periods', path: '/accounting/periods' },
      { label: 'Number series', path: '/accounting/number-series' },
      { label: 'Integrations', path: '/admin/integrations' },
      { label: 'Audit log', path: '/admin/audit' },
    ],
  },
];

/** Flat lookup of every route for the verification sweep and for search. */
export const allRoutes = navigation.flatMap((g) => g.items.map((i) => ({ ...i, group: g.label })));
