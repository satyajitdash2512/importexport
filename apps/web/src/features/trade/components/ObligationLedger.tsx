import * as React from 'react';
import { Box, Stack, Typography, Button, Chip, Alert, AlertTitle, Divider, Tooltip } from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import { useNavigate, useParams } from 'react-router-dom';
import { color, font, shape } from '../../../context/tokens';
import { useApi } from '../../../lib/api';
import { inr, date, pct, relativeDeadline } from '../../../utils/format';
import {
  Band, PageHeader, Section, KpiStrip, StatusChip, Loading, ErrorState, Money, DefRow, LabelledProgress, PillTabs,
} from '../../../components/primitives';
import { DataTable, type GridColDef } from '../../../components/DataTable';

export default function ObligationLedger() {
  const { id } = useParams();
  const nav = useNavigate();
  const [tab, setTab] = React.useState('progress');
  const { data: l, isLoading, error, refetch } = useApi<any>(['licence', id], `/licences/${id}`);

  if (isLoading) return <Loading label="Loading authorisation" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!l) return null;

  const p = l.projection;
  const entitlementUsed = l.utilisation.reduce((s: number, u: any) => s + u.value, 0);

  return (
    <Box>
      <PageHeader
        onBack
        title={l.number}
        subtitle={`${l.scheme} · issued ${date(l.issuedOn)} · duty saved ₹${inr(l.dutySaved)} · obligation ₹${inr(l.obligationAmount)} (${l.obligationType})`}
        meta={<StatusChip status={l.status} />}
        actions={
          <>
            <Button>Extend period</Button>
            <Button>Compute shortfall</Button>
            <Button>Add export</Button>
            <Button variant="contained">Apply redemption</Button>
          </>
        }
      />

      <KpiStrip
        tiles={[
          { label: 'Duty saved', value: `₹ ${inr(l.dutySaved)}` },
          { label: 'Total obligation', value: `₹ ${inr(l.obligationAmount)}` },
          { label: 'Fulfilled', value: `₹ ${inr(p.fulfilled)}`, sub: pct(p.pct, 0) },
          { label: 'Remaining', value: `₹ ${inr(p.remaining)}` },
          { label: 'Headroom to deadline', value: p.headroomDays >= 0 ? `${p.headroomDays} days` : `${Math.abs(p.headroomDays)} days short`, tone: p.atRisk ? 'danger' : 'success' },
          { label: 'Exposure if unmet', value: `₹ ${inr(p.exposureDuty + p.exposureInterest)}`, tone: p.atRisk ? 'danger' : 'default' },
        ]}
      />

      <PillTabs
        value={tab} onChange={setTab}
        tabs={[
          { value: 'progress', label: 'Obligation progress' },
          { value: 'utilisation', label: 'Utilisation (imports)', badge: l.utilisation.length },
          { value: 'fulfilment', label: 'Fulfilment (exports)', badge: l.fulfilment.length },
          { value: 'conditions', label: 'Conditions', badge: l.conditions.filter((c: any) => !c.satisfied).length, warn: l.conditions.some((c: any) => !c.satisfied) },
          { value: 'security', label: 'Security & redemption' },
        ]}
      />
      <Band />

      {tab === 'progress' && (
        <>
          <Section title="Obligation progress" noBand>
            <Box sx={{ px: 1.5, pb: 1.5 }}>
              <Box sx={{ mb: 1.5 }}>
                <LabelledProgress
                  value={p.pct}
                  label="Total obligation"
                  tone={p.atRisk ? 'warning' : 'success'}
                  right={
                    <Typography sx={{ fontSize: font.size.label, fontVariantNumeric: 'tabular-nums' }}>
                      ₹{inr(p.fulfilled)} of ₹{inr(p.totalObligation)} · <strong>{pct(p.pct, 0)}</strong>
                    </Typography>
                  }
                />
              </Box>
              {l.blocks.map((b: any) => (
                <Box key={b.label} sx={{ mb: 1.25 }}>
                  <LabelledProgress
                    value={(b.fulfilled / b.sharePct) * 100}
                    label={b.label}
                    tone={b.fulfilled >= b.sharePct ? 'success' : new Date(b.dueOn) < new Date('2027-01-01') ? 'warning' : 'primary'}
                    right={
                      <Typography sx={{ fontSize: font.size.label }}>
                        {pct((b.fulfilled / b.sharePct) * 100, 0)} of block · due {date(b.dueOn)} ({relativeDeadline(b.dueOn)})
                      </Typography>
                    }
                  />
                </Box>
              ))}
              {l.averageObligation && (
                <DefRow label="Average export obligation">
                  ₹{inr(l.averageObligation)} per year —{' '}
                  {l.averageMaintained
                    ? <Typography component="span" sx={{ color: color.success, fontWeight: font.weight.semibold }}>maintained</Typography>
                    : <Typography component="span" sx={{ color: color.danger, fontWeight: font.weight.semibold }}>not maintained</Typography>}
                </DefRow>
              )}
              {l.minValueAddition && (
                <DefRow label="Minimum value addition">
                  {pct(l.minValueAddition, 0)} required —{' '}
                  {l.conditions.find((c: any) => c.name.includes('value addition'))?.satisfied
                    ? <Typography component="span" sx={{ color: color.success }}>achieved</Typography>
                    : <Typography component="span" sx={{ color: color.danger, fontWeight: font.weight.semibold }}>
                        {l.conditions.find((c: any) => c.name.includes('value addition'))?.detail}
                      </Typography>}
                </DefRow>
              )}
            </Box>
          </Section>

          <Section title="Projection">
            <Box sx={{ px: 1.5, pb: 1.5 }}>
              <Alert severity={p.atRisk ? 'error' : 'success'} sx={{ mb: 1.5 }}>
                <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>
                  {p.atRisk
                    ? `Projected shortfall — completion ${date(p.projectedCompletion)} against deadline ${date(p.deadline)}`
                    : `On track — projected completion ${date(p.projectedCompletion)}, ${p.headroomDays} days of headroom`}
                </AlertTitle>
                <Typography sx={{ fontSize: font.size.label }}>
                  At the current run rate of ₹{inr(p.runRatePerYear)} per year the remaining ₹{inr(p.remaining)} completes on{' '}
                  {date(p.projectedCompletion)}. {p.atRisk
                    ? `That is ${Math.abs(p.headroomDays)} days beyond the deadline. Seek a period extension or redirect exports to this authorisation now — the exposure if unmet is duty ₹${inr(p.exposureDuty)} plus interest ₹${inr(p.exposureInterest)}.`
                    : 'No action required, but the projection is monitored weekly.'}
                </Typography>
              </Alert>
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
                <Box>
                  <DefRow label="Run rate per year">₹{inr(p.runRatePerYear)}</DefRow>
                  <DefRow label="Projected completion">{date(p.projectedCompletion)}</DefRow>
                  <DefRow label="Next block deadline">{date(p.deadline)}</DefRow>
                  <DefRow label="Headroom" tone={p.headroomDays < 0 ? color.danger : color.success}>
                    {p.headroomDays >= 0 ? `${p.headroomDays} days` : `${Math.abs(p.headroomDays)} days short`}
                  </DefRow>
                </Box>
                <Box>
                  <DefRow label="Duty exposure" tone={color.danger}>₹{inr(p.exposureDuty)}</DefRow>
                  <DefRow label="Interest exposure" tone={color.danger}>₹{inr(p.exposureInterest)}</DefRow>
                  <DefRow label="Total contingent exposure" tone={color.danger}>
                    <strong>₹{inr(p.exposureDuty + p.exposureInterest)}</strong>
                  </DefRow>
                  <DefRow label="Carried in">Memorandum book — contingent duty (not a ledger liability)</DefRow>
                </Box>
              </Box>
            </Box>
          </Section>
        </>
      )}

      {tab === 'utilisation' && (
        <>
          <Box sx={{ bgcolor: color.surface, px: 1.5, pt: 1.5 }}>
            <Typography sx={{ fontSize: font.size.body }}>
              Entitlement used ₹{inr(entitlementUsed)} of duty saved ₹{inr(l.dutySaved)} —{' '}
              <strong>{entitlementUsed >= l.dutySaved ? 'fully utilised' : `balance ₹${inr(l.dutySaved - entitlementUsed)}`}</strong>
            </Typography>
          </Box>
          <DataTable
            rows={l.utilisation}
            exportName={`${l.number}-utilisation`}
            searchFields={['ref', 'description']}
            columns={[
              { field: 'date', headerName: 'Date', width: 110, renderCell: (p) => date(p.value) },
              { field: 'ref', headerName: 'Declaration', width: 130 },
              { field: 'description', headerName: 'Description', flex: 1, minWidth: 240 },
              { field: 'qty', headerName: 'Quantity', width: 110, align: 'right', headerAlign: 'right', renderCell: (p) => (p.value ? p.value.toLocaleString('en-IN') : '—') },
              { field: 'value', headerName: 'Duty foregone', width: 140, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value} /> },
            ] as GridColDef[]}
          />
        </>
      )}

      {tab === 'fulfilment' && (
        <>
          <Box sx={{ bgcolor: color.surface, px: 1.5, pt: 1.5 }}>
            <Alert severity={l.fulfilment.some((f: any) => !f.evidenceComplete) ? 'warning' : 'success'}>
              {l.fulfilment.filter((f: any) => !f.evidenceComplete).length} of {l.fulfilment.length} fulfilment entries lack
              complete realisation evidence. An export is credited to the obligation only on satisfaction of the scheme's
              evidence conditions (HBIE-CMP-020).
            </Alert>
          </Box>
          <DataTable
            rows={l.fulfilment}
            exportName={`${l.number}-fulfilment`}
            searchFields={['ref', 'description']}
            columns={[
              { field: 'date', headerName: 'Date', width: 110, renderCell: (p) => date(p.value) },
              { field: 'ref', headerName: 'Shipping bill', width: 130 },
              { field: 'description', headerName: 'Description', flex: 1, minWidth: 240 },
              { field: 'value', headerName: 'Value credited', width: 140, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value} /> },
              {
                field: 'evidenceComplete', headerName: 'Realisation evidence', width: 170,
                renderCell: (p) => p.value
                  ? <Stack direction="row" spacing={0.5} alignItems="center"><CheckCircleIcon sx={{ fontSize: 14, color: color.success }} /><span>Complete</span></Stack>
                  : <Stack direction="row" spacing={0.5} alignItems="center"><CancelIcon sx={{ fontSize: 14, color: color.warning }} /><span>Pending</span></Stack>,
              },
            ] as GridColDef[]}
            rowClassName={(r: any) => (r.evidenceComplete ? undefined : 'row-severity-medium')}
          />
        </>
      )}

      {tab === 'conditions' && (
        <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
          {l.conditions.map((c: any) => (
            <Stack key={c.name} direction="row" spacing={1.25} alignItems="flex-start" sx={{ py: 1, borderBottom: `1px solid ${color.border}` }}>
              {c.satisfied
                ? <CheckCircleIcon sx={{ fontSize: 16, color: color.success, mt: 0.2 }} />
                : <CancelIcon sx={{ fontSize: 16, color: color.danger, mt: 0.2 }} />}
              <Box sx={{ flex: 1 }}>
                <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold }}>{c.name}</Typography>
                <Typography sx={{ fontSize: font.size.label, color: c.satisfied ? color.muted : color.danger }}>{c.detail}</Typography>
              </Box>
              <Chip
                label={c.satisfied ? 'Satisfied' : 'Not satisfied'}
                sx={{ bgcolor: c.satisfied ? color.successSoft : color.dangerSoft, color: c.satisfied ? color.success : color.danger }}
              />
            </Stack>
          ))}
          <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 1 }}>
            Conditions are enforced as transaction rules, not merely recorded (HBIE-CMP-052).
          </Typography>
        </Box>
      )}

      {tab === 'security' && (
        <Box sx={{ bgcolor: color.surface, p: 1.5, display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
          <Box>
            <Typography variant="h2" sx={{ mb: 0.75 }}>Security furnished</Typography>
            <DefRow label="Bond reference">{l.bondRef ?? '—'}</DefRow>
            <DefRow label="Bond amount">₹{inr(l.dutySaved)}</DefRow>
            <DefRow label="Bank guarantee">{l.bgWaived ? 'Waived — status holder' : 'Furnished'}</DefRow>
            <DefRow label="Release">On redemption</DefRow>
          </Box>
          <Box>
            <Typography variant="h2" sx={{ mb: 0.75 }}>Redemption</Typography>
            <DefRow label="Status">Not applied</DefRow>
            <DefRow label="Evidence pack">
              {l.fulfilment.filter((f: any) => f.evidenceComplete).length} of {l.fulfilment.length} entries evidenced
            </DefRow>
            <DefRow label="Import validity">{date(l.importValidTo)} ({relativeDeadline(l.importValidTo)})</DefRow>
            <DefRow label="Export validity">{date(l.exportValidTo)} ({relativeDeadline(l.exportValidTo)})</DefRow>
            <Button variant="contained" sx={{ mt: 1 }}>Assemble redemption pack</Button>
          </Box>
        </Box>
      )}
    </Box>
  );
}
