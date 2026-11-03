import * as React from 'react';
import {
  Box, Stack, Typography, Button, Chip, Alert, AlertTitle, TextField, MenuItem, Divider, Tooltip,
  Dialog, DialogTitle, DialogContent, DialogActions, Snackbar, ToggleButtonGroup, ToggleButton,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import PendingIcon from '@mui/icons-material/Pending';
import RadioButtonUncheckedIcon from '@mui/icons-material/RadioButtonUnchecked';
import LockIcon from '@mui/icons-material/Lock';
import { useNavigate, useParams } from 'react-router-dom';
import { color, font, shape } from '../../../context/tokens';
import { useApi } from '../../../lib/api';
import { openPrint, downloadBlob } from '../../../lib/crud';
import { inr, date, pct } from '../../../utils/format';
import {
  Band, PageHeader, Section, KpiStrip, StatusChip, SeverityChip, Loading, ErrorState, Money,
  DefRow, LabelledProgress, EmptyState, PillTabs,
} from '../../../components/primitives';
import { DataTable, type GridColDef } from '../../../components/DataTable';

const td = { p: '5px 8px', borderBottom: `1px solid ${color.border}` } as const;
const tdNum = { ...td, textAlign: 'right', fontVariantNumeric: 'tabular-nums' } as const;

/* ========================================================================== */
/*  TRIAL BALANCE                                                             */
/* ========================================================================== */
export function TrialBalance() {
  const nav = useNavigate();
  const { data, isLoading, error, refetch } = useApi<any>(['trialBalance'], '/trial-balance');
  const [group, setGroup] = React.useState('all');
  const [toast, setToast] = React.useState<string | null>(null);

  if (isLoading) return <Loading label="Loading trial balance" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!data) return null;

  const groups = ['all', ...Array.from(new Set(data.rows.map((r: any) => r.group)))] as string[];
  const rows = group === 'all' ? data.rows : data.rows.filter((r: any) => r.group === group);
  const t = data.totals;

  return (
    <Box>
      <PageHeader
        title="Trial balance"
        subtitle={`Book: ${data.book} · period ${data.period} · every figure drills to documents and evidence`}
        meta={
          <Chip
            icon={data.balanced ? <CheckCircleIcon sx={{ fontSize: 13 }} /> : <ErrorIcon sx={{ fontSize: 13 }} />}
            label={data.balanced ? 'Balanced' : 'OUT OF BALANCE'}
            sx={{ bgcolor: data.balanced ? color.successSoft : color.dangerSoft, color: data.balanced ? color.success : color.danger, '& .MuiChip-icon': { color: 'inherit' } }}
          />
        }
        actions={
          <>
            <Button onClick={() => nav('/accounting/statements')}>Financial statements</Button>
            <Button onClick={() => openPrint('/print/trial-balance').catch((e) => setToast(e.message))}>Print</Button>
            <Button variant="contained" onClick={() => downloadBlob('/export/trial-balance.xlsx', 'trial-balance.xlsx').then(() => setToast('Trial balance exported.')).catch((e) => setToast(e.message))}>Export xlsx</Button>
          </>
        }
      />

      <KpiStrip
        tiles={[
          { label: 'Accounts with movement', value: data.rows.length },
          { label: 'Opening total', value: `₹ ${inr(t.openingDr)}` },
          { label: 'Period debits', value: `₹ ${inr(t.periodDr)}` },
          { label: 'Period credits', value: `₹ ${inr(t.periodCr)}` },
          { label: 'Closing total', value: `₹ ${inr(t.closingDr)}` },
          { label: 'Integrity check', value: data.balanced ? 'Passed' : 'FAILED', tone: data.balanced ? 'success' : 'danger' },
        ]}
      />

      <Band />
      <Box sx={{ bgcolor: color.surface, px: 1.5, py: 1 }}>
        <TextField select label="Account group" value={group} onChange={(e) => setGroup(e.target.value)} sx={{ width: 280 }}>
          {groups.map((g) => <MenuItem key={g} value={g}>{g === 'all' ? 'All groups' : g}</MenuItem>)}
        </TextField>
      </Box>

      <DataTable
        rows={rows.map((r: any) => ({ ...r, id: r.code }))}
        exportName="trial-balance"
        searchFields={['code', 'name', 'group']}
        searchPlaceholder="Search account code or name"
        onRowClick={(r: any) => nav(`/accounting/ledger?account=${r.code}`)}
        hiddenByDefault={['scheduleIIIGroup', 'reconFrequency']}
        columns={[
          { field: 'code', headerName: 'Code', width: 90 },
          { field: 'name', headerName: 'Account', flex: 1, minWidth: 260 },
          {
            field: 'type', headerName: 'Type', width: 100,
            renderCell: (p) => (
              <Chip
                label={p.value}
                sx={{
                  bgcolor: p.value === 'clearing' ? color.warningSoft : p.value === 'control' ? color.infoSoft : p.value === 'memorandum' ? color.band : 'transparent',
                  color: p.value === 'clearing' ? color.warning : p.value === 'control' ? color.primary : color.label,
                }}
              />
            ),
          },
          { field: 'group', headerName: 'Group', width: 170 },
          { field: 'scheduleIIIGroup', headerName: 'Schedule III presentation', width: 260 },
          {
            field: 'monetary', headerName: 'Monetary', width: 90,
            renderCell: (p) => (
              <Tooltip title={p.value ? 'Restated at closing rate (Ind AS 21)' : 'Not restated — non-monetary'}>
                <span>{p.value ? 'Yes' : 'No'}</span>
              </Tooltip>
            ),
          },
          { field: 'subledger', headerName: 'Subledger', width: 110, renderCell: (p) => p.value ?? '—' },
          { field: 'reconFrequency', headerName: 'Reconciled', width: 100, renderCell: (p) => p.value ?? '—' },
          { field: 'openingDr', headerName: 'Opening Dr', width: 120, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value || null} /> },
          { field: 'openingCr', headerName: 'Opening Cr', width: 120, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value || null} /> },
          { field: 'periodDr', headerName: 'Period Dr', width: 120, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value || null} /> },
          { field: 'periodCr', headerName: 'Period Cr', width: 120, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value || null} /> },
          { field: 'closingDr', headerName: 'Closing Dr', width: 125, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value || null} bold /> },
          { field: 'closingCr', headerName: 'Closing Cr', width: 125, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value || null} bold /> },
        ] as GridColDef[]}
        initialPageSize={50}
      />

      <Band />
      <Box sx={{ bgcolor: color.surface, px: 1.5, py: 1.25 }}>
        <Box component="table" sx={{ width: '100%', maxWidth: 900, borderCollapse: 'collapse', fontSize: font.size.table }}>
          <tbody>
            <Box component="tr" sx={{ bgcolor: color.band }}>
              <Box component="td" sx={{ ...td, fontWeight: font.weight.bold }}>TOTALS — all accounts</Box>
              <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.openingDr} bold /></Box>
              <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.openingCr} bold /></Box>
              <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.periodDr} bold /></Box>
              <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.periodCr} bold /></Box>
              <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.closingDr} bold /></Box>
              <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={t.closingCr} bold /></Box>
            </Box>
          </tbody>
        </Box>
        <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 0.75 }}>
          A scheduled integrity check confirms the trial balance sums to zero in every book and that every subledger equals its
          control account. Any failure raises a critical alert and is not self-correctable by an unattended process (HBIE-ACC-032, HBIE-ACC-033).
        </Typography>
      </Box>
      <Snackbar open={Boolean(toast)} autoHideDuration={5000} onClose={() => setToast(null)} message={toast} />
    </Box>
  );
}

