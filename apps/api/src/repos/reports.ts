import ExcelJS from 'exceljs';
import { q, q1, n } from '../db/pool.js';
import { config } from '../db/env.js';
import { trialBalance } from './accounting.js';
import { getVoucher } from './accounting.js';
import { HttpError } from '../http/context.js';

const inr = (v: number) => Number(v || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const esc = (s: any) => String(s ?? '').replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c] as string));

const shell = (title: string, body: string) => `<!doctype html><html><head><meta charset="utf-8"><title>${esc(title)}</title>
<style>
  @page { size: A4; margin: 16mm; }
  body { font: 12px/1.4 'Segoe UI', Arial, sans-serif; color: #1F2A37; }
  h1 { font-size: 18px; color: #145E93; margin: 0 0 2px; }
  .sub { color: #6B7A8C; font-size: 11px; margin-bottom: 14px; }
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid #D8E1EA; padding: 5px 7px; text-align: left; }
  th { background: #F4F7FA; font-weight: 600; }
  td.n, th.n { text-align: right; font-variant-numeric: tabular-nums; }
  tfoot td { font-weight: 700; background: #F4F7FA; }
  .print-hint { margin: 12px 0; color: #6B7A8C; font-size: 11px; }
  @media print { .print-hint { display: none; } }
</style></head><body>
<div class="print-hint">Use your browser's Print (Ctrl/Cmd-P) → Save as PDF.</div>
${body}
</body></html>`;

/** Printable voucher (browser prints to PDF). */
export async function printVoucher(entityId: number, idStr: string): Promise<string> {
  const v = await getVoucher(entityId, idStr);
  if (!v) throw new HttpError(404, 'Voucher not found');
  const rows = v.lines.map((l) => `<tr><td>${esc(l.accountCode)}</td><td>${esc(l.accountName)}</td>
    <td class="n">${l.drCr === 'Dr' ? inr(l.amountFunc) : ''}</td><td class="n">${l.drCr === 'Cr' ? inr(l.amountFunc) : ''}</td></tr>`).join('');
  const ev = v.evidence.map((e) => `<li>${esc(e.docType)} — ${esc(e.name)} ${e.attached ? '✓' : '(missing)'}</li>`).join('');
  const body = `
    <h1>${esc(v.voucherTypeName)}</h1>
    <div class="sub">${esc(v.number ?? '(unnumbered)')} · ${esc(v.date)} · book ${esc(v.book)} · status ${esc(v.status)}</div>
    <p><b>Narration:</b> ${esc(v.narration)}</p>
    <table><thead><tr><th>Account</th><th>Name</th><th class="n">Debit</th><th class="n">Credit</th></tr></thead>
      <tbody>${rows}</tbody>
      <tfoot><tr><td colspan="2">Total</td><td class="n">${inr(v.totalDr)}</td><td class="n">${inr(v.totalCr)}</td></tr></tfoot>
    </table>
    <p class="sub">Posting rule ${esc(v.postingRule)} ${esc(v.postingRuleVersion)} · prepared by ${esc(v.preparedBy)}${v.approvedBy ? ` · approved by ${esc(v.approvedBy)}` : ''}</p>
    <p><b>Evidence</b></p><ul>${ev || '<li>None</li>'}</ul>`;
  return shell(`Voucher ${v.number ?? ''}`, body);
}

/** Printable trial balance. */
export async function printTrialBalance(entityId: number): Promise<string> {
  const tb = await trialBalance(entityId);
  const rows = tb.rows.map((r) => `<tr><td>${esc(r.code)}</td><td>${esc(r.name)}</td>
    <td class="n">${r.closingDr ? inr(r.closingDr) : ''}</td><td class="n">${r.closingCr ? inr(r.closingCr) : ''}</td></tr>`).join('');
  const body = `
    <h1>Trial balance</h1>
    <div class="sub">${esc(tb.book)} · ${esc(tb.period)} · ${tb.balanced ? 'balanced' : 'OUT OF BALANCE'}</div>
    <table><thead><tr><th>Code</th><th>Account</th><th class="n">Debit</th><th class="n">Credit</th></tr></thead>
      <tbody>${rows}</tbody>
      <tfoot><tr><td colspan="2">Total</td><td class="n">${inr(tb.totals.closingDr)}</td><td class="n">${inr(tb.totals.closingCr)}</td></tr></tfoot>
    </table>`;
  return shell('Trial balance', body);
}

/** Trial balance as a real .xlsx workbook. */
export async function trialBalanceXlsx(entityId: number): Promise<Buffer> {
  const tb = await trialBalance(entityId);
  const wb = new ExcelJS.Workbook();
  wb.creator = 'HB Trade';
  const ws = wb.addWorksheet('Trial balance');
  ws.columns = [
    { header: 'Code', key: 'code', width: 12 },
    { header: 'Account', key: 'name', width: 46 },
    { header: 'Class', key: 'cls', width: 12 },
    { header: 'Opening Dr', key: 'odr', width: 16, style: { numFmt: '#,##0.00' } },
    { header: 'Opening Cr', key: 'ocr', width: 16, style: { numFmt: '#,##0.00' } },
    { header: 'Period Dr', key: 'pdr', width: 16, style: { numFmt: '#,##0.00' } },
    { header: 'Period Cr', key: 'pcr', width: 16, style: { numFmt: '#,##0.00' } },
    { header: 'Closing Dr', key: 'cdr', width: 16, style: { numFmt: '#,##0.00' } },
    { header: 'Closing Cr', key: 'ccr', width: 16, style: { numFmt: '#,##0.00' } },
  ];
  ws.getRow(1).font = { bold: true };
  ws.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF4F7FA' } };
  for (const r of tb.rows) ws.addRow({ code: r.code, name: r.name, cls: r.class, odr: r.openingDr, ocr: r.openingCr, pdr: r.periodDr, pcr: r.periodCr, cdr: r.closingDr, ccr: r.closingCr });
  const total = ws.addRow({ code: '', name: 'TOTAL', cls: '', odr: tb.totals.openingDr, ocr: tb.totals.openingCr, pdr: tb.totals.periodDr, pcr: tb.totals.periodCr, cdr: tb.totals.closingDr, ccr: tb.totals.closingCr });
  total.font = { bold: true };
  return Buffer.from(await wb.xlsx.writeBuffer());
}
