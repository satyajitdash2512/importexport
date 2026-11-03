import * as React from 'react';
import { Box, Stack, Typography, Card, CardHeader, CardContent, Button, Chip } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip as RTooltip, CartesianGrid, LineChart, Line } from 'recharts';
import { color, font, shape } from '../../../context/tokens';
import { useApi } from '../../../lib/api';
import { inr, pct } from '../../../utils/format';
import { Band, PageHeader, Section, SeverityChip, Loading, ErrorState, LabelledProgress, DefRow, Money } from '../../../components/primitives';

interface Cockpit {
  needsAction: { key: string; label: string; count: number; exposure?: number; ageDays?: number; ref?: string; severity: 'critical' | 'high'; route: string }[];
  importPipeline: { stage: string; count: number; value: number; currency: string; exceptions?: number }[];
  exportPipeline: { stage: string; count: number; value: number; currency: string; exceptions?: number }[];
  compliance: { openExceptions: number; critical: number; high: number; obligationCoverPct: number; filingsDue7Days: number; overridesThisMonth: number; overridesTrend: number };
  accounting: { manualJournals: number; manualJournalTrend: number; parkedVouchers: number; clearingAged: number; subledgerDifferences: number; closeProgressPct: number; lockPermitted: boolean; evidenceCompletePct: number };
  entitlements: { eligible: number; claimed: number; received: number; gap: number };
  fx: { currency: string; netExposure: number; hedgedPct: number; position: string }[];
  costTrend: { month: string; landedPct: number; demurrage: number }[];
  openCostSheets: number; uninvoicedAccrual: number;
}

