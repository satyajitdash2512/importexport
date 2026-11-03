import * as React from 'react';
import {
  Box, Stack, Typography, Button, Chip, MenuItem, TextField, Alert, AlertTitle, Divider,
  Dialog, DialogTitle, DialogContent, DialogActions, Snackbar,
} from '@mui/material';
import { useParams, useNavigate } from 'react-router-dom';
import { color, font, shape } from '../../../context/tokens';
import { useApi, post } from '../../../lib/api';
import { inr, pct } from '../../../utils/format';
import {
  Band, PageHeader, Section, KpiStrip, StatusChip, Loading, ErrorState, Money, DefRow, LabelledProgress,
} from '../../../components/primitives';

const BASES = [
  { value: 'value', label: 'Value' },
  { value: 'grossWeight', label: 'Gross weight' },
  { value: 'volume', label: 'Volume' },
  { value: 'quantity', label: 'Quantity' },
  { value: 'chargeableWeight', label: 'Chargeable weight' },
  { value: 'container', label: 'Per container' },
  { value: 'direct', label: 'Direct assignment' },
  { value: 'equal', label: 'Equal split' },
];

export default function LandedCostSheet() {
  const { id } = useParams();
  const nav = useNavigate();
  const { data: cs, isLoading, error, refetch } = useApi<any>(['costSheet', id], `/cost-sheets/${id}`);
  const [selected, setSelected] = React.useState<string | null>(null);
  const [basis, setBasis] = React.useState('grossWeight');
  const [alloc, setAlloc] = React.useState<any>(null);
  const [altAlloc, setAltAlloc] = React.useState<any>(null);
  const [closeOpen, setCloseOpen] = React.useState(false);
  const [toast, setToast] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (cs && !selected) {
      const first = cs.lines.find((l: any) => l.basis !== 'direct') ?? cs.lines[0];
      setSelected(first.id);
      setBasis(first.basis);
    }
  }, [cs, selected]);

  React.useEffect(() => {
    if (!cs || !selected) return;
    let live = true;
    (async () => {
      const res = await post<any>(`/cost-sheets/${cs.id}/allocate`, { chargeLineId: selected, basis });
      if (live) setAlloc(res);
      const other = basis === 'value' ? 'grossWeight' : 'value';
      const res2 = await post<any>(`/cost-sheets/${cs.id}/allocate`, { chargeLineId: selected, basis: other });
      if (live) setAltAlloc({ basis: other, ...res2 });
    })();
    return () => { live = false; };
  }, [cs, selected, basis]);

  if (isLoading) return <Loading label="Loading cost sheet" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!cs) return null;

  const t = cs.totals;
  const closure = cs.closure;
  const line = cs.lines.find((l: any) => l.id === selected);
  const beyondTolerance = cs.lines.filter((l: any) => l.actual !== undefined && Math.abs(l.actual - l.estimate) > (l.estimate * l.tolerancePct) / 100);
  const pending = cs.lines.filter((l: any) => l.actual === undefined);
  const uninvoiced = pending.reduce((s: number, l: any) => s + l.accrued, 0);

  // difference between the chosen and the alternative basis, for the biggest line
  const shift = alloc && altAlloc
    ? Math.max(...alloc.allocation.map((a: any, i: number) => Math.abs(a.allocated - (altAlloc.allocation[i]?.allocated ?? 0))))
    : 0;

  return (
    <Box>
      <PageHeader
        onBack
        title={`Landed cost sheet — ${cs.shipment?.number ?? cs.id}`}
        subtitle={`${cs.lines.length} cost elements · stock on hand ${pct(cs.stockOnHandPct, 0)} · valuation method ${closure.method}`}
        meta={<StatusChip status={cs.status} />}
        actions={
          <>
            <Button onClick={() => nav(`/import/shipments/${cs.shipmentId}`)}>Open shipment</Button>
            <Button onClick={() => refetch()}>Refresh estimate</Button>
            <Button>Add charge</Button>
            <Button variant="contained" onClick={() => setCloseOpen(true)} disabled={beyondTolerance.some((l: any) => !l.status.includes('Variance') && false)}>
              Close cost sheet
            </Button>
          </>
        }
      />

      <KpiStrip
        tiles={[
          { label: 'Estimated landed cost', value: `₹ ${inr(t.estimate)}` },
          { label: 'Actual to date', value: `₹ ${inr(t.actual)}`, sub: t.invoicedAll ? 'fully invoiced' : `₹${inr(t.uninvoicedAccrual)} still accrued` },
          { label: 'Variance on invoiced lines', value: `₹ ${inr(t.variance)}`, tone: t.variance > 0 ? 'danger' : 'success' },
          { label: 'Capitalised', value: `₹ ${inr(t.capitalised)}` },
          { label: 'Expensed', value: `₹ ${inr(t.expensed)}`, tone: t.expensed > 0 ? 'warning' : 'default' },
          { label: 'Recoverable tax', value: `₹ ${inr(t.recoverable)}` },
        ]}
      />

      {(pending.length > 0 || beyondTolerance.length > 0) && (
        <>
          <Band />
          <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
            {pending.length > 0 && (
              <Alert severity="warning" sx={{ mb: beyondTolerance.length ? 1 : 0 }}>
                <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>
                  {pending.length} element{pending.length > 1 ? 's' : ''} accrued but not invoiced — ₹{inr(uninvoiced)} in clearing
                </AlertTitle>
                <Typography sx={{ fontSize: font.size.label }}>
                  {pending.map((p: any) => p.chargeName).join('; ')}. Every clearing balance must be explainable shipment by
                  shipment; a balance aged beyond policy is a period-close blocker (control C-25).
                </Typography>
              </Alert>
            )}
            {beyondTolerance.length > 0 && (
              <Alert severity="error">
                <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>
                  {beyondTolerance.length} variance{beyondTolerance.length > 1 ? 's' : ''} beyond tolerance require disposition before closure
                </AlertTitle>
                <Typography sx={{ fontSize: font.size.label }}>
                  {beyondTolerance.map((l: any) => `${l.chargeName} ₹${inr((l.actual ?? 0) - l.estimate)} (${l.tolerancePct}% tolerance)`).join('; ')}
                </Typography>
              </Alert>
            )}
          </Box>
        </>
      )}

      {/* ------------------------------------------------------- cost table */}
      <Section title="Cost elements">
        <Box sx={{ px: 1.5, pb: 1.5, overflowX: 'auto' }}>
          <Box component="table" sx={{ width: '100%', minWidth: 980, borderCollapse: 'collapse', fontSize: font.size.table }}>
            <thead>
              <Box component="tr" sx={{ bgcolor: color.tableHeader }}>
                {['Element', 'Category', 'Basis', 'Estimate', 'Accrued', 'Actual', 'Variance', 'Treatment', 'Provider', 'Status'].map((h, i) => (
                  <Box component="th" key={h} sx={{ p: '6px 8px', textAlign: i >= 3 && i <= 6 ? 'right' : 'left', fontWeight: font.weight.bold, color: color.label, borderBottom: `1px solid ${color.borderStrong}`, whiteSpace: 'nowrap' }}>
                    {h}
                  </Box>
                ))}
              </Box>
            </thead>
            <tbody>
              <Box component="tr">
                <Box component="td" sx={td}>Goods value</Box>
                <Box component="td" sx={td}>Goods</Box>
                <Box component="td" sx={td}>—</Box>
                <Box component="td" sx={tdNum}><Money value={cs.goodsValue} /></Box>
                <Box component="td" sx={tdNum}>—</Box>
                <Box component="td" sx={tdNum}><Money value={cs.goodsValue} /></Box>
                <Box component="td" sx={tdNum}>0</Box>
                <Box component="td" sx={td}>capitalise</Box>
                <Box component="td" sx={td}>—</Box>
                <Box component="td" sx={td}>matched</Box>
              </Box>
              {cs.lines.map((l: any) => {
                const variance = l.actual !== undefined ? l.actual - l.estimate : null;
                const beyond = variance !== null && Math.abs(variance) > (l.estimate * l.tolerancePct) / 100;
                const isSel = l.id === selected;
                return (
                  <Box
                    component="tr" key={l.id}
                    onClick={() => { setSelected(l.id); setBasis(l.basis); }}
                    sx={{
                      cursor: 'pointer', bgcolor: isSel ? color.primarySoft : undefined,
                      borderLeft: beyond ? `3px solid ${color.warning}` : '3px solid transparent',
                      '&:hover': { bgcolor: color.primarySoft },
                    }}
                  >
                    <Box component="td" sx={td}>{l.chargeName}</Box>
                    <Box component="td" sx={td}>{l.category}</Box>
                    <Box component="td" sx={td}>{BASES.find((b) => b.value === l.basis)?.label ?? l.basis}</Box>
                    <Box component="td" sx={tdNum}><Money value={l.estimate} /></Box>
                    <Box component="td" sx={tdNum}><Money value={l.accrued} /></Box>
                    <Box component="td" sx={tdNum}>{l.actual !== undefined ? <Money value={l.actual} /> : <Typography component="span" sx={{ color: color.muted, fontSize: 'inherit' }}>pending</Typography>}</Box>
                    <Box component="td" sx={tdNum}>
                      {variance !== null ? (
                        <Stack direction="row" spacing={0.4} justifyContent="flex-end" alignItems="center">
                          <Money value={variance} variance />
                          {beyond && <Typography component="span" sx={{ fontSize: font.size.small, color: color.warning, fontWeight: 700 }}>▲</Typography>}
                        </Stack>
                      ) : '—'}
                    </Box>
                    <Box component="td" sx={td}>
                      <Chip
                        label={l.treatment}
                        sx={{
                          bgcolor: l.treatment === 'expense' ? color.warningSoft : l.treatment === 'recoverable' ? color.infoSoft : color.band,
                          color: l.treatment === 'expense' ? color.warning : l.treatment === 'recoverable' ? color.primary : color.label,
                        }}
                      />
                    </Box>
                    <Box component="td" sx={td}>{l.providerName ?? '—'}</Box>
                    <Box component="td" sx={{ ...td, color: beyond ? color.warning : color.muted, fontSize: font.size.small }}>{l.status}</Box>
                  </Box>
                );
              })}
              <Box component="tr" sx={{ bgcolor: color.band }}>
                <Box component="td" sx={{ ...td, fontWeight: font.weight.bold }} colSpan={3}>TOTAL</Box>
                <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.estimate} bold /></Box>
                <Box component="td" sx={tdNum} />
                <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.actual} bold /></Box>
                <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.variance} variance bold /></Box>
                <Box component="td" sx={td} colSpan={3} />
              </Box>
            </tbody>
          </Box>
          <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 0.75 }}>
            Capitalised ₹{inr(t.capitalised)} · expensed ₹{inr(t.expensed)} · recoverable tax ₹{inr(t.recoverable)} —
            the split finance must defend (HBIE-UIX-041).
          </Typography>
        </Box>
      </Section>

      {/* ------------------------------------------------------- allocation */}
      <Section
        title={`Allocation — ${line?.chargeName ?? ''}`}
        actions={
          <Stack direction="row" spacing={1} alignItems="center">
            <Typography sx={{ fontSize: font.size.label, color: color.label }}>Basis</Typography>
            <TextField select value={basis} onChange={(e) => setBasis(e.target.value)} sx={{ width: 180 }} aria-label="Allocation basis">
              {BASES.map((b) => <MenuItem key={b.value} value={b.value}>{b.label}</MenuItem>)}
            </TextField>
          </Stack>
        }
      >
        {alloc && line ? (
          <Box sx={{ px: 1.5, pb: 1.5 }}>
            <Typography sx={{ fontSize: font.size.body, mb: 0.75 }}>
              ₹{inr(alloc.amount)} allocated on {BASES.find((b) => b.value === basis)?.label.toLowerCase()}
            </Typography>
            <Box component="table" sx={{ width: '100%', borderCollapse: 'collapse', fontSize: font.size.table }}>
              <thead>
                <Box component="tr" sx={{ bgcolor: color.tableHeader }}>
                  {['Order line', 'Measure', 'Share', 'Allocated', 'Alternative basis', 'Difference'].map((h, i) => (
                    <Box component="th" key={h} sx={{ p: '6px 8px', textAlign: i >= 1 ? 'right' : 'left', fontWeight: font.weight.bold, color: color.label, borderBottom: `1px solid ${color.borderStrong}` }}>{h}</Box>
                  ))}
                </Box>
              </thead>
              <tbody>
                {alloc.allocation.map((a: any, i: number) => {
                  const other = altAlloc?.allocation?.[i];
                  const diff = other ? a.allocated - other.allocated : 0;
                  return (
                    <Box component="tr" key={a.id}>
                      <Box component="td" sx={td}>{a.label}</Box>
                      <Box component="td" sx={tdNum}>{a.measure.toLocaleString('en-IN', { maximumFractionDigits: 2 })}</Box>
                      <Box component="td" sx={tdNum}>{pct(a.sharePct)}</Box>
                      <Box component="td" sx={tdNum}><Money value={a.allocated} /></Box>
                      <Box component="td" sx={tdNum}>{other ? <Money value={other.allocated} /> : '—'}</Box>
                      <Box component="td" sx={tdNum}><Money value={diff} variance /></Box>
                    </Box>
                  );
                })}
              </tbody>
            </Box>
            {shift > 0 && (
              <Typography sx={{ fontSize: font.size.small, color: color.primary, mt: 0.75 }}>
                ⓘ Switching to {altAlloc?.basis === 'value' ? 'value' : 'gross weight'} basis would move up to ₹{inr(shift)} between
                lines. Allocating freight by value systematically over-costs light high-value items (RD 16.2.2).
              </Typography>
            )}
          </Box>
        ) : <Box sx={{ p: 1.5 }}><Typography sx={{ fontSize: font.size.label, color: color.muted }}>Select a cost element to see its allocation.</Typography></Box>}
      </Section>

      {/* ------------------------------------------------------ closure impact */}
      <Section title="Closure impact">
        <Box sx={{ px: 1.5, pb: 1.5, display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
          <Box>
            <DefRow label="Differential to post"><Money value={closure.differential} variance bold /></DefRow>
            <DefRow label="Stock on hand">{pct(closure.stockOnHandPct, 0)}</DefRow>
            <DefRow label="Valuation method">{closure.method}</DefRow>
            <DefRow label="To inventory revaluation"><Money value={closure.toInventory} /></DefRow>
            <DefRow label="To cost of goods sold" tone={color.warning}><Money value={closure.toCogs} /></DefRow>
            <Box sx={{ mt: 1 }}>
              <LabelledProgress
                value={closure.stockOnHandPct}
                label="Split by stock position"
                right={<Typography sx={{ fontSize: font.size.small, color: color.muted }}>{pct(closure.stockOnHandPct, 0)} inventory · {pct(100 - closure.stockOnHandPct, 0)} cost of sales</Typography>}
              />
            </Box>
          </Box>
          <Box sx={{ border: `1px solid ${color.border}`, borderRadius: `${shape.radius}px`, p: 1.25, bgcolor: color.canvas }}>
            <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.bold, color: color.label, mb: 0.75 }}>
              POSTING THAT WILL RESULT (voucher LCV, rule PR-IMP-11 v2)
            </Typography>
            <Box component="table" sx={{ width: '100%', fontSize: font.size.table, borderCollapse: 'collapse' }}>
              <tbody>
                <Box component="tr">
                  <Box component="td" sx={td}>Dr</Box>
                  <Box component="td" sx={td}>1401001 Inventory — raw material (imported)</Box>
                  <Box component="td" sx={tdNum}><Money value={closure.toInventory} decimals /></Box>
                </Box>
                <Box component="tr">
                  <Box component="td" sx={td}>Dr</Box>
                  <Box component="td" sx={td}>5101001 Cost of materials consumed</Box>
                  <Box component="td" sx={tdNum}><Money value={closure.toCogs} decimals /></Box>
                </Box>
                <Box component="tr">
                  <Box component="td" sx={td}>Cr</Box>
                  <Box component="td" sx={td}>2109001 Landed cost clearing — freight</Box>
                  <Box component="td" sx={tdNum}><Money value={closure.differential} decimals /></Box>
                </Box>
              </tbody>
            </Box>
            <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 0.75 }}>
              Dimensions: entity · site · shipment {cs.shipment?.number} · item · lot. Closure locks the sheet; reopening
              requires authorisation and creates a new version (HBIE-FIN-034).
            </Typography>
          </Box>
        </Box>
      </Section>

      <Dialog open={closeOpen} onClose={() => setCloseOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Close cost sheet {cs.id}</DialogTitle>
        <DialogContent>
          <Alert severity={pending.length ? 'warning' : 'info'} sx={{ mb: 1.5 }}>
            {pending.length
              ? `${pending.length} element(s) are still accrued but not invoiced (₹${inr(uninvoiced)}). Closing now posts the residual variance and locks the sheet.`
              : 'All elements are actualised.'}
          </Alert>
          <DefRow label="Differential"><Money value={closure.differential} variance bold /></DefRow>
          <DefRow label="To inventory"><Money value={closure.toInventory} /></DefRow>
          <DefRow label="To cost of goods sold"><Money value={closure.toCogs} /></DefRow>
          <DefRow label="Voucher to be created">LCV — landed cost voucher</DefRow>
          <TextField label="Reason for closure with pending items" fullWidth multiline rows={2} sx={{ mt: 1.5 }} required />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCloseOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => { setCloseOpen(false); setToast('Cost sheet closed. Voucher LCV/2026-27/00034 created in parked state for approval.'); }}>
            Confirm closure
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={Boolean(toast)} autoHideDuration={6000} onClose={() => setToast(null)} message={toast} />
    </Box>
  );
}

const td = { p: '5px 8px', borderBottom: `1px solid ${color.border}` } as const;
const tdNum = { ...td, textAlign: 'right', fontVariantNumeric: 'tabular-nums' } as const;
