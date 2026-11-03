import * as React from 'react';
import { Box, Stack, Typography, Button, Card, CardHeader, CardContent, Chip, Tooltip, Alert } from '@mui/material';
import CheckIcon from '@mui/icons-material/Check';
import { useNavigate, useParams } from 'react-router-dom';
import { color, font, shape } from '../../../context/tokens';
import { useApi } from '../../../lib/api';
import { inr, date, relativeDeadline, qty } from '../../../utils/format';
import {
  Band, PageHeader, PillTabs, FieldGrid, Section, KpiStrip, StatusChip, SeverityChip, DeadlineChip,
  Loading, ErrorState, Money, DefRow, EmptyState,
} from '../../../components/primitives';
import { DataTable, type GridColDef } from '../../../components/DataTable';

export default function Shipment360() {
  const { id } = useParams();
  const nav = useNavigate();
  const [tab, setTab] = React.useState('overview');
  const { data: s, isLoading, error, refetch } = useApi<any>(['shipment', id], `/shipments/${id}`);

  if (isLoading) return <Loading label="Loading shipment" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!s) return null;

  const cost = s.costSummary;
  const decl = s.declarations?.[0];
  const criticalExc = s.exceptions.filter((e: any) => e.severity === 'critical');
  const nextDeadline = s.containers.length
    ? new Date(new Date(s.containers[0].freeFrom).getTime() + s.containers[0].freeDays * 864e5).toISOString().slice(0, 10)
    : undefined;

  const tabs = [
    { value: 'overview', label: 'Overview' },
    { value: 'lines', label: 'Order lines', badge: s.orders?.[0]?.lines?.length ?? 0 },
    { value: 'containers', label: 'Containers', badge: s.containers.length },
    { value: 'milestones', label: 'Milestones', badge: s.milestones.length },
    { value: 'documents', label: 'Documents', badge: s.docsRequired - s.docsReceived, warn: s.docsReceived < s.docsRequired },
    { value: 'declaration', label: 'Declaration' },
    { value: 'cost', label: 'Cost sheet' },
    { value: 'exceptions', label: 'Exceptions', badge: s.exceptions.length, warn: criticalExc.length > 0 },
    { value: 'activity', label: 'Activity log' },
  ];

  return (
    <Box>
      <PageHeader
        onBack
        title={`${s.number}`}
        subtitle={
          <>
            {s.direction === 'import' ? 'IMPORT' : 'EXPORT'} · {s.mode} · {s.containers.length ? 'FCL' : 'LCL/AIR'} —{' '}
            {s.party?.name} · {s.incoterm} {s.portOfDischarge} · {s.currency} {inr(s.value)}
            {s.containers.length ? ` · ${s.containers.length}×${s.containers[0].type}` : ''}
          </>
        }
        meta={<StatusChip status={s.status} />}
        actions={
          <>
            <Button onClick={() => decl && nav(`/import/declarations/${decl.id}`)} disabled={!decl}>Open declaration</Button>
            <Button onClick={() => s.costSheet && nav(`/finance/landed-cost/${s.costSheet.id}`)} disabled={!s.costSheet}>Cost sheet</Button>
            <Button variant="contained">Upload document</Button>
          </>
        }
        newMenu={[{ label: 'Declaration' }, { label: 'Cost line' }, { label: 'Exception' }, { label: 'Document' }]}
      />

      <StageSpine milestones={s.milestones} />

      <KpiStrip
        tiles={[
          { label: 'Shipment value', value: `${s.currency} ${inr(s.value)}` },
          { label: 'Estimated landed cost', value: `₹ ${inr(cost?.estimate ?? 0)}` },
          { label: 'Actual to date', value: `₹ ${inr(cost?.actual ?? 0)}` },
          { label: 'Variance on invoiced', value: `₹ ${inr(cost?.variance ?? 0)}`, tone: (cost?.variance ?? 0) > 0 ? 'danger' : 'success' },
          { label: 'Documents', value: `${s.docsReceived} / ${s.docsRequired}`, tone: s.docsReceived < s.docsRequired ? 'warning' : 'default' },
          { label: 'Open exceptions', value: s.exceptions.length, tone: criticalExc.length ? 'danger' : 'default' },
        ]}
      />

      <PillTabs value={tab} onChange={setTab} tabs={tabs} />
      <Band />

      {tab === 'overview' && (
        <>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '1fr 380px' }, gap: 0 }}>
            <Box>
              <FieldGrid
                columns={3}
                fields={[
                  { label: 'Supplier / buyer', value: s.party?.name },
                  { label: 'Carrier', value: s.carrier },
                  { label: 'Vessel / voyage', value: s.vessel ? `${s.vessel} · ${s.voyage}` : '—' },
                  { label: 'Transport document', value: s.blNumber ? `${s.blNumber} dated ${date(s.blDate)}` : '—' },
                  { label: 'Port of loading', value: s.portOfLoading },
                  { label: 'Port of discharge', value: s.portOfDischarge },
                  { label: 'Incoterm', value: s.incoterm },
                  { label: 'Forwarder', value: s.forwarder },
                  { label: 'Customs broker', value: s.broker },
                  { label: 'Departure', value: `${date(s.etd)} planned · ${date(s.atd)} actual` },
                  { label: 'Arrival', value: `${date(s.eta)} planned · ${date(s.ata)} actual` },
                  { label: 'Gross / net weight', value: `${qty(s.grossKg, 'KG')} / ${qty(s.netKg, 'KG')}` },
                ]}
              />
              <Section title="Cost sheet summary" actions={s.costSheet ? <Button onClick={() => nav(`/finance/landed-cost/${s.costSheet.id}`)}>Open full sheet</Button> : undefined}>
                {s.costSheet ? <CostSummaryTable costSheet={s.costSheet} /> : <EmptyState title="No cost sheet yet" detail="A cost sheet is created when the shipment is costed." />}
              </Section>
            </Box>

            <Box sx={{ borderLeft: { lg: `1px solid ${color.border}` }, bgcolor: color.surface }}>
              <Box sx={{ p: 1.5 }}>
                <Typography variant="h2" sx={{ mb: 0.75 }}>⚠ Deadlines</Typography>
                {nextDeadline && (
                  <DefRow label="Free time expires">
                    <Stack direction="row" spacing={0.75} alignItems="center">
                      <DeadlineChip iso={nextDeadline} label="Free time" />
                    </Stack>
                  </DefRow>
                )}
                {s.containers.length > 0 && (
                  <DefRow label="Projected detention" tone={color.danger}>
                    ₹{inr(s.containers.reduce((a: number, c: any) => a + c.projectedCharge, 0))} if release slips 3 days
                  </DefRow>
                )}
                {decl && !decl.paidOn && decl.assessedDuty && (
                  <DefRow label="Duty payment due"><DeadlineChip iso="2026-08-05" label="Duty payment" /></DefRow>
                )}

                <Typography variant="h2" sx={{ mt: 2, mb: 0.75 }}>⚠ Exceptions</Typography>
                {s.exceptions.length === 0 && <Typography sx={{ fontSize: font.size.label, color: color.success }}>None open.</Typography>}
                {s.exceptions.map((e: any) => (
                  <Box key={e.id} sx={{ mb: 1, p: 1, border: `1px solid ${color.border}`, borderLeft: `3px solid ${e.severity === 'critical' ? color.danger : color.warning}`, borderRadius: `${shape.radius}px` }}>
                    <Stack direction="row" spacing={0.75} alignItems="center" sx={{ mb: 0.4 }}>
                      <SeverityChip severity={e.severity} />
                      <Typography sx={{ fontSize: font.size.small, color: color.muted }}>{e.type} · {e.ageDays}d</Typography>
                    </Stack>
                    <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold }}>{e.title}</Typography>
                    <Typography sx={{ fontSize: font.size.label, color: color.muted, mt: 0.25 }}>{e.detail}</Typography>
                    {e.exposure ? (
                      <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.semibold, color: color.danger, mt: 0.4 }}>
                        Value at risk ₹{inr(e.exposure)}
                      </Typography>
                    ) : null}
                    <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 0.4 }}>Rule {e.ruleId} · owner {e.owner}</Typography>
                  </Box>
                ))}

                <Typography variant="h2" sx={{ mt: 2, mb: 0.75 }}>Linked records</Typography>
                {s.orders?.map((o: any) => (
                  <DefRow key={o.id} label="Order">
                    <Button size="small" variant="text" onClick={() => nav(`/import/orders/${o.id}`)}>{o.number}</Button>
                  </DefRow>
                ))}
                {s.declarations?.map((d: any) => (
                  <DefRow key={d.id} label="Declaration">
                    <Button size="small" variant="text" onClick={() => nav(`/import/declarations/${d.id}`)}>{d.number}</Button>
                  </DefRow>
                ))}
                {s.orders?.[0]?.instrumentRef && (
                  <DefRow label="Instrument">
                    <Button size="small" variant="text" onClick={() => nav(`/finance/instruments/${s.orders[0].instrumentRef}`)}>
                      LC linked
                    </Button>
                  </DefRow>
                )}
              </Box>
            </Box>
          </Box>
        </>
      )}

      {tab === 'lines' && (
        <DataTable
          rows={(s.orders?.[0]?.lines ?? []).map((l: any) => ({ ...l }))}
          exportName={`${s.number}-lines`}
          searchFields={['itemCode', 'description', 'hsCode']}
          columns={[
            { field: 'itemCode', headerName: 'Item', width: 110 },
            { field: 'description', headerName: 'Description', flex: 1, minWidth: 220 },
            { field: 'hsCode', headerName: 'HS code', width: 110 },
            { field: 'originCountry', headerName: 'Origin', width: 70 },
            { field: 'qty', headerName: 'Quantity', width: 110, align: 'right', headerAlign: 'right', renderCell: (p) => qty(p.value, p.row.uom) },
            { field: 'unitPrice', headerName: 'Unit price', width: 100, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value} currency={p.row.currency} decimals /> },
            { field: 'value', headerName: 'Value', width: 120, align: 'right', headerAlign: 'right', valueGetter: (p: any) => p.row.qty * p.row.unitPrice, renderCell: (p) => <Money value={p.value} currency={p.row.currency} /> },
            { field: 'netWeightKg', headerName: 'Net weight', width: 100, align: 'right', headerAlign: 'right', renderCell: (p) => qty(p.value, 'KG') },
            { field: 'preferenceIntent', headerName: 'Preference', width: 100, renderCell: (p) => p.value ?? '—' },
            { field: 'estLandedCost', headerName: 'Est. landed cost', width: 130, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value} /> },
          ] as GridColDef[]}
        />
      )}

      {tab === 'containers' && (
        s.containers.length === 0
          ? <EmptyState title="No containers" detail="This shipment moves as air cargo or loose cargo, so no container records exist." />
          : <DataTable
              rows={s.containers.map((c: any) => ({ ...c, id: c.number }))}
              exportName={`${s.number}-containers`}
              columns={[
                { field: 'number', headerName: 'Container', width: 140 },
                { field: 'type', headerName: 'Type', width: 80 },
                { field: 'sealNumber', headerName: 'Seal', width: 110 },
                { field: 'tareKg', headerName: 'Tare', width: 90, align: 'right', headerAlign: 'right', renderCell: (p) => qty(p.value, 'KG') },
                { field: 'grossKg', headerName: 'Verified gross mass', width: 150, align: 'right', headerAlign: 'right', renderCell: (p) => qty(p.value, 'KG') },
                { field: 'freeDays', headerName: 'Free days', width: 90, align: 'right', headerAlign: 'right' },
                { field: 'daysUsed', headerName: 'Days used', width: 90, align: 'right', headerAlign: 'right' },
                {
                  field: 'remaining', headerName: 'Remaining', width: 200,
                  valueGetter: (p: any) => p.row.freeDays - p.row.daysUsed,
                  renderCell: (p) => {
                    const remaining = p.value as number;
                    const tone = remaining <= 2 ? color.danger : remaining <= 4 ? color.warning : color.success;
                    return (
                      <Stack direction="row" spacing={0.75} alignItems="center" sx={{ width: '100%' }}>
                        <Box sx={{ flex: 1, height: 6, bgcolor: color.band, borderRadius: 3, overflow: 'hidden' }}>
                          <Box sx={{ width: `${Math.max(0, (remaining / p.row.freeDays) * 100)}%`, height: '100%', bgcolor: tone }} />
                        </Box>
                        <Typography sx={{ fontSize: font.size.small, color: tone, fontWeight: font.weight.bold, minWidth: 46 }}>
                          {remaining <= 0 ? 'expired' : `${remaining} days`}
                        </Typography>
                      </Stack>
                    );
                  },
                },
                { field: 'projectedCharge', headerName: 'Projected charge', width: 130, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value} variance /> },
              ] as GridColDef[]}
            />
      )}

      {tab === 'milestones' && (
        <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
          {s.milestones.map((m: any, i: number) => {
            const done = Boolean(m.actual);
            const late = done && m.planned && m.actual > m.planned;
            return (
              <Stack key={m.key} direction="row" spacing={1.5} alignItems="flex-start" sx={{ pb: 1.5, position: 'relative' }}>
                <Box sx={{ width: 18, display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0 }}>
                  <Box sx={{
                    width: 14, height: 14, borderRadius: '50%', border: `2px solid ${done ? color.success : color.borderStrong}`,
                    bgcolor: done ? color.success : color.surface, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    {done && <CheckIcon sx={{ fontSize: 9, color: '#fff' }} />}
                  </Box>
                  {i < s.milestones.length - 1 && <Box sx={{ width: 2, flex: 1, minHeight: 22, bgcolor: color.border, mt: 0.25 }} />}
                </Box>
                <Box sx={{ flex: 1 }}>
                  <Stack direction="row" spacing={1} alignItems="baseline">
                    <Typography sx={{ fontSize: font.size.body, fontWeight: done ? font.weight.semibold : font.weight.regular }}>{m.label}</Typography>
                    {late && <Chip label="late" sx={{ bgcolor: color.warningSoft, color: color.warning }} />}
                  </Stack>
                  <Typography sx={{ fontSize: font.size.small, color: color.muted }}>
                    planned {date(m.planned)}{m.revised ? ` · revised ${date(m.revised)}` : ''}{m.actual ? ` · actual ${date(m.actual)}` : ' · not yet'}
                  </Typography>
                </Box>
              </Stack>
            );
          })}
        </Box>
      )}

      {tab === 'documents' && <DocumentPanel shipment={s} />}

      {tab === 'declaration' && (
        decl ? (
          <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
            <FieldGrid
              columns={4}
              fields={[
                { label: 'Declaration', value: decl.number },
                { label: 'Type', value: decl.type },
                { label: 'Status', value: <StatusChip status={decl.status} /> },
                { label: 'Authority reference', value: decl.authorityRef },
                { label: 'Filed on', value: date(decl.filedOn) },
                { label: 'Statutory exchange rate', value: decl.statutoryFxRate },
                { label: 'Assessable value', value: `₹ ${inr(decl.assessableValue)}` },
                { label: 'Duty computed', value: `₹ ${inr(decl.dutyTotal)}` },
                { label: 'Duty assessed', value: `₹ ${inr(decl.assessedDuty ?? 0)}` },
                { label: 'Variance', value: <Money value={(decl.assessedDuty ?? 0) - decl.dutyTotal} variance /> },
              ]}
            />
            <Button variant="contained" sx={{ ml: 1.5 }} onClick={() => nav(`/import/declarations/${decl.id}`)}>Open declaration workbench</Button>
          </Box>
        ) : <EmptyState title="No declaration filed" detail="Prepare a declaration from the shipment once the document set is complete." />
      )}

      {tab === 'cost' && (s.costSheet
        ? <CostSummaryTable costSheet={s.costSheet} full />
        : <EmptyState title="No cost sheet" />)}

      {tab === 'exceptions' && (
        <DataTable
          rows={s.exceptions}
          exportName={`${s.number}-exceptions`}
          columns={[
            { field: 'severity', headerName: 'Severity', width: 110, renderCell: (p) => <SeverityChip severity={p.value} /> },
            { field: 'type', headerName: 'Type', width: 140 },
            { field: 'title', headerName: 'Exception', flex: 1, minWidth: 260 },
            { field: 'exposure', headerName: 'Value at risk', width: 130, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value} /> },
            { field: 'ageDays', headerName: 'Age', width: 70, align: 'right', headerAlign: 'right', renderCell: (p) => `${p.value}d` },
            { field: 'owner', headerName: 'Owner', width: 170 },
            { field: 'ruleId', headerName: 'Rule', width: 110 },
          ] as GridColDef[]}
        />
      )}

      {tab === 'activity' && <ActivityLog shipment={s} />}
    </Box>
  );
}