export default function CockpitScreen() {
  const nav = useNavigate();
  const { data, isLoading, error, refetch } = useApi<Cockpit>(['cockpit'], '/cockpit');

  if (isLoading) return <Loading label="Loading cockpit" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!data) return null;

  const crit = data.needsAction.filter((n) => n.severity === 'critical');
  const high = data.needsAction.filter((n) => n.severity === 'high');

  return (
    <Box>
      <PageHeader
        title="Trade cockpit"
        subtitle="Everything needing action today, ranked by consequence. Every figure drills to its records."
        actions={<Button onClick={() => refetch()}>Refresh</Button>}
        meta={<Chip label="as at 04-Aug-2026 09:00" sx={{ bgcolor: color.band, color: color.label }} />}
      />

      {/* ----------------------------------------------- needs action today */}
      <Section title="⚠ Needs action today" noBand={false}
        actions={<Button onClick={() => nav('/compliance/monitor')}>View all exceptions</Button>}>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' }, gap: 1, px: 1.5, pb: 1.5 }}>
          {[...crit, ...high].map((n) => (
            <Box
              key={n.key}
              component="button"
              onClick={() => nav(n.route)}
              sx={{
                textAlign: 'left', border: `1px solid ${n.severity === 'critical' ? color.danger : color.warning}55`,
                borderLeft: `3px solid ${n.severity === 'critical' ? color.danger : color.warning}`,
                borderRadius: `${shape.radius}px`, bgcolor: n.severity === 'critical' ? color.dangerSoft : color.warningSoft,
                p: 1, cursor: 'pointer', font: 'inherit',
                '&:hover': { filter: 'brightness(0.98)' },
              }}
            >
              <Stack direction="row" spacing={0.75} alignItems="center">
                <SeverityChip severity={n.severity} showLabel={false} />
                <Typography sx={{ fontSize: 20, fontWeight: font.weight.bold, color: n.severity === 'critical' ? color.danger : color.warning, lineHeight: 1 }}>
                  {n.count}
                </Typography>
              </Stack>
              <Typography sx={{ fontSize: font.size.label, color: color.text, mt: 0.5 }}>{n.label}</Typography>
              {n.exposure !== undefined && (
                <Typography sx={{ fontSize: font.size.small, color: color.label, fontWeight: font.weight.semibold, mt: 0.25 }}>
                  exposure ₹{inr(n.exposure)}
                </Typography>
              )}
              {n.ageDays !== undefined && <Typography sx={{ fontSize: font.size.small, color: color.muted }}>oldest {n.ageDays} days</Typography>}
              {n.ref && <Typography sx={{ fontSize: font.size.small, color: color.muted }}>{n.ref}</Typography>}
            </Box>
          ))}
        </Box>
      </Section>

      {/* --------------------------------------------------------- pipelines */}
      <Band />
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 0, bgcolor: color.surface }}>
        <PipelineCard title="Pipeline — Import" rows={data.importPipeline} onClick={() => nav('/import/shipments')} />
        <Box sx={{ borderLeft: { md: `1px solid ${color.border}` } }}>
          <PipelineCard title="Pipeline — Export" rows={data.exportPipeline} onClick={() => nav('/export/shipments')} />
        </Box>
      </Box>

      {/* ------------------------------------------- compliance + accounting */}
      <Band />
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '1fr 1fr 1fr' }, gap: 1, p: 1.5, bgcolor: color.surface }}>
        <Card>
          <CardHeader title="Compliance posture" action={<Button onClick={() => nav('/compliance/monitor')}>Open monitor</Button>} />
          <CardContent>
            <DefRow label="Open exceptions">
              <Stack direction="row" spacing={0.75} alignItems="center">
                <strong>{data.compliance.openExceptions}</strong>
                <SeverityChip severity="critical" showLabel={false} /><span>{data.compliance.critical}</span>
                <SeverityChip severity="high" showLabel={false} /><span>{data.compliance.high}</span>
              </Stack>
            </DefRow>
            <DefRow label="Obligation cover">{pct(data.compliance.obligationCoverPct, 0)}</DefRow>
            <DefRow label="Filings due in 7 days">{data.compliance.filingsDue7Days}</DefRow>
            <DefRow label="Overrides this month" tone={color.warning}>
              {data.compliance.overridesThisMonth} ({data.compliance.overridesTrend > 0 ? '↑' : '↓'}{Math.abs(data.compliance.overridesTrend)} on last month)
            </DefRow>
            <Box sx={{ mt: 1 }}>
              <LabelledProgress value={data.compliance.obligationCoverPct} label="Export obligation cover" tone="warning"
                right={<Typography sx={{ fontSize: font.size.small, color: color.muted }}>{pct(data.compliance.obligationCoverPct, 0)}</Typography>} />
            </Box>
          </CardContent>
        </Card>

        <Card>
          <CardHeader title="Accounting integrity" action={<Button onClick={() => nav('/close/checklist')}>Open close</Button>} />
          <CardContent>
            <DefRow label="Manual journals (month)">
              {data.accounting.manualJournals} ({data.accounting.manualJournalTrend < 0 ? '↓' : '↑'}{Math.abs(data.accounting.manualJournalTrend)})
            </DefRow>
            <DefRow label="Parked at cut-off" tone={data.accounting.parkedVouchers ? color.warning : undefined}>
              {data.accounting.parkedVouchers}
            </DefRow>
            <DefRow label="Clearing beyond policy age" tone={color.danger}>₹{inr(data.accounting.clearingAged)}</DefRow>
            <DefRow label="Subledger differences" tone={data.accounting.subledgerDifferences ? color.danger : color.success}>
              {data.accounting.subledgerDifferences === 0 ? 'None' : data.accounting.subledgerDifferences}
            </DefRow>
            <DefRow label="Evidence completeness">{pct(data.accounting.evidenceCompletePct, 0)}</DefRow>
            <Box sx={{ mt: 1 }}>
              <LabelledProgress
                value={data.accounting.closeProgressPct}
                label="July close progress"
                tone={data.accounting.lockPermitted ? 'success' : 'warning'}
                right={
                  <Typography sx={{ fontSize: font.size.small, color: data.accounting.lockPermitted ? color.success : color.warning, fontWeight: font.weight.semibold }}>
                    {data.accounting.lockPermitted ? 'Lock permitted' : 'Lock blocked'}
                  </Typography>
                }
              />
            </Box>
          </CardContent>
        </Card>

        <Card>
          <CardHeader title="Entitlements and exposure" action={<Button onClick={() => nav('/export/entitlements')}>Open claims</Button>} />
          <CardContent>
            <DefRow label="Eligible">₹{inr(data.entitlements.eligible)}</DefRow>
            <DefRow label="Claimed">₹{inr(data.entitlements.claimed)}</DefRow>
            <DefRow label="Received">₹{inr(data.entitlements.received)}</DefRow>
            <DefRow label="Gap" tone={data.entitlements.gap > 0 ? color.danger : color.success}>
              <Money value={data.entitlements.gap} variance />
            </DefRow>
            {data.fx.map((f) => (
              <DefRow key={f.currency} label={`${f.currency} exposure`}>
                {f.currency} {inr(f.netExposure)} net {f.position} · hedged {pct(f.hedgedPct, 0)}
              </DefRow>
            ))}
          </CardContent>
        </Card>
      </Box>

      {/* ------------------------------------------------------------ charts */}
      <Band />
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 1, p: 1.5, bgcolor: color.surface }}>
        <Card>
          <CardHeader title="Landed cost as a share of goods value" subheader="Percentage, last six months" />
          <CardContent sx={{ height: 200 }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={data.costTrend} margin={{ top: 6, right: 10, bottom: 0, left: -18 }}>
                <CartesianGrid stroke={color.border} vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: color.muted }} stroke={color.border} />
                <YAxis tick={{ fontSize: 11, fill: color.muted }} stroke={color.border} domain={[9, 13]} />
                <RTooltip contentStyle={{ fontSize: 12, borderRadius: shape.radius, border: `1px solid ${color.border}` }} formatter={(v: any) => `${v}%`} />
                <Line type="monotone" dataKey="landedPct" stroke={color.primary} strokeWidth={2} dot={{ r: 3, fill: color.primary }} name="Landed cost %" />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
        <Card>
          <CardHeader title="Demurrage and detention" subheader="Rupees per month — avoidable cost" />
          <CardContent sx={{ height: 200 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.costTrend} margin={{ top: 6, right: 10, bottom: 0, left: -6 }}>
                <CartesianGrid stroke={color.border} vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: color.muted }} stroke={color.border} />
                <YAxis tick={{ fontSize: 11, fill: color.muted }} stroke={color.border} tickFormatter={(v) => `${v / 1000}k`} />
                <RTooltip contentStyle={{ fontSize: 12, borderRadius: shape.radius, border: `1px solid ${color.border}` }} formatter={(v: any) => `₹${inr(Number(v))}`} />
                <Bar dataKey="demurrage" fill={color.primaryTile} name="Demurrage" radius={[2, 2, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </Box>
    </Box>
  );
}