/* ========================================================================== */
/*  CLOSE CHECKLIST                                                           */
/* ========================================================================== */
export function CloseChecklist() {
  const nav = useNavigate();
  const { data, isLoading, error, refetch } = useApi<any>(['closeTasks'], '/close-tasks');
  const [lockOpen, setLockOpen] = React.useState(false);
  const [toast, setToast] = React.useState<string | null>(null);

  if (isLoading) return <Loading label="Loading close checklist" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!data) return null;

  const { tasks, summary } = data;
  const days = Array.from(new Set(tasks.map((t: any) => t.day))) as string[];
  const blockers = tasks.filter((t: any) => t.mandatory && t.status !== 'complete');

  const icon = (s: string) =>
    s === 'complete' ? <CheckCircleIcon sx={{ fontSize: 16, color: color.success }} />
    : s === 'blocked' ? <ErrorIcon sx={{ fontSize: 16, color: color.danger }} />
    : s === 'inProgress' ? <PendingIcon sx={{ fontSize: 16, color: color.warning }} />
    : <RadioButtonUncheckedIcon sx={{ fontSize: 16, color: color.borderStrong }} />;

  return (
    <Box>
      <PageHeader
        title="Period close — July 2026"
        subtitle="Status is derived from the underlying data, never from user assertion (HBIE-CLS-001)"
        actions={
          <>
            <Button onClick={() => nav('/close/reconciliations')}>Reconciliations</Button>
            <Button onClick={() => refetch()}>Refresh status</Button>
            <Tooltip title={summary.lockPermitted ? 'Lock the period' : `${summary.mandatoryIncomplete} mandatory task(s) incomplete`}>
              <span>
                <Button variant="contained" startIcon={<LockIcon sx={{ fontSize: 15 }} />} onClick={() => setLockOpen(true)}>
                  Lock period
                </Button>
              </span>
            </Tooltip>
          </>
        }
      />

      <KpiStrip
        tiles={[
          { label: 'Tasks complete', value: `${summary.complete} / ${summary.total}` },
          { label: 'Blocked', value: summary.blocked, tone: summary.blocked ? 'danger' : 'success' },
          { label: 'In progress', value: summary.inProgress, tone: summary.inProgress ? 'warning' : 'default' },
          { label: 'Not started', value: summary.notStarted },
          { label: 'Mandatory incomplete', value: summary.mandatoryIncomplete, tone: summary.mandatoryIncomplete ? 'danger' : 'success' },
          { label: 'Period lock', value: summary.lockPermitted ? 'Permitted' : 'Blocked', tone: summary.lockPermitted ? 'success' : 'danger' },
        ]}
      />

      <Band />
      <Box sx={{ bgcolor: color.surface, px: 1.5, py: 1.25 }}>
        <LabelledProgress
          value={(summary.complete / summary.total) * 100}
          label="Close progress"
          tone={summary.lockPermitted ? 'success' : 'warning'}
          right={<Typography sx={{ fontSize: font.size.label }}>{pct((summary.complete / summary.total) * 100, 0)}</Typography>}
        />
      </Box>

      {blockers.length > 0 && (
        <>
          <Band />
          <Box sx={{ p: 1.5, bgcolor: color.surface }}>
            <Alert severity="error">
              <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>
                Period lock is blocked — {blockers.length} mandatory task{blockers.length > 1 ? 's' : ''} incomplete
              </AlertTitle>
              <Box component="ul" sx={{ m: 0, pl: 2.5 }}>
                {blockers.filter((b: any) => b.blockingCount > 0).map((b: any) => (
                  <Box component="li" key={b.id} sx={{ fontSize: font.size.label }}>
                    <strong>{b.step}</strong> — {b.blockingDetail}
                  </Box>
                ))}
              </Box>
              <Typography sx={{ fontSize: font.size.label, mt: 0.5 }}>
                Override requires the finance controller, records the reason and the incomplete tasks, and is reported to the
                audit committee pack (HBIE-CLS-004).
              </Typography>
            </Alert>
          </Box>
        </>
      )}

      {days.map((day) => (
        <Section key={day} title={`${day} — ${tasks.find((t: any) => t.day === day)?.area}`}>
          <Box sx={{ px: 1.5, pb: 1 }}>
            {tasks.filter((t: any) => t.day === day).map((t: any) => (
              <Stack
                key={t.id} direction="row" spacing={1.25} alignItems="flex-start"
                sx={{
                  py: 0.75, borderBottom: `1px solid ${color.border}`,
                  borderLeft: t.status === 'blocked' ? `3px solid ${color.danger}` : '3px solid transparent', pl: 1,
                }}
              >
                {icon(t.status)}
                <Box sx={{ flex: 1, minWidth: 0 }}>
                  <Stack direction="row" spacing={0.75} alignItems="center" flexWrap="wrap">
                    <Typography sx={{ fontSize: font.size.body, fontWeight: t.status === 'blocked' ? font.weight.semibold : font.weight.regular }}>
                      {t.step}
                    </Typography>
                    {t.mandatory && <Chip label="mandatory" sx={{ bgcolor: color.band, color: color.label }} />}
                    {t.blockingCount > 0 && (
                      <Chip label={`${t.blockingCount} blocking`} sx={{ bgcolor: color.dangerSoft, color: color.danger }} />
                    )}
                  </Stack>
                  {t.blockingDetail && (
                    <Typography sx={{ fontSize: font.size.label, color: color.danger, mt: 0.25 }}>{t.blockingDetail}</Typography>
                  )}
                  {t.evidence && (
                    <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 0.25 }}>Evidence: {t.evidence}</Typography>
                  )}
                </Box>
                <Typography sx={{ fontSize: font.size.label, color: color.label, minWidth: 150 }}>{t.owner}</Typography>
                <Box sx={{ minWidth: 130, textAlign: 'right' }}>
                  {t.signedOffBy
                    ? <Typography sx={{ fontSize: font.size.small, color: color.success }}>signed off · {t.signedOffBy}</Typography>
                    : <StatusChip status={t.status === 'inProgress' ? 'In progress' : t.status === 'notStarted' ? 'Not started' : t.status} />}
                </Box>
                {t.status === 'blocked' && <Button onClick={() => nav('/close/reconciliations')}>Resolve</Button>}
              </Stack>
            ))}
          </Box>
        </Section>
      ))}

      <Dialog open={lockOpen} onClose={() => setLockOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Lock period — July 2026</DialogTitle>
        <DialogContent>
          {summary.lockPermitted ? (
            <Alert severity="success">All mandatory close tasks are complete. The period may be locked.</Alert>
          ) : (
            <>
              <Alert severity="error" sx={{ mb: 1.5 }}>
                {summary.mandatoryIncomplete} mandatory task(s) are incomplete. Locking now is an override.
              </Alert>
              <Box component="ul" sx={{ m: 0, pl: 2.5, mb: 1.5 }}>
                {blockers.map((b: any) => <Box component="li" key={b.id} sx={{ fontSize: font.size.label }}>{b.step}</Box>)}
              </Box>
              <TextField label="Override reason (recorded and reported)" fullWidth multiline rows={2} required />
              <TextField label="Authorised by" fullWidth select sx={{ mt: 1.5 }} defaultValue="controller">
                <MenuItem value="controller">S. Menon — Finance controller</MenuItem>
              </TextField>
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLockOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => { setLockOpen(false); setToast(summary.lockPermitted ? 'Period locked.' : 'Override recorded in the override register and added to the audit committee pack. Period locked.'); }}>
            {summary.lockPermitted ? 'Lock period' : 'Override and lock'}
          </Button>
        </DialogActions>
      </Dialog>
      <Snackbar open={Boolean(toast)} autoHideDuration={7000} onClose={() => setToast(null)} message={toast} />
    </Box>
  );
}

