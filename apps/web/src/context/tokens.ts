/**
 * ============================================================================
 *  HOSTBOOKS DESIGN TOKENS  —  THE ONLY FILE YOU EDIT TO RE-BRAND
 * ============================================================================
 *
 *  Every colour, radius, font size and spacing value used anywhere in the
 *  application resolves to a token declared here. No component contains a
 *  literal hex value. To match an updated brand palette, change the values in
 *  this file only; nothing else needs to be touched.
 *
 *  Values below were derived from the supplied HostBooks product screenshot
 *  (contact detail screen): flat surfaces with no elevation, filled mid-blue
 *  KPI tiles with white text, pill-style active tabs on a light blue wash,
 *  four-column bold-label / regular-value field grids, outlined blue action
 *  buttons, and light blue-grey separator bands between blocks.
 * ============================================================================
 */

export const color = {
  /* ---- brand blues ---------------------------------------------------- */
  /** Page titles, links, outlined button text and borders, active tab text. */
  primary: '#1B76B8',
  /** Hover / pressed state for primary. */
  primaryDark: '#145E93',
  /** Fill of the KPI tile strip and of filled primary buttons. */
  primaryTile: '#4E92C4',
  /** Wash behind an active pill tab, selected row, hover row. */
  primarySoft: '#E9F3FB',
  /** Border of an active pill tab and of outlined controls. */
  primaryBorder: '#A8CDE8',

  /* ---- surfaces ------------------------------------------------------- */
  /** Application canvas behind cards. */
  canvas: '#EDF2F7',
  /** Light blue-grey separator band between content blocks. */
  band: '#E8EEF4',
  /** Card / content background. */
  surface: '#FFFFFF',
  /** Table header background. */
  tableHeader: '#F4F7FA',
  /** Hairline borders and dividers. */
  border: '#D8E1EA',
  borderStrong: '#C3D0DC',

  /* ---- text ----------------------------------------------------------- */
  /** Body and value text. */
  text: '#1F2A37',
  /** Bold field labels. */
  label: '#37474F',
  /** Secondary, helper and placeholder text. */
  muted: '#6B7A8C',
  /** Text on a filled brand surface. */
  onPrimary: '#FFFFFF',

  /* ---- semantic ------------------------------------------------------- */
  success: '#2E9E4F',
  successSoft: '#E8F6EC',
  warning: '#E08600',
  warningSoft: '#FDF3E3',
  danger: '#C0392B',
  dangerSoft: '#FBEBE9',
  info: '#1B76B8',
  infoSoft: '#E9F3FB',
  /** The pinned survey/help tab accent in the product. */
  accentYellow: '#F5C400',

  /* ---- posting / accounting semantics --------------------------------- */
  debit: '#1F2A37',
  credit: '#1F2A37',
  varianceUp: '#C0392B',
  varianceDown: '#2E9E4F',
} as const;

/** Severity scale used by exceptions, alerts and deadlines. */
export const severity = {
  critical: { fg: color.danger, bg: color.dangerSoft, label: 'Critical', mark: '●' },
  high: { fg: color.warning, bg: color.warningSoft, label: 'High', mark: '▲' },
  medium: { fg: color.info, bg: color.infoSoft, label: 'Medium', mark: '■' },
  info: { fg: color.muted, bg: color.band, label: 'Info', mark: '○' },
} as const;
export type SeverityKey = keyof typeof severity;

export const font = {
  family: '"Segoe UI", Roboto, "Helvetica Neue", Arial, system-ui, sans-serif',
  mono: '"Cascadia Mono", Consolas, "Liberation Mono", monospace',
  size: {
    pageTitle: 18,
    sectionTitle: 15,
    tileLabel: 12,
    tileValue: 20,
    label: 12,
    body: 13,
    table: 12.5,
    small: 11.5,
  },
  weight: { regular: 400, medium: 500, semibold: 600, bold: 700 },
} as const;

export const shape = {
  radius: 4,
  radiusSm: 3,
  radiusPill: 14,
  border: `1px solid ${color.border}`,
} as const;

export const layout = {
  topBarHeight: 48,
  sidebarWidth: 244,
  sidebarCollapsedWidth: 56,
  bandHeight: 10,
  contentMaxWidth: 2200,
  density: 'compact' as const,
  rowHeight: 32,
  headerHeight: 34,
} as const;

/** Flat product: elevation is expressed with borders and bands, not shadows. */
export const elevation = {
  none: 'none',
  overlay: '0 4px 16px rgba(31,42,55,0.14)',
  popover: '0 2px 8px rgba(31,42,55,0.12)',
} as const;