function PipelineCard({ title, rows, onClick }: { title: string; rows: Cockpit['importPipeline']; onClick: () => void }) {
  return (
    <Box sx={{ p: 1.5 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 0.75 }}>
        <Typography variant="h2">{title}</Typography>
        <Button onClick={onClick}>Open list</Button>
      </Stack>
      <Box>
        {rows.map((r) => (
          <Stack key={r.stage} direction="row" alignItems="center" spacing={1} sx={{ py: 0.5, borderBottom: `1px solid ${color.border}` }}>
            <Typography sx={{ fontSize: font.size.body, flex: 1 }}>{r.stage}</Typography>
            <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold, minWidth: 28, textAlign: 'right' }}>{r.count}</Typography>
            <Typography sx={{ fontSize: font.size.body, minWidth: 120, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>
              {r.currency} {inr(r.value)}
            </Typography>
            <Box sx={{ minWidth: 42, textAlign: 'right' }}>
              {r.exceptions ? (
                <Typography component="span" sx={{ fontSize: font.size.small, fontWeight: font.weight.bold, color: color.danger, bgcolor: color.dangerSoft, px: 0.5, borderRadius: '3px' }}>
                  ▲ {r.exceptions}
                </Typography>
              ) : null}
            </Box>
          </Stack>
        ))}
      </Box>
    </Box>
  );
}