/* ========================================================================== */
/*  RECONCILIATION LIST + DETAIL                                              */
/* ========================================================================== */
export function ReconciliationList() {
  const nav = useNavigate();
  const { data = [], isLoading, error, refetch } = useApi<any[]>(['reconciliations'], '/reconciliations');
  if (isLoading) return <Loading label="Loading reconciliations" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;

  const atRisk = data.reduce((s, r) => s + r.valueAtRisk, 0);
  const critical = data.filter((r) => r.status === 'critical').length;

  return (
    <Box>
      <PageHeader
        title="Reconciliations"
        subtitle="Nineteen reconciliations, each with two sources, a matching rule, an owner and a retained signed result (RD 18.2)"
        actions={<Button onClick={() => nav('/close/checklist')}>Close checklist</Button>}
      />
      <KpiStrip
        tiles={[
          { label: 'Reconciliations', value: data.length },
          { label: 'Clean', value: data.filter((r) => r.status === 'clean').length, tone: 'success' },
          { label: 'With exceptions', value: data.filter((r) => r.status === 'exceptions').length, tone: 'warning' },
          { label: 'Critical', value: critical, tone: critical ? 'danger' : 'default' },
          { label: 'Total value at risk', value: `₹ ${inr(atRisk)}`, tone: atRisk > 0 ? 'danger' : 'success' },
          { label: 'Oldest item', value: `${Math.max(...data.map((r) => r.oldestDays))} days` },
        ]}
      />
      <Band />
      <DataTable
        rows={data}
        exportName="reconciliations"
        searchFields={['name', 'owner']}
        onRowClick={(r: any) => nav(`/close/reconciliations/${r.id}`)}
        columns={[
          { field: 'name', headerName: 'Reconciliation', flex: 1, minWidth: 260 },
          { field: 'sourceA', headerName: 'Source A', width: 180 },
          { field: 'sourceB', headerName: 'Source B', width: 220 },
          { field: 'frequency', headerName: 'Frequency', width: 100 },
          { field: 'owner', headerName: 'Owner', width: 160 },
          { field: 'asOf', headerName: 'As at', width: 105, renderCell: (p) => date(p.value) },
          { field: 'matched', headerName: 'Matched', width: 90, align: 'right', headerAlign: 'right' },
          {
            field: 'unmatched', headerName: 'Unmatched', width: 100, align: 'right', headerAlign: 'right',
            valueGetter: (p: any) => p.row.unmatchedA + p.row.unmatchedB,
            renderCell: (p) => <Typography sx={{ fontSize: 'inherit', color: p.value ? color.danger : color.success, fontWeight: font.weight.semibold }}>{p.value}</Typography>,
          },
          { field: 'valueAtRisk', headerName: 'Value at risk', width: 130, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value || null} /> },
          { field: 'oldestDays', headerName: 'Oldest', width: 85, align: 'right', headerAlign: 'right', renderCell: (p) => (p.value ? `${p.value}d` : '—') },
          { field: 'status', headerName: 'Status', width: 120, renderCell: (p) => <StatusChip status={p.value} /> },
        ] as GridColDef[]}
        rowClassName={(r: any) => (r.status === 'critical' ? 'row-severity-critical' : r.status === 'exceptions' ? 'row-severity-high' : undefined)}
      />
    </Box>
  );
}