/* -------------------------------------------------------------- stage spine */
function StageSpine({ milestones }: { milestones: any[] }) {
  const key = ['booked', 'onBoard', 'arrived', 'declFiled', 'assessed', 'dutyPaid', 'cleared', 'delivered'];
  const shown = key.map((k) => milestones.find((m) => m.key === k)).filter(Boolean);
  const currentIndex = shown.findIndex((m: any) => !m.actual);
  return (
    <Box sx={{ bgcolor: color.surface, px: 1.5, py: 1, borderTop: `1px solid ${color.border}`, borderBottom: `1px solid ${color.border}`, overflowX: 'auto' }}>
      <Stack direction="row" alignItems="center" spacing={0} sx={{ minWidth: 'min-content' }}>
        {shown.map((m: any, i: number) => {
          const done = Boolean(m.actual);
          const current = i === currentIndex;
          return (
            <React.Fragment key={m.key}>
              <Tooltip title={`${m.label}: ${m.actual ? `actual ${date(m.actual)}` : `planned ${date(m.planned)}`}`}>
                <Stack alignItems="center" spacing={0.25} sx={{ minWidth: 92 }}>
                  <Stack direction="row" spacing={0.5} alignItems="center">
                    <Box sx={{
                      width: 15, height: 15, borderRadius: '50%', flexShrink: 0,
                      bgcolor: done ? color.success : current ? color.primary : color.surface,
                      border: `2px solid ${done ? color.success : current ? color.primary : color.borderStrong}`,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      {done ? <CheckIcon sx={{ fontSize: 9, color: '#fff' }} /> : current ? <Box sx={{ width: 5, height: 5, borderRadius: '50%', bgcolor: '#fff' }} /> : null}
                    </Box>
                    <Typography sx={{ fontSize: font.size.small, fontWeight: current ? font.weight.bold : font.weight.medium, color: current ? color.primary : color.text, whiteSpace: 'nowrap' }}>
                      {`${i + 1}. ${m.label.split(' ')[0]}`}
                    </Typography>
                  </Stack>
                  <Typography sx={{ fontSize: 10, color: done ? color.success : color.muted, whiteSpace: 'nowrap' }}>
                    {done ? date(m.actual).slice(0, 6) : current ? 'now' : '—'}
                  </Typography>
                </Stack>
              </Tooltip>
              {i < shown.length - 1 && <Box sx={{ width: 26, height: 2, bgcolor: done ? color.success : color.border, flexShrink: 0, mt: -1.5 }} />}
            </React.Fragment>
          );
        })}
      </Stack>
    </Box>
  );
}

/* ------------------------------------------------------------ cost summary */
function CostSummaryTable({ costSheet, full }: { costSheet: any; full?: boolean }) {
  const lines = costSheet.lines;
  return (
    <Box sx={{ bgcolor: color.surface, px: 1.5, pb: 1.5 }}>
      <Box component="table" sx={{ width: '100%', borderCollapse: 'collapse', fontSize: font.size.table }}>
        <Box component="thead">
          <Box component="tr" sx={{ bgcolor: color.tableHeader }}>
            {['Element', 'Basis', 'Estimate', 'Accrued', 'Actual', 'Variance', 'Provider', 'Status'].map((h, i) => (
              <Box component="th" key={h} sx={{ textAlign: i >= 2 && i <= 5 ? 'right' : 'left', p: '5px 8px', fontWeight: font.weight.bold, color: color.label, borderBottom: `1px solid ${color.borderStrong}` }}>{h}</Box>
            ))}
          </Box>
        </Box>
        <Box component="tbody">
          <Box component="tr">
            <Box component="td" sx={cellSx}>Goods value</Box>
            <Box component="td" sx={cellSx}>—</Box>
            <Box component="td" sx={numSx}><Money value={costSheet.goodsValue} /></Box>
            <Box component="td" sx={numSx}>—</Box>
            <Box component="td" sx={numSx}><Money value={costSheet.goodsValue} /></Box>
            <Box component="td" sx={numSx}>0</Box>
            <Box component="td" sx={cellSx}>—</Box>
            <Box component="td" sx={cellSx}>matched</Box>
          </Box>
          {lines.map((l: any) => {
            const variance = l.actual !== undefined ? l.actual - l.estimate : null;
            const beyond = variance !== null && Math.abs(variance) > (l.estimate * l.tolerancePct) / 100;
            return (
              <Box component="tr" key={l.id} sx={{ '&:hover': { bgcolor: color.primarySoft } }}>
                <Box component="td" sx={cellSx}>{l.chargeName}</Box>
                <Box component="td" sx={cellSx}>{l.basis}</Box>
                <Box component="td" sx={numSx}><Money value={l.estimate} /></Box>
                <Box component="td" sx={numSx}><Money value={l.accrued} /></Box>
                <Box component="td" sx={numSx}>{l.actual !== undefined ? <Money value={l.actual} /> : <Typography component="span" sx={{ fontSize: 'inherit', color: color.muted }}>pending</Typography>}</Box>
                <Box component="td" sx={numSx}>
                  {variance !== null ? (
                    <Stack direction="row" spacing={0.5} justifyContent="flex-end" alignItems="center">
                      <Money value={variance} variance />
                      {beyond && <Typography component="span" sx={{ fontSize: font.size.small, color: color.warning }}>▲</Typography>}
                    </Stack>
                  ) : '—'}
                </Box>
                <Box component="td" sx={cellSx}>{l.providerName ?? '—'}</Box>
                <Box component="td" sx={cellSx}>
                  <Typography sx={{ fontSize: font.size.small, color: beyond ? color.warning : color.muted }}>{l.status}</Typography>
                </Box>
              </Box>
            );
          })}
        </Box>
      </Box>
    </Box>
  );
}

const cellSx = { p: '5px 8px', borderBottom: `1px solid ${color.border}` } as const;
const numSx = { ...cellSx, textAlign: 'right', fontVariantNumeric: 'tabular-nums' } as const;

/* ------------------------------------------------------------- documents */
function DocumentPanel({ shipment }: { shipment: any }) {
  const docs = [
    { name: 'Commercial invoice', required: true, received: true, version: 1, blocks: '' },
    { name: 'Packing list', required: true, received: true, version: 1, blocks: '' },
    { name: 'Bill of lading (3 originals)', required: true, received: true, version: 1, blocks: '' },
    { name: 'Certificate of origin — AIFTA preferential', required: true, received: false, version: 0, blocks: 'Preferential claim on declaration line 2' },
    { name: 'Insurance certificate', required: true, received: true, version: 2, blocks: '', superseded: true },
    { name: 'Supplier declaration of origin', required: true, received: false, version: 0, blocks: 'Origin determination evidence file' },
    { name: 'Test / inspection certificate', required: true, received: true, version: 1, blocks: '' },
    { name: 'Bill of entry', required: true, received: true, version: 1, blocks: '' },
    { name: 'Duty payment challan', required: true, received: true, version: 1, blocks: '' },
    { name: 'Delivery order', required: true, received: true, version: 1, blocks: '' },
    { name: 'Weight certificate', required: false, received: true, version: 1, blocks: '' },
    { name: 'Fumigation certificate', required: false, received: true, version: 1, blocks: '' },
    { name: 'Short-landing certificate', required: false, received: true, version: 1, blocks: '' },
  ];
  const missing = docs.filter((d) => d.required && !d.received);
  return (
    <Box>
      {missing.length > 0 && (
        <Box sx={{ p: 1.5, bgcolor: color.surface }}>
          <Alert severity="warning">
            <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold }}>
              {missing.length} mandatory document{missing.length > 1 ? 's' : ''} outstanding
            </Typography>
            <Typography sx={{ fontSize: font.size.label }}>
              {missing.map((m) => m.name).join('; ')}. The declaration cannot be released while a mandatory customs document is missing (HBIE-IMP-054).
            </Typography>
          </Alert>
        </Box>
      )}
      <DataTable
        rows={docs.map((d, i) => ({ ...d, id: `doc-${i}` }))}
        exportName={`${shipment.number}-documents`}
        searchFields={['name']}
        columns={[
          { field: 'name', headerName: 'Document', flex: 1, minWidth: 260 },
          { field: 'required', headerName: 'Required for', width: 130, renderCell: (p) => (p.value ? 'Customs + bank' : 'Optional') },
          {
            field: 'received', headerName: 'Status', width: 140,
            renderCell: (p) => (
              p.value
                ? <StatusChip status={p.row.superseded ? 'Superseded' : 'Received'} />
                : <StatusChip status="Pending" />
            ),
          },
          { field: 'version', headerName: 'Version', width: 80, align: 'right', headerAlign: 'right', renderCell: (p) => (p.value ? `v${p.value}` : '—') },
          { field: 'blocks', headerName: 'Blocks', flex: 1, minWidth: 200, renderCell: (p) => p.value || '—' },
        ] as GridColDef[]}
        rowClassName={(r: any) => (r.required && !r.received ? 'row-severity-critical' : undefined)}
      />
    </Box>
  );
}

