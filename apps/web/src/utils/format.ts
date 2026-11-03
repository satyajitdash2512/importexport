/** Indian-convention formatting. Statutory outputs must not follow user locale. */

function parseNum(val: unknown): number | null {
  if (val === null || val === undefined || val === '') return null;
  const num = typeof val === 'string' ? parseFloat(val) : Number(val);
  return Number.isNaN(num) ? null : num;
}

export function inr(value: any, opts: { decimals?: boolean; blankZero?: boolean } = {}) {
  const num = parseNum(value);
  if (num === null) return '—';
  if (num === 0 && opts.blankZero) return '—';
  const neg = num < 0;
  const abs = Math.abs(num);
  const fixed = opts.decimals ? abs.toFixed(2) : Math.round(abs).toString();
  const [whole, dec] = fixed.split('.');
  // Indian grouping: last three digits, then pairs
  let out = '';
  if (whole.length > 3) {
    const last3 = whole.slice(-3);
    const rest = whole.slice(0, -3);
    out = rest.replace(/\B(?=(\d{2})+(?!\d))/g, ',') + ',' + last3;
  } else out = whole;
  const body = dec ? `${out}.${dec}` : out;
  return neg ? `(${body})` : body;
}

export function money(value: any, currency = 'INR', decimals = false) {
  const num = parseNum(value);
  if (num === null) return '—';
  if (currency === 'INR') return inr(num, { decimals });
  const neg = num < 0;
  const s = Math.abs(num).toLocaleString('en-US', { minimumFractionDigits: decimals ? 2 : 0, maximumFractionDigits: decimals ? 2 : 0 });
  return neg ? `(${s})` : s;
}

export function qty(value: any, unit?: string) {
  const num = parseNum(value);
  if (num === null) return '—';
  const s = num.toLocaleString('en-IN', { maximumFractionDigits: 3 });
  return unit ? `${s} ${unit}` : s;
}

export function pct(value: any, dp = 1) {
  const num = parseNum(value);
  if (num === null) return '—';
  return `${num.toFixed(dp)}%`;
}

const MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export function date(iso?: string | null) {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return `${String(d.getDate()).padStart(2, '0')}-${MON[d.getMonth()]}-${d.getFullYear()}`;
}

export function dateTime(iso?: string | null) {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return `${date(iso)} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

/** Days from today (negative = in the past). Today is fixed for a stable demo. */
export const TODAY = new Date('2026-08-04T09:00:00');

export function daysFromToday(iso?: string | null) {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  return Math.round((d.getTime() - TODAY.getTime()) / 864e5);
}

export function relativeDeadline(iso?: string | null) {
  const d = daysFromToday(iso);
  if (d === null) return '—';
  if (d === 0) return 'today';
  if (d === 1) return 'tomorrow';
  if (d > 0) return `${d} days`;
  return `${Math.abs(d)} days overdue`;
}