export function ReconciliationDetail() {
  const { id } = useParams();
  const nav = useNavigate();
  const { data: r, isLoading, error, refetch } = useApi<any>(['reconciliation', id], `/reconciliations/${id}`);
  const [toast, setToast] = React.useState<string | null>(null);

  if (isLoading) return <Loading label="Loading reconciliation" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!r) return null;

  const withLimitation = r.items.filter((i: any) => i.limitationDate);

  return (
    <Box>
      <PageHeader
        onBack
        title={r.name}
        subtitle={`${r.sourceA} against ${r.sourceB} · ${r.frequency} · owner ${r.owner} · as at ${date(r.asOf)}`}
        meta={<StatusChip status={r.status} />}
        actions={<><Button>Auto-match</Button><Button>Sign off</Button><Button variant="contained">Export workpaper</Button></>}
      />
      <KpiStrip
        tiles={[
          { label: 'Matched', value: r.matched, tone: 'success' },
          { label: `Unmatched in ${r.sourceA}`, value: r.unmatchedA, tone: r.unmatchedA ? 'warning' : 'default' },
          { label: `Unmatched in ${r.sourceB}`, value: r.unmatchedB, tone: r.unmatchedB ? 'warning' : 'default' },
          { label: 'Value at risk', value: `₹ ${inr(r.valueAtRisk)}`, tone: r.valueAtRisk ? 'danger' : 'success' },
          { label: 'Oldest item', value: r.oldestDays ? `${r.oldestDays} days` : '—' },
          { label: 'Limitation exposure', value: withLimitation.length, tone: withLimitation.length ? 'danger' : 'default' },
        ]}
      />

      {withLimitation.length > 0 && (
        <>
          <Band />
          <Box sx={{ p: 1.5, bgcolor: color.surface }}>
            <Alert severity="error">
              <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>
                {withLimitation.length} item{withLimitation.length > 1 ? 's' : ''} approaching a statutory limitation date
              </AlertTitle>
              <Typography sx={{ fontSize: font.size.label }}>
                Beyond the limitation date the credit or refund is forfeited. {withLimitation.map((i: any) => `${i.ref} (${date(i.limitationDate)})`).join('; ')}.
                The module alerts before the limit is reached (HBIE-CLS-012).
              </Typography>
            </Alert>
          </Box>
        </>
      )}

      <Band />
      {r.items.length === 0 ? (
        <EmptyState title="Fully reconciled" detail={`Every item in ${r.sourceA} agrees to ${r.sourceB} as at ${date(r.asOf)}. The signed result is retained as evidence.`} />
      ) : (
        <DataTable
          rows={r.items}
          exportName={`${r.id}-items`}
          searchFields={['ref', 'description', 'cause']}
          columns={[
            { field: 'ref', headerName: 'Reference', width: 190 },
            { field: 'date', headerName: 'Date', width: 105, renderCell: (p) => date(p.value) },
            { field: 'description', headerName: 'Description', flex: 1, minWidth: 260 },
            { field: 'amountA', headerName: 'Source A', width: 130, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value ?? null} /> },
            { field: 'amountB', headerName: 'Source B', width: 130, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value ?? null} /> },
            { field: 'difference', headerName: 'Difference', width: 130, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value} variance /> },
            { field: 'cause', headerName: 'Cause', width: 240 },
            { field: 'ageDays', headerName: 'Age', width: 75, align: 'right', headerAlign: 'right', renderCell: (p) => `${p.value}d` },
            { field: 'limitationDate', headerName: 'Limitation', width: 115, renderCell: (p) => (p.value ? <Typography sx={{ fontSize: 'inherit', color: color.danger }}>{date(p.value)}</Typography> : '—') },
            { field: 'status', headerName: 'Status', width: 130, renderCell: (p) => <StatusChip status={p.value} /> },
            {
              field: 'actions', headerName: 'Action', width: 120, sortable: false,
              renderCell: (p) => (
                <Button onClick={(e) => { e.stopPropagation(); setToast(`Manual match recorded on ${p.row.ref} with basis and approver (HBIE-CLS-011).`); }}>
                  Match
                </Button>
              ),
            },
          ] as GridColDef[]}
          rowClassName={(r2: any) => (r2.limitationDate ? 'row-severity-critical' : r2.ageDays > 30 ? 'row-severity-high' : undefined)}
        />
      )}
      <Snackbar open={Boolean(toast)} autoHideDuration={6000} onClose={() => setToast(null)} message={toast} />
    </Box>
  );
}

