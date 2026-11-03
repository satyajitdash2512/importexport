import * as React from 'react';
import {
  Box, Stack, Typography, Button, Chip, TextField, MenuItem, Alert, AlertTitle, Divider,
  Dialog, DialogTitle, DialogContent, DialogActions, ToggleButtonGroup, ToggleButton, Tooltip, Snackbar,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import AttachFileIcon from '@mui/icons-material/AttachFile';
import { useParams } from 'react-router-dom';
import { color, font, shape } from '../../../context/tokens';
import { useApi, post } from '../../../lib/api';
import { inr, date, qty, pct } from '../../../utils/format';
import {
  Band, PageHeader, Section, StatusChip, Loading, ErrorState, Money, ComputationTree,
  type ComputationStep, DefRow, KpiStrip,
} from '../../../components/primitives';

const SECTIONS = [
  { key: 'header', label: 'Header' },
  { key: 'parties', label: 'Parties' },
  { key: 'lines', label: 'Lines' },
  { key: 'valuation', label: 'Valuation' },
  { key: 'origin', label: 'Origin' },
  { key: 'licences', label: 'Licences' },
  { key: 'levies', label: 'Levies' },
  { key: 'permits', label: 'Agency permits' },
  { key: 'documents', label: 'Documents' },
  { key: 'review', label: 'Review' },
];

export default function DeclarationWorkbench() {
  const { id } = useParams();
  const { data: d, isLoading, error, refetch } = useApi<any>(['declaration', id], `/declarations/${id}`);
  const [activeLine, setActiveLine] = React.useState(0);
  const [section, setSection] = React.useState('lines');
  const [proofDialog, setProofDialog] = React.useState(false);
  const [recomputed, setRecomputed] = React.useState<Record<string, any>>({});
  const [toast, setToast] = React.useState<string | null>(null);
  const [showReview, setShowReview] = React.useState(false);

  if (isLoading) return <Loading label="Loading declaration" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!d) return null;

  const line = d.lines[activeLine];
  const errors = d.validations.filter((v: any) => v.severity === 'error');
  const warnings = d.validations.filter((v: any) => v.severity === 'warning');
  const lineOverride = line ? recomputed[line.id] : undefined;

  const attachProof = async () => {
    const res = await post<any>(`/declarations/${d.id}/compute`, { lineId: line.id, hasPreferenceProof: true });
    setRecomputed((r) => ({ ...r, [line.id]: res }));
    setProofDialog(false);
    setToast(`Origin proof recorded. Preferential rate applied — duty saved ₹${inr(res.dutySaved)}.`);
  };

  const lineLevies = lineOverride?.levies ?? line?.levies ?? [];
  const lineDutyTotal = lineLevies.reduce((s: number, l: any) => s + l.amount, 0);
  const blockedOnLine = lineOverride ? 0 : (line?.dutyForegoneBlocked ?? 0);

  const computationSteps: ComputationStep[] = line ? [
    { label: 'Invoice value', detail: `${qty(line.qty, line.statutoryUom)} × ${line.currency} ${(line.invoiceValueFc / line.qty).toFixed(2)}`, amount: line.invoiceValueFc, currency: line.currency },
    { label: 'Add: cost of transport to place of importation', amount: line.freightFc, currency: line.currency },
    { label: 'Add: insurance', amount: line.insuranceFc, currency: line.currency },
    { label: 'Value for duty (transaction currency)', amount: line.invoiceValueFc + line.freightFc + line.insuranceFc, currency: line.currency, emphasis: true },
    { label: `Statutory exchange rate applied`, detail: `notified rate on declaration date · ${d.statutoryFxRate}`, note: 'not the accounting rate' },
    {
      label: 'Assessable value', amount: line.assessableValue, emphasis: true,
      children: lineLevies.map((lv: any) => ({
        label: `${lv.name} (${lv.code})`,
        detail: `${lv.basis} × ${lv.rate}%`,
        amount: lv.amount,
        note: lv.recoverable ? 'recoverable' : undefined,
      })),
    },
    { label: 'Total duty and taxes on this line', amount: lineDutyTotal, emphasis: true },
    ...(blockedOnLine > 0 ? [{
      label: 'Duty saving available but BLOCKED', detail: 'preferential rate not applied — origin proof absent',
      amount: -blockedOnLine, note: 'attach proof to realise',
    }] : []),
    ...(lineOverride?.dutySaved ? [{ label: 'Duty saved by preference', amount: -lineOverride.dutySaved, note: 'realised' }] : []),
  ] : [];

  return (
    <Box>
      <PageHeader
        onBack
        title={`Declaration ${d.number}`}
        subtitle={`${d.direction === 'import' ? 'Import' : 'Export'} · ${d.type} · ${d.lines.length} lines · port ${d.portCode} · ${d.filingChannel}`}
        meta={<StatusChip status={d.status} />}
        actions={
          <>
            <Button onClick={() => refetch()}>Validate</Button>
            <Button onClick={() => setShowReview(true)}>Review as filed</Button>
            <Tooltip title={errors.length ? `${errors.length} error(s) must be cleared before filing` : 'Release to the filing channel'}>
              <span><Button variant="contained" disabled={errors.length > 0}>File</Button></span>
            </Tooltip>
          </>
        }
      />

      <KpiStrip
        tiles={[
          { label: 'Assessable value', value: `₹ ${inr(d.assessableValue)}` },
          { label: 'Duty computed', value: `₹ ${inr(d.dutyTotal)}` },
          { label: 'Of which recoverable', value: `₹ ${inr(d.dutyRecoverable)}` },
          { label: 'Duty assessed by customs', value: d.assessedDuty ? `₹ ${inr(d.assessedDuty)}` : '—' },
          { label: 'Variance to own computation', value: d.assessedDuty ? `₹ ${inr(d.assessedDuty - d.dutyTotal)}` : '—', tone: d.assessedDuty && d.assessedDuty > d.dutyTotal ? 'warning' : 'default' },
          { label: 'Duty saving blocked', value: `₹ ${inr(d.blockedSaving)}`, tone: d.blockedSaving > 0 ? 'danger' : 'success' },
        ]}
      />

      <Band />
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '190px 1fr 320px' }, gap: 0, alignItems: 'stretch' }}>
        {/* ------------------------------------------------------- sections */}
        <Box sx={{ bgcolor: color.surface, borderRight: { lg: `1px solid ${color.border}` }, py: 1 }}>
          <Typography sx={{ px: 1.5, fontSize: font.size.small, fontWeight: font.weight.bold, color: color.label, mb: 0.5 }}>
            SECTIONS
          </Typography>
          {SECTIONS.map((s) => {
            const sectionErrors = errors.filter((e: any) => sectionOf(e.field) === s.key).length;
            const sectionWarn = warnings.filter((e: any) => sectionOf(e.field) === s.key).length;
            const active = section === s.key;
            return (
              <Stack
                key={s.key} direction="row" alignItems="center" spacing={0.75}
                component="button"
                onClick={() => setSection(s.key)}
                sx={{
                  width: '100%', border: 'none', textAlign: 'left', cursor: 'pointer', font: 'inherit',
                  px: 1.5, py: 0.6, bgcolor: active ? color.primarySoft : 'transparent',
                  borderLeft: `3px solid ${active ? color.primary : 'transparent'}`,
                  '&:hover': { bgcolor: color.primarySoft },
                }}
              >
                {sectionErrors > 0 ? <ErrorIcon sx={{ fontSize: 13, color: color.danger }} />
                  : sectionWarn > 0 ? <WarningAmberIcon sx={{ fontSize: 13, color: color.warning }} />
                  : <CheckCircleIcon sx={{ fontSize: 13, color: color.success }} />}
                <Typography sx={{ fontSize: font.size.body, color: active ? color.primary : color.text, fontWeight: active ? font.weight.semibold : font.weight.regular }}>
                  {s.label}
                </Typography>
                {s.key === 'lines' && (
                  <Typography sx={{ fontSize: font.size.small, color: color.muted, ml: 'auto' }}>
                    {d.lines.length - errors.filter((e: any) => e.lineNo).length}/{d.lines.length}
                  </Typography>
                )}
              </Stack>
            );
          })}
          <Divider sx={{ my: 1 }} />
          <Box sx={{ px: 1.5 }}>
            <Button fullWidth sx={{ mb: 0.5 }}>Add line ⊕</Button>
            <Typography sx={{ fontSize: font.size.small, fontWeight: font.weight.bold, color: color.label, mt: 1 }}>TEMPLATES</Typography>
            <Button fullWidth variant="text" sx={{ justifyContent: 'flex-start' }}>▸ Last similar declaration</Button>
            <Button fullWidth variant="text" sx={{ justifyContent: 'flex-start' }}>▸ Copy from BOE-4412</Button>
          </Box>
        </Box>

        {/* ----------------------------------------------------- line editor */}
        <Box sx={{ bgcolor: color.surface, minWidth: 0 }}>
          <Stack direction="row" alignItems="center" spacing={1} sx={{ px: 1.5, pt: 1.25, pb: 0.5 }}>
            <Typography variant="h2">Line {activeLine + 1} of {d.lines.length}</Typography>
            <ToggleButtonGroup
              size="small" exclusive value={activeLine}
              onChange={(_, v) => v !== null && setActiveLine(v)}
              aria-label="Select declaration line"
            >
              {d.lines.map((l: any, i: number) => {
                const hasErr = errors.some((e: any) => e.lineNo === l.lineNo);
                return (
                  <ToggleButton key={l.id} value={i} aria-label={`Line ${i + 1}`}>
                    {i + 1}
                    {hasErr && <ErrorIcon sx={{ fontSize: 11, color: color.danger, ml: 0.3 }} />}
                  </ToggleButton>
                );
              })}
            </ToggleButtonGroup>
          </Stack>

          {line && (
            <Box sx={{ px: 1.5, pb: 1.5 }}>
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 1.25, mb: 1.5 }}>
                <TextField label="Item" value={`${line.itemCode} — ${line.description}`} InputProps={{ readOnly: true }} />
                <TextField label="Classification (HS code)" value={line.hsCode} helperText="Confirmed by compliance officer on 05-Jul-2026 · basis retained" />
                <TextField
                  label={`Quantity (statutory ${line.statutoryUom})`}
                  value={line.qty}
                  helperText={`Stock unit ${line.stockUom} · conversion ${line.conversion}`}
                />
                <TextField label="Unit price" value={(line.invoiceValueFc / line.qty).toFixed(2)} helperText={line.currency} />
                <TextField label="Country of origin" value={line.originCountry} select>
                  <MenuItem value={line.originCountry}>{line.originCountry}</MenuItem>
                </TextField>
                <TextField label="Preference claimed" value={line.preferenceAgreement ?? 'None'} select>
                  <MenuItem value={line.preferenceAgreement ?? 'None'}>{line.preferenceAgreement ?? 'None'}</MenuItem>
                </TextField>
                <Box>
                  <Stack direction="row" spacing={1} alignItems="flex-start">
                    <TextField
                      label="Origin proof reference"
                      value={lineOverride ? 'COO/KR/2026/90118 (attached now)' : line.preferenceProofRef ?? ''}
                      placeholder="Not attached"
                      error={Boolean(line.preferenceAgreement && !line.preferenceProofRef && !lineOverride)}
                      helperText={
                        line.preferenceAgreement && !line.preferenceProofRef && !lineOverride
                          ? 'Mandatory for a preferential claim (VR-009)'
                          : 'Type, issuer and validity recorded'
                      }
                      sx={{ flex: 1 }}
                    />
                    {line.preferenceAgreement && !line.preferenceProofRef && !lineOverride && (
                      <Button startIcon={<AttachFileIcon sx={{ fontSize: 15 }} />} onClick={() => setProofDialog(true)} sx={{ mt: 0.25 }}>
                        Attach
                      </Button>
                    )}
                  </Stack>
                </Box>
                <TextField label="Licence / authorisation" value={line.licenceRef ?? 'None'} helperText={line.licenceRef ? 'Entitlement provisionally debited' : ''} />
                <TextField label="Net weight (KG)" value={line.netWeightKg} />
                <TextField label="Assessable value (₹)" value={inr(line.assessableValue, { decimals: true })} InputProps={{ readOnly: true }} />
              </Box>

              <Section title={`Levies — line ${activeLine + 1}`} noBand
                actions={<Chip label={lineOverride ? `rule ${lineOverride.ruleVersion}` : 'rule IN-PACK-2026.08 / duty-v3'} sx={{ bgcolor: color.band, color: color.label }} />}>
                <Box sx={{ border: `1px solid ${color.border}`, borderRadius: `${shape.radius}px`, overflow: 'hidden' }}>
                  <ComputationTree steps={computationSteps} />
                </Box>
                {blockedOnLine > 0 && (
                  <Alert severity="error" sx={{ mt: 1 }}>
                    <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>
                      Preferential rate available but blocked — ₹{inr(blockedOnLine)} of duty saving is being forgone
                    </AlertTitle>
                    <Typography sx={{ fontSize: font.size.label }}>
                      {line.preferenceAgreement} gives a nil basic duty rate on {line.hsCode}. The claim requires the origin proof
                      reference and confirmation that the underlying origin information is held. Attach the certificate to realise
                      the saving, or file at the schedule rate and record the reason.
                    </Typography>
                  </Alert>
                )}
              </Section>
            </Box>
          )}
        </Box>

        {/* --------------------------------------- validation + computation */}
        <Box sx={{ bgcolor: color.surface, borderLeft: { lg: `1px solid ${color.border}` } }}>
          <Box sx={{ p: 1.5 }}>
            <Stack direction="row" alignItems="center" spacing={0.75} sx={{ mb: 0.75 }}>
              <Typography variant="h2">Validation</Typography>
              <Chip
                label={`${errors.length} error${errors.length === 1 ? '' : 's'} · ${warnings.length} warning${warnings.length === 1 ? '' : 's'}`}
                sx={{ bgcolor: errors.length ? color.dangerSoft : color.successSoft, color: errors.length ? color.danger : color.success }}
              />
            </Stack>

            {d.validations.length === 0 && (
              <Typography sx={{ fontSize: font.size.label, color: color.success }}>
                All checks pass. The declaration may be released to the filing channel.
              </Typography>
            )}

            {d.validations.map((v: any) => {
              const suppressed = v.rule === 'VR-009' && recomputed[d.lines.find((l: any) => l.lineNo === v.lineNo)?.id ?? ''];
              if (suppressed) return null;
              const isError = v.severity === 'error';
              return (
                <Box
                  key={v.id}
                  onClick={() => { if (v.lineNo) setActiveLine(d.lines.findIndex((l: any) => l.lineNo === v.lineNo)); setSection(sectionOf(v.field)); }}
                  sx={{
                    mb: 1, p: 1, cursor: 'pointer', borderRadius: `${shape.radius}px`,
                    border: `1px solid ${isError ? color.danger : color.warning}44`,
                    borderLeft: `3px solid ${isError ? color.danger : color.warning}`,
                    bgcolor: isError ? color.dangerSoft : color.warningSoft,
                    '&:hover': { filter: 'brightness(0.98)' },
                  }}
                >
                  <Stack direction="row" spacing={0.5} alignItems="center">
                    {isError ? <ErrorIcon sx={{ fontSize: 13, color: color.danger }} /> : <WarningAmberIcon sx={{ fontSize: 13, color: color.warning }} />}
                    <Typography sx={{ fontSize: font.size.small, fontWeight: font.weight.bold, color: isError ? color.danger : color.warning }}>
                      {isError ? 'ERROR' : 'WARNING'} · {v.rule}{v.lineNo ? ` · line ${v.lineNo}` : ''}
                    </Typography>
                  </Stack>
                  <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.semibold, mt: 0.4 }}>{v.field}</Typography>
                  <Typography sx={{ fontSize: font.size.label, color: color.text, mt: 0.25 }}>{v.message}</Typography>
                  <Typography sx={{ fontSize: font.size.small, color: color.label, mt: 0.4, fontStyle: 'italic' }}>→ {v.remedy}</Typography>
                </Box>
              );
            })}

            <Divider sx={{ my: 1.5 }} />
            <Typography variant="h2" sx={{ mb: 0.75 }}>Declaration totals</Typography>
            <DefRow label="Lines">{d.lines.length}</DefRow>
            <DefRow label="Assessable value">₹{inr(d.assessableValue, { decimals: true })}</DefRow>
            <DefRow label="Duty computed">₹{inr(d.dutyTotal, { decimals: true })}</DefRow>
            <DefRow label="Inventoriable">₹{inr(d.dutyInventoriable, { decimals: true })}</DefRow>
            <DefRow label="Recoverable (IGST)">₹{inr(d.dutyRecoverable, { decimals: true })}</DefRow>
            {d.assessedDuty && (
              <>
                <DefRow label="Assessed by customs">₹{inr(d.assessedDuty, { decimals: true })}</DefRow>
                <DefRow label="Variance" tone={color.warning}>
                  <Money value={d.assessedDuty - d.dutyTotal} variance decimals />
                  <Typography sx={{ fontSize: font.size.small, color: color.muted }}>
                    Classify and dispose before closure (HBIE-IMP-072)
                  </Typography>
                </DefRow>
              </>
            )}
            <DefRow label="Content version">IN-PACK-2026.08</DefRow>
          </Box>
        </Box>
      </Box>

      {/* --------------------------------------------------- attach dialog */}
      <Dialog open={proofDialog} onClose={() => setProofDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Attach origin proof — line {activeLine + 1}</DialogTitle>
        <DialogContent>
          <Typography sx={{ fontSize: font.size.body, mb: 1.5 }}>
            Recording an origin proof enables the preferential claim. The module retains the proof reference and requires
            confirmation that the underlying origin information is held, because it must be producible on verification
            years later (HBIE-CMP-061).
          </Typography>
          <Stack spacing={1.25}>
            <TextField label="Proof mode" select defaultValue="agency">
              <MenuItem value="agency">Authority / agency certificate of origin</MenuItem>
              <MenuItem value="approved">Approved-exporter self-certification</MenuItem>
              <MenuItem value="importer">Importer origin declaration</MenuItem>
            </TextField>
            <TextField label="Reference" defaultValue="COO/KR/2026/90118" />
            <TextField label="Issuing body" defaultValue="Korea Chamber of Commerce and Industry" />
            <TextField label="Valid to" defaultValue="2027-06-20" />
            <Alert severity="info">
              I confirm the underlying origin information (bill of materials, input origin and value) is held and can be produced on verification.
            </Alert>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setProofDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={attachProof}>Record proof and recompute duty</Button>
        </DialogActions>
      </Dialog>

      {/* --------------------------------------------------- review as filed */}
      <Dialog open={showReview} onClose={() => setShowReview(false)} maxWidth="md" fullWidth>
        <DialogTitle>Review — declaration as it will be transmitted</DialogTitle>
        <DialogContent>
          <Typography sx={{ fontSize: font.size.small, color: color.muted, mb: 1 }}>
            This is the exact data set that will be sent to {d.filingChannel} and retained immutably as the evidentiary record (HBIE-IMP-068).
          </Typography>
          <Box component="pre" sx={{ fontFamily: font.mono, fontSize: 11, bgcolor: color.canvas, p: 1.5, borderRadius: `${shape.radius}px`, overflow: 'auto', maxHeight: 420, border: `1px solid ${color.border}` }}>
{JSON.stringify({
  declarationType: d.type, portCode: d.portCode, importer: d.party?.name,
  statutoryFxRate: d.statutoryFxRate, assessableValue: d.assessableValue,
  lines: d.lines.map((l: any) => ({
    lineNo: l.lineNo, hsCode: l.hsCode, description: l.description,
    qty: l.qty, uom: l.statutoryUom, invoiceValue: l.invoiceValueFc, currency: l.currency,
    origin: l.originCountry, preference: l.preferenceAgreement ?? null,
    proofRef: l.preferenceProofRef ?? null, licence: l.licenceRef ?? null,
    assessableValue: l.assessableValue,
    levies: l.levies.map((x: any) => ({ code: x.code, rate: x.rate, amount: x.amount })),
  })),
  dutyTotal: d.dutyTotal, contentVersion: 'IN-PACK-2026.08',
}, null, 2)}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowReview(false)}>Close</Button>
          <Button variant="contained" disabled={errors.length > 0}>Confirm and file</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={Boolean(toast)} autoHideDuration={6000} onClose={() => setToast(null)} message={toast} anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }} />
    </Box>
  );
}

function sectionOf(field: string) {
  const f = field.toLowerCase();
  if (f.includes('origin')) return 'origin';
  if (f.includes('weight') || f.includes('unit') || f.includes('quantity')) return 'lines';
  if (f.includes('value')) return 'valuation';
  if (f.includes('licence')) return 'licences';
  if (f.includes('permit')) return 'permits';
  return 'lines';
}