/* -------------------------------------------------------------- activity */
function ActivityLog({ shipment }: { shipment: any }) {
  const events = [
    { at: '2026-07-12T11:04', who: 'System', what: 'Goods receipt GRN-2026-0881 posted; voucher PJV/2026-27/00418 created', kind: 'posting' },
    { at: '2026-07-10T16:22', who: 'System', what: 'Duty assessed captured from ICEGATE; variance ₹21,400 against own computation raised for disposition', kind: 'determination' },
    { at: '2026-07-10T16:22', who: 'System', what: 'Voucher DTY/2026-27/00212 posted under rule PR-IMP-05 v3', kind: 'posting' },
    { at: '2026-07-09T09:11', who: 'D. Rao', what: 'Origin proof exception raised on line 2 — preferential claim blocked (VR-009)', kind: 'exception' },
    { at: '2026-07-07T14:40', who: 'Bluewave Clearing', what: 'Declaration filed; authority reference 4471021 received', kind: 'filing' },
    { at: '2026-07-07T12:02', who: 'A. Kulkarni', what: 'Declaration data set validated — 5 findings, 1 error', kind: 'validation' },
    { at: '2026-07-05T10:30', who: 'System', what: 'Free-time clock started on 2 containers; 7 free days per rate contract AGL-2026-LANE-KR', kind: 'milestone' },
    { at: '2026-06-22T08:15', who: 'Acme Global Logistics', what: 'Loaded on board; transport document OSLNSA2604471 issued', kind: 'milestone' },
  ];
  return (
    <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
      {events.map((e, i) => (
        <Stack key={i} direction="row" spacing={1.5} sx={{ py: 0.75, borderBottom: `1px solid ${color.border}` }}>
          <Typography sx={{ fontSize: font.size.small, color: color.muted, minWidth: 120, fontVariantNumeric: 'tabular-nums' }}>
            {date(e.at)} {e.at.slice(11)}
          </Typography>
          <Chip label={e.kind} sx={{ bgcolor: color.band, color: color.label, minWidth: 92 }} />
          <Typography sx={{ fontSize: font.size.label, color: color.label, minWidth: 140 }}>{e.who}</Typography>
          <Typography sx={{ fontSize: font.size.body, flex: 1 }}>{e.what}</Typography>
        </Stack>
      ))}
    </Box>
  );
}