/* ========================================================================== */
/*  COMPLIANCE MONITOR                                                        */
/* ========================================================================== */
export function ComplianceMonitor() {
  const nav = useNavigate();
  const { data = [], isLoading, error, refetch } = useApi<any[]>(['exceptions'], '/exceptions');
  const [groupBy, setGroupBy] = React.useState<'severity' | 'type' | 'owner'>('severity');

  if (isLoading) return <Loading label="Loading exceptions" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;

  const exposure = data.reduce((s, e) => s + (e.exposure ?? 0), 0);
  const grouped = data.reduce((acc: Record<string, any[]>, e) => {
    const key = groupBy === 'severity' ? e.severity : groupBy === 'type' ? e.type : e.owner;
    (acc[key] ||= []).push(e);
    return acc;
  }, {});
  const order = groupBy === 'severity' ? ['critical', 'high', 'medium', 'info'] : Object.keys(grouped).sort();

  const routeFor = (e: any) =>
    e.objectType === 'declaration' ? `/import/declarations/${e.objectId}`
    : e.objectType === 'shipment' ? `/import/shipments/${e.objectId}`
    : e.objectType === 'costSheet' ? `/finance/landed-cost/${e.objectId}`
    : e.objectType === 'instrument' ? `/finance/instruments/${e.objectId}`
    : e.objectType === 'party' ? '/compliance/screening'
    : '/compliance/monitor';

  return (
    <Box>
      <PageHeader
        title="Compliance monitor"
        subtitle="Ranked by a composite of severity, financial exposure, deadline proximity and age — the item at the top is the one to do first"
        actions={
          <>
            <ToggleButtonGroup size="small" exclusive value={groupBy} onChange={(_, v) => v && setGroupBy(v)} aria-label="Group by">
              <ToggleButton value="severity">Severity</ToggleButton>
              <ToggleButton value="type">Type</ToggleButton>
              <ToggleButton value="owner">Owner</ToggleButton>
            </ToggleButtonGroup>
            <Button onClick={() => refetch()}>Refresh</Button>
          </>
        }
      />
      <KpiStrip
        tiles={[
          { label: 'Open exceptions', value: data.length },
          { label: 'Critical', value: data.filter((e) => e.severity === 'critical').length, tone: 'danger' },
          { label: 'High', value: data.filter((e) => e.severity === 'high').length, tone: 'warning' },
          { label: 'Total value at risk', value: `₹ ${inr(exposure)}`, tone: exposure ? 'danger' : 'success' },
          { label: 'Oldest', value: `${Math.max(...data.map((e) => e.ageDays))} days` },
          { label: 'Overrides this month', value: 6, tone: 'warning' },
        ]}
      />
      <Band />
      {order.filter((k) => grouped[k]?.length).map((key) => (
        <Section key={key} title={groupBy === 'severity' ? `${key.charAt(0).toUpperCase()}${key.slice(1)} (${grouped[key].length})` : `${key} (${grouped[key].length})`}>
          <Box sx={{ px: 1.5, pb: 1 }}>
            {grouped[key].map((e: any) => (
              <Box
                key={e.id}
                onClick={() => nav(routeFor(e))}
                sx={{
                  py: 1, px: 1, mb: 0.75, cursor: 'pointer', borderRadius: `${shape.radius}px`,
                  border: `1px solid ${color.border}`,
                  borderLeft: `3px solid ${e.severity === 'critical' ? color.danger : e.severity === 'high' ? color.warning : color.info}`,
                  '&:hover': { bgcolor: color.primarySoft },
                }}
              >
                <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap" sx={{ mb: 0.4 }}>
                  <SeverityChip severity={e.severity} />
                  <Chip label={e.type} sx={{ bgcolor: color.band, color: color.label }} />
                  <Typography sx={{ fontSize: font.size.small, color: color.muted }}>
                    {e.objectType} {e.objectId} · rule {e.ruleId} · {e.ageDays} days old
                  </Typography>
                  <Box sx={{ flex: 1 }} />
                  {e.exposure ? (
                    <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.bold, color: color.danger }}>
                      ₹{inr(e.exposure)} at risk
                    </Typography>
                  ) : null}
                </Stack>
                <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold }}>{e.title}</Typography>
                <Typography sx={{ fontSize: font.size.label, color: color.muted, mt: 0.25 }}>{e.detail}</Typography>
                <Typography sx={{ fontSize: font.size.small, color: color.label, mt: 0.4 }}>Owner: {e.owner}</Typography>
              </Box>
            ))}
          </Box>
        </Section>
      ))}
    </Box>
  );
}

/* ========================================================================== */
/*  BANK PRESENTATION DESK                                                    */
/* ========================================================================== */
export function BankPresentation() {
  const { id } = useParams();
  const { data: i, isLoading, error, refetch } = useApi<any>(['instrument', id], `/instruments/${id}`);
  const [toast, setToast] = React.useState<string | null>(null);

  if (isLoading) return <Loading label="Loading instrument" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!i) return null;

  const held = i.documentRequirements.filter((d: any) => d.held).length;
  const missing = i.documentRequirements.filter((d: any) => !d.held);
  const canPresent = missing.length === 0 && i.discrepancies.length === 0;

  return (
    <Box>
      <PageHeader
        onBack
        title={`${i.number} — bank presentation`}
        subtitle={`${i.type} · ${i.governingRules} · ${i.issuingBank} · ${i.currency} ${inr(i.value)} ±${i.tolerancePct}%`}
        meta={<StatusChip status={i.status} />}
        actions={
          <>
            <Button>Discrepancy check</Button>
            <Tooltip title={canPresent ? 'Generate the covering schedule and present' : 'Resolve missing documents and discrepancies first'}>
              <span><Button variant="contained" disabled={!canPresent} onClick={() => setToast('Presentation pack generated with covering schedule.')}>Present documents</Button></span>
            </Tooltip>
          </>
        }
      />
      <KpiStrip
        tiles={[
          { label: 'Instrument value', value: `${i.currency} ${inr(i.value)}` },
          { label: 'Drawn', value: `${i.currency} ${inr(i.drawnValue)}` },
          { label: 'Available', value: `${i.currency} ${inr(i.availableValue)}` },
          { label: 'Latest shipment date', value: date(i.latestShipmentDate) },
          { label: 'Presentation deadline', value: date(i.presentationDeadline ?? i.expiryDate), tone: 'danger' },
          { label: 'Documents held', value: `${held} / ${i.documentRequirements.length}`, tone: missing.length ? 'warning' : 'success' },
        ]}
      />

      {(missing.length > 0 || i.discrepancies.length > 0) && (
        <>
          <Band />
          <Box sx={{ p: 1.5, bgcolor: color.surface }}>
            <Alert severity="error">
              <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>
                Presentation cannot proceed — deadline {date(i.presentationDeadline ?? i.expiryDate)}
              </AlertTitle>
              {missing.length > 0 && (
                <Typography sx={{ fontSize: font.size.label }}>
                  Missing or unsatisfied: {missing.map((m: any) => m.doc).join('; ')}.
                </Typography>
              )}
              {i.discrepancies.map((d: any) => (
                <Typography key={d.id} sx={{ fontSize: font.size.label }}>
                  Discrepancy {d.code}: {d.description} → disposition: {d.disposition}
                </Typography>
              ))}
              <Typography sx={{ fontSize: font.size.label, mt: 0.5 }}>
                A document set inconsistent with the credit is not paid. Presentation must fall within the presentation period
                and before expiry (VR-011).
              </Typography>
            </Alert>
          </Box>
        </>
      )}

      <Band />
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '1fr 1fr' }, gap: 0 }}>
        <Box sx={{ bgcolor: color.surface, borderRight: { lg: `1px solid ${color.border}` } }}>
          <Section title="What the credit requires" noBand>
            <Box sx={{ px: 1.5, pb: 1.5 }}>
              {i.documentRequirements.map((d: any) => (
                <Stack key={d.doc} direction="row" spacing={1.25} alignItems="flex-start" sx={{ py: 0.75, borderBottom: `1px solid ${color.border}` }}>
                  {d.held ? <CheckCircleIcon sx={{ fontSize: 16, color: color.success, mt: 0.2 }} /> : <ErrorIcon sx={{ fontSize: 16, color: color.danger, mt: 0.2 }} />}
                  <Box sx={{ flex: 1 }}>
                    <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold }}>{d.doc}</Typography>
                    <Typography sx={{ fontSize: font.size.small, color: color.muted }}>
                      {d.originals} original{d.originals > 1 ? 's' : ''} + {d.copies} cop{d.copies > 1 ? 'ies' : 'y'} · issued by {d.issuer}
                    </Typography>
                    {d.wording && (
                      <Typography sx={{ fontSize: font.size.small, color: color.primary, mt: 0.25, fontStyle: 'italic' }}>
                        Required wording: “{d.wording}”
                      </Typography>
                    )}
                  </Box>
                  <StatusChip status={d.held ? 'Held' : 'Missing'} />
                </Stack>
              ))}
            </Box>
          </Section>
        </Box>
        <Box sx={{ bgcolor: color.surface }}>
          <Section title="Instrument terms" noBand>
            <Box sx={{ px: 1.5, pb: 1.5 }}>
              <DefRow label="Applicant">{i.applicant}</DefRow>
              <DefRow label="Beneficiary">{i.beneficiary}</DefRow>
              <DefRow label="Issuing bank">{i.issuingBank}</DefRow>
              <DefRow label="Advising bank">{i.advisingBank ?? '—'}</DefRow>
              <DefRow label="Payment terms">{i.paymentTerms}</DefRow>
              <DefRow label="Latest shipment">{date(i.latestShipmentDate)}</DefRow>
              <DefRow label="Expiry">{date(i.expiryDate)}</DefRow>
              <DefRow label="Presentation period">{i.presentationDays} days from shipment</DefRow>
              <DefRow label="Presentation deadline" tone={color.danger}>{date(i.presentationDeadline ?? i.expiryDate)}</DefRow>
              <DefRow label="Tolerance">±{i.tolerancePct}%</DefRow>
              <DefRow label="Charges to date">₹{inr(i.charges)}</DefRow>
              {i.shipment && <DefRow label="Linked shipment">{i.shipment.number} · on board {date(i.shipment.atd)}</DefRow>}
            </Box>
          </Section>
        </Box>
      </Box>
      <Snackbar open={Boolean(toast)} autoHideDuration={6000} onClose={() => setToast(null)} message={toast} />
    </Box>
  );
}

/* ========================================================================== */
/*  SCREENING REVIEW QUEUE                                                    */
/* ========================================================================== */
export function ScreeningReview() {
  const { data = [], isLoading, error, refetch } = useApi<any[]>(['parties'], '/parties');
  const [toast, setToast] = React.useState<string | null>(null);
  const [selected, setSelected] = React.useState<string | null>(null);

  if (isLoading) return <Loading label="Loading screening queue" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;

  const queue = data.filter((p) => p.screeningStatus !== 'clear');
  const party = queue.find((p) => p.id === selected) ?? queue[0];

  const listEntry = party?.screeningStatus === 'match'
    ? { name: 'ZHEJIANG FASTENER WORKS CO LTD', country: 'CN', list: 'Consolidated restricted-party list', score: 96, matchedTokens: ['ZHEJIANG', 'FASTENER', 'WORKS'], programme: 'Export control — entity list', added: '2026-07-30' }
    : { name: 'ORIENT TRADING FZE', country: 'AE', list: 'Consolidated restricted-party list', score: 87, matchedTokens: ['ORIENT', 'FZE'], programme: 'Sanctions — sectoral', added: '2026-08-03' };

  return (
    <Box>
      <PageHeader
        title="Screening review queue"
        subtitle="Potential matches from the list refresh. A confirmed match blocks transaction creation and release across all modules (VR-020)."
        actions={<Button onClick={() => refetch()}>Re-screen all</Button>}
      />
      <KpiStrip
        tiles={[
          { label: 'Parties screened', value: data.length },
          { label: 'Clear', value: data.filter((p) => p.screeningStatus === 'clear').length, tone: 'success' },
          { label: 'Under review', value: data.filter((p) => p.screeningStatus === 'review').length, tone: 'warning' },
          { label: 'Confirmed match', value: data.filter((p) => p.screeningStatus === 'match').length, tone: 'danger' },
          { label: 'Last list refresh', value: '03-Aug-2026' },
          { label: 'Blocked transactions', value: 2, tone: 'danger' },
        ]}
      />
      <Band />
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '320px 1fr' }, gap: 0 }}>
        <Box sx={{ bgcolor: color.surface, borderRight: { lg: `1px solid ${color.border}` } }}>
          <Typography variant="h2" sx={{ px: 1.5, pt: 1.25, pb: 0.5 }}>Queue ({queue.length})</Typography>
          {queue.map((p) => (
            <Box
              key={p.id}
              onClick={() => setSelected(p.id)}
              sx={{
                px: 1.5, py: 1, cursor: 'pointer', borderBottom: `1px solid ${color.border}`,
                bgcolor: party?.id === p.id ? color.primarySoft : undefined,
                borderLeft: `3px solid ${p.screeningStatus === 'match' ? color.danger : color.warning}`,
                '&:hover': { bgcolor: color.primarySoft },
              }}
            >
              <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold }}>{p.name}</Typography>
              <Typography sx={{ fontSize: font.size.small, color: color.muted }}>{p.country} · {p.roles.join(', ')} · screened {date(p.screenedOn)}</Typography>
              <Chip
                label={p.screeningStatus === 'match' ? 'Confirmed match' : 'Potential match'}
                sx={{ mt: 0.5, bgcolor: p.screeningStatus === 'match' ? color.dangerSoft : color.warningSoft, color: p.screeningStatus === 'match' ? color.danger : color.warning }}
              />
            </Box>
          ))}
        </Box>

        {party && (
          <Box sx={{ bgcolor: color.surface }}>
            <Section title="Side-by-side comparison" noBand>
              <Box sx={{ px: 1.5, pb: 1.5, display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
                <Box sx={{ border: `1px solid ${color.border}`, borderRadius: `${shape.radius}px`, p: 1.25 }}>
                  <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.bold, color: color.label, mb: 0.75 }}>ENTITY RECORD</Typography>
                  <DefRow label="Name">{party.legalName}</DefRow>
                  <DefRow label="Country">{party.country}</DefRow>
                  <DefRow label="Roles">{party.roles.join(', ')}</DefRow>
                  <DefRow label="Contact code">{party.contactCode}</DefRow>
                  <DefRow label="Ledger">{party.ledgerGroup ?? '—'} {party.ledgerCode ? `· ${party.ledgerCode}` : ''}</DefRow>
                  <DefRow label="Bank details verified" tone={party.bankVerified ? color.success : color.danger}>
                    {party.bankVerified ? 'Yes' : 'No — payment suspended'}
                  </DefRow>
                </Box>
                <Box sx={{ border: `1px solid ${color.danger}55`, bgcolor: color.dangerSoft, borderRadius: `${shape.radius}px`, p: 1.25 }}>
                  <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.bold, color: color.danger, mb: 0.75 }}>LIST ENTRY</Typography>
                  <DefRow label="Name">{listEntry.name}</DefRow>
                  <DefRow label="Country">{listEntry.country}</DefRow>
                  <DefRow label="List">{listEntry.list}</DefRow>
                  <DefRow label="Programme">{listEntry.programme}</DefRow>
                  <DefRow label="Added to list">{date(listEntry.added)}</DefRow>
                  <DefRow label="Match score" tone={color.danger}><strong>{listEntry.score}</strong> / 100</DefRow>
                </Box>
              </Box>
              <Box sx={{ px: 1.5, pb: 1.5 }}>
                <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.bold, color: color.label, mb: 0.5 }}>MATCHED TOKENS</Typography>
                <Stack direction="row" spacing={0.75} flexWrap="wrap">
                  {listEntry.matchedTokens.map((t) => (
                    <Chip key={t} label={t} sx={{ bgcolor: color.warningSoft, color: color.warning, fontFamily: font.mono }} />
                  ))}
                </Stack>
                <Alert severity="warning" sx={{ mt: 1.5 }}>
                  Every screening event, including negative results, is retained as evidence that screening was performed
                  (HBIE-CMP-075). A false-positive determination requires documented reasoning.
                </Alert>
                <Stack direction="row" spacing={1} sx={{ mt: 1.5 }}>
                  <Button onClick={() => setToast('Recorded as a false positive with reasoning. The party is released for transactions and the decision is logged.')}>
                    False positive — release
                  </Button>
                  <Button onClick={() => setToast('Escalated to the compliance officer for determination. Transactions remain blocked.')}>Escalate</Button>
                  <Button variant="contained" color="error" onClick={() => setToast('Confirmed as a match. Transaction creation and release blocked for this party across all modules.')}>
                    Confirm match — block
                  </Button>
                </Stack>
              </Box>
            </Section>
          </Box>
        )}
      </Box>
      <Snackbar open={Boolean(toast)} autoHideDuration={7000} onClose={() => setToast(null)} message={toast} />
    </Box>
  );
}
