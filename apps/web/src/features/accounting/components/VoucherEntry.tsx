import * as React from 'react';
import {
  Box, Stack, Typography, Button, Chip, TextField, MenuItem, Alert, AlertTitle, Divider,
  Dialog, DialogTitle, DialogContent, DialogActions, Snackbar, Tooltip, IconButton,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import RadioButtonUncheckedIcon from '@mui/icons-material/RadioButtonUnchecked';
import AttachFileIcon from '@mui/icons-material/AttachFile';
import { useNavigate, useParams } from 'react-router-dom';
import { color, font, shape } from '../../../context/tokens';
import { useApi, post } from '../../../lib/api';
import { useAuth } from '../../../context/AuthContext';
import { createVoucher, postVoucher, reverseVoucher, openPrint } from '../../../lib/crud';
import { inr, date, dateTime } from '../../../utils/format';
import {
  Band, PageHeader, Section, KpiStrip, StatusChip, Loading, ErrorState, Money, DefRow, PillTabs, EmptyState,
} from '../../../components/primitives';

const EVENTS = [
  { value: 'goodsReceipt', label: 'Goods receipt at estimated landed cost', voucher: 'PJV' },
  { value: 'dutyAssessed', label: 'Customs duty assessed', voucher: 'DTY' },
  { value: 'ownershipTransferInTransit', label: 'Ownership transfer in transit per Incoterm', voucher: 'PJV' },
  { value: 'landedCostClosure', label: 'Landed cost closure', voucher: 'LCV' },
  { value: 'exportDispatch', label: 'Export dispatch — revenue recognition', voucher: 'SIV' },
  { value: 'exportRealisation', label: 'Export realisation', voucher: 'RCP' },
  { value: 'entitlementAccrual', label: 'Entitlement accrual', voucher: 'ENT' },
  { value: 'fxRevaluation', label: 'Foreign exchange revaluation', voucher: 'FXR' },
  { value: 'unmappedEvent', label: '— an event with no posting rule (demonstrates the block) —', voucher: '?' },
];

const AMOUNT_FIELDS: Record<string, { key: string; label: string; default: number }[]> = {
  goodsReceipt: [
    { key: 'estimatedLandedCost', label: 'Estimated landed cost', default: 1846500 },
    { key: 'goodsValueFunc', label: 'Goods value (functional)', default: 1522000 },
    { key: 'dutyInventoriable', label: 'Duty — inventoriable', default: 286140 },
    { key: 'freightEstimate', label: 'Freight estimate', default: 31000 },
    { key: 'portEstimate', label: 'Port and brokerage estimate', default: 7360 },
  ],
  dutyAssessed: [
    { key: 'dutyInventoriable', label: 'Duty — inventoriable', default: 794465 },
    { key: 'dutyRecoverable', label: 'Duty — recoverable (IGST)', default: 2657871 },
    { key: 'dutyTotal', label: 'Duty total', default: 3452336 },
  ],
  ownershipTransferInTransit: [{ key: 'goodsValueFunc', label: 'Goods value (functional)', default: 1522000 }],
  landedCostClosure: [
    { key: 'toInventory', label: 'To inventory', default: 33232 },
    { key: 'toCogs', label: 'To cost of goods sold', default: 20368 },
    { key: 'differential', label: 'Differential', default: 53600 },
  ],
  exportDispatch: [{ key: 'invoiceValueFunc', label: 'Invoice value (functional)', default: 33045920 }],
  exportRealisation: [
    { key: 'netCredited', label: 'Net credited to bank', default: 2812400 },
    { key: 'bankCharges', label: 'Bank charges', default: 27600 },
    { key: 'fxLoss', label: 'Realised exchange loss', default: 12000 },
    { key: 'carryingAmount', label: 'Receivable carrying amount', default: 2852000 },
  ],
  entitlementAccrual: [{ key: 'entitlementValue', label: 'Entitlement value', default: 260064 }],
  fxRevaluation: [{ key: 'revalLoss', label: 'Revaluation loss', default: 412000 }],
  unmappedEvent: [{ key: 'amount', label: 'Amount', default: 100000 }],
};

/* ========================================================================== */
/*  NEW VOUCHER  —  posting preview before submission (HBIE-VCH-005)          */
/* ========================================================================== */
export function VoucherEntry() {
  const nav = useNavigate();
  const [event, setEvent] = React.useState('goodsReceipt');
  const [amounts, setAmounts] = React.useState<Record<string, number>>(
    Object.fromEntries(AMOUNT_FIELDS.goodsReceipt.map((f) => [f.key, f.default])),
  );
  const [preview, setPreview] = React.useState<any>(null);
  const [narration, setNarration] = React.useState('Goods receipt against BOE-4471 / SHP-2026-04471 at estimated landed cost');
  const [docDate, setDocDate] = React.useState('2026-07-31');
  const [toast, setToast] = React.useState<string | null>(null);
  const [confirm, setConfirm] = React.useState(false);
  const [submitting, setSubmitting] = React.useState(false);
  const [submitError, setSubmitError] = React.useState<string | null>(null);
  const [evidence, setEvidence] = React.useState<Record<string, boolean>>({});
  const { can } = useAuth();

  const submitVoucher = async (thenPost: boolean) => {
    if (!preview?.balanced) return;
    setSubmitting(true); setSubmitError(null);
    try {
      const lines = (preview.lines ?? []).map((l: any) => ({ accountCode: l.accountCode, drCr: l.drCr, amount: l.amountFunc }));
      const created = await createVoucher({ voucherType: voucherCode, date: docDate, narration, currency: 'INR', lines });
      if (thenPost && can('voucher:post')) {
        const posted = await postVoucher(created.id);
        setConfirm(false);
        nav(`/accounting/vouchers/${created.id}`);
        setToast(`Posted as ${posted.number}.`);
      } else {
        setConfirm(false);
        nav(`/accounting/vouchers/${created.id}`);
        setToast(`Parked as ${created.id}. Approve and post from the voucher.`);
      }
    } catch (e: any) { setSubmitError(e.message ?? 'Submit failed'); }
    finally { setSubmitting(false); }
  };

  const { data: voucherTypes = [] } = useApi<any[]>(['voucherTypes'], '/voucher-types');
  const voucherCode = EVENTS.find((e) => e.value === event)?.voucher ?? 'JVM';
  const vt = voucherTypes.find((t) => t.code === voucherCode);

  React.useEffect(() => {
    const fields = AMOUNT_FIELDS[event] ?? [];
    setAmounts(Object.fromEntries(fields.map((f) => [f.key, f.default])));
    setEvidence({});
  }, [event]);

  React.useEffect(() => {
    let live = true;
    (async () => {
      const res = await post<any>('/postings/preview', {
        event, amounts,
        dimensions: { entity: 'HB Manufacturing Ltd', site: 'Pune Unit I', shipment: 'SHP-2026-04471', declaration: 'BOE-4471', costCentre: 'CC-PROD-01' },
        currency: 'INR', fxRate: 1,
      });
      if (live) setPreview(res);
    })();
    return () => { live = false; };
  }, [event, amounts]);

  const mandatoryEvidence = vt?.requiredEvidence ?? [];
  const evidenceComplete = mandatoryEvidence.every((e: string) => evidence[e]);
  const canSubmit = preview?.balanced && evidenceComplete && narration.trim().length > 0;

  return (
    <Box>
      <PageHeader
        title="New accounting voucher"
        subtitle="Record the event; the posting rule determines the entry. The posting is shown before submission (HBIE-VCH-005)."
        onBack
        actions={
          <>
            <Button onClick={() => nav('/accounting/vouchers')}>Voucher register</Button>
            <Tooltip title={canSubmit ? 'Submit for approval' : 'Complete the mandatory evidence set and ensure the posting balances'}>
              <span><Button variant="contained" disabled={!canSubmit} onClick={() => setConfirm(true)}>Submit for approval</Button></span>
            </Tooltip>
          </>
        }
      />

      <Band />
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '1fr 1fr' }, gap: 0 }}>
        {/* ------------------------------------------------------- the event */}
        <Box sx={{ bgcolor: color.surface, borderRight: { lg: `1px solid ${color.border}` } }}>
          <Section title="The business event" noBand>
            <Box sx={{ px: 1.5, pb: 1.5 }}>
              <TextField
                select fullWidth label="Business event" value={event} onChange={(e) => setEvent(e.target.value)}
                helperText="A user records the event, not the journal. The voucher type and posting follow."
              >
                {EVENTS.map((e) => <MenuItem key={e.value} value={e.value}>{e.label}</MenuItem>)}
              </TextField>

              <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 1.25, mt: 1.5 }}>
                <TextField label="Voucher type" value={vt ? `${vt.code} — ${vt.name}` : voucherCode} InputProps={{ readOnly: true }} />
                <TextField label="Series number" value="allocated at posting" InputProps={{ readOnly: true }} helperText="Never at creation (HBIE-VCH-011)" />
                <TextField label="Document date" type="date" value={docDate} onChange={(e) => setDocDate(e.target.value)} InputLabelProps={{ shrink: true }} />
                <TextField label="Book" value="Primary (Ind AS)" select>
                  <MenuItem value="Primary (Ind AS)">Primary (Ind AS)</MenuItem>
                  <MenuItem value="Tax">Tax</MenuItem>
                </TextField>
              </Box>

              <TextField
                label="Narration" fullWidth multiline rows={2} sx={{ mt: 1.5 }}
                value={narration} onChange={(e) => setNarration(e.target.value)}
                required error={narration.trim().length === 0}
                helperText={narration.trim().length === 0 ? 'Narration is mandatory' : ' '}
              />

              <Typography variant="h2" sx={{ mt: 1.5, mb: 0.75 }}>Amounts</Typography>
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 1.25 }}>
                {(AMOUNT_FIELDS[event] ?? []).map((f) => (
                  <TextField
                    key={f.key} label={f.label} type="number" value={amounts[f.key] ?? 0}
                    onChange={(e) => setAmounts((a) => ({ ...a, [f.key]: Number(e.target.value) }))}
                    InputProps={{ startAdornment: <Typography sx={{ fontSize: font.size.label, color: color.muted, mr: 0.5 }}>₹</Typography> }}
                  />
                ))}
              </Box>

              <Typography variant="h2" sx={{ mt: 1.5, mb: 0.75 }}>Dimensions</Typography>
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 1.25 }}>
                <TextField label="Legal entity" value="HB Manufacturing Ltd" InputProps={{ readOnly: true }} />
                <TextField label="Site" value="Pune Unit I" InputProps={{ readOnly: true }} />
                <TextField label="Shipment" value="SHP-2026-04471" InputProps={{ readOnly: true }} />
                <TextField label="Declaration" value="BOE-4471" InputProps={{ readOnly: true }} />
                <TextField label="Cost centre" value="CC-PROD-01" InputProps={{ readOnly: true }} />
              </Box>
              <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 0.75 }}>
                Dimensions are derived from the source transaction; manual entry is the exception (HBIE-ACC-021).
              </Typography>

              <Typography variant="h2" sx={{ mt: 1.5, mb: 0.75 }}>
                Mandatory evidence — voucher type {voucherCode}
              </Typography>
              {mandatoryEvidence.length === 0 && (
                <Typography sx={{ fontSize: font.size.label, color: color.muted }}>No evidence defined for this voucher type.</Typography>
              )}
              {mandatoryEvidence.map((e: string) => (
                <Stack key={e} direction="row" alignItems="center" spacing={1} sx={{ py: 0.4, borderBottom: `1px solid ${color.border}` }}>
                  {evidence[e]
                    ? <CheckCircleIcon sx={{ fontSize: 15, color: color.success }} />
                    : <RadioButtonUncheckedIcon sx={{ fontSize: 15, color: color.warning }} />}
                  <Typography sx={{ fontSize: font.size.body, flex: 1 }}>{e}</Typography>
                  <Button
                    startIcon={<AttachFileIcon sx={{ fontSize: 14 }} />}
                    onClick={() => setEvidence((v) => ({ ...v, [e]: true }))}
                    disabled={Boolean(evidence[e])}
                  >
                    {evidence[e] ? 'Attached' : 'Attach'}
                  </Button>
                </Stack>
              ))}
              {!evidenceComplete && mandatoryEvidence.length > 0 && (
                <Alert severity="warning" sx={{ mt: 1 }}>
                  Approval is blocked while a mandatory evidence item is absent (VR-038). Override requires the controller and
                  is entered in the override register.
                </Alert>
              )}
            </Box>
          </Section>
        </Box>

        {/* ---------------------------------------------------- the posting */}
        <Box sx={{ bgcolor: color.surface }}>
          <Section title="Posting preview" noBand
            actions={preview?.rule ? <Chip label={`${preview.rule.code} ${preview.rule.version}`} sx={{ bgcolor: color.primarySoft, color: color.primary }} /> : undefined}>
            <Box sx={{ px: 1.5, pb: 1.5 }}>
              {preview?.error ? (
                <Alert severity="error">
                  <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>No posting rule matches this event</AlertTitle>
                  <Typography sx={{ fontSize: font.size.label }}>{preview.error}</Typography>
                </Alert>
              ) : preview ? (
                <>
                  <Box sx={{ mb: 1, p: 1, bgcolor: color.canvas, border: `1px solid ${color.border}`, borderRadius: `${shape.radius}px` }}>
                    <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.semibold }}>{preview.rule.description}</Typography>
                    <Typography sx={{ fontSize: font.size.small, color: color.muted }}>
                      Rule {preview.rule.code} {preview.rule.version} · effective from {date(preview.rule.effectiveFrom)} · book {preview.rule.book}
                      {preview.rule.standardRef ? ` · ${preview.rule.standardRef}` : ''}
                    </Typography>
                  </Box>

                  <Box component="table" sx={{ width: '100%', borderCollapse: 'collapse', fontSize: font.size.table }}>
                    <thead>
                      <Box component="tr" sx={{ bgcolor: color.tableHeader }}>
                        {['', 'Account', 'Debit', 'Credit', 'Subledger'].map((h, i) => (
                          <Box component="th" key={h + i} sx={{ p: '6px 8px', textAlign: i === 2 || i === 3 ? 'right' : 'left', fontWeight: font.weight.bold, color: color.label, borderBottom: `1px solid ${color.borderStrong}` }}>{h}</Box>
                        ))}
                      </Box>
                    </thead>
                    <tbody>
                      {preview.lines.map((l: any) => (
                        <Box component="tr" key={l.id} sx={{ '&:hover': { bgcolor: color.primarySoft } }}>
                          <Box component="td" sx={{ ...td, fontWeight: font.weight.bold, color: color.label, width: 28 }}>{l.drCr}</Box>
                          <Box component="td" sx={td}>
                            <Typography sx={{ fontSize: font.size.table }}>{l.accountCode} {l.accountName}</Typography>
                            {l.ruleBranch && (
                              <Typography sx={{ fontSize: font.size.small, color: color.primary }}>branch: {l.ruleBranch}</Typography>
                            )}
                            {l.taxCode && <Typography sx={{ fontSize: font.size.small, color: color.muted }}>tax code {l.taxCode}</Typography>}
                          </Box>
                          <Box component="td" sx={tdNum}>{l.drCr === 'Dr' ? <Money value={l.amountFunc} decimals /> : ''}</Box>
                          <Box component="td" sx={tdNum}>{l.drCr === 'Cr' ? <Money value={l.amountFunc} decimals /> : ''}</Box>
                          <Box component="td" sx={{ ...td, fontSize: font.size.small, color: color.muted }}>{l.subledgerKey ?? '—'}</Box>
                        </Box>
                      ))}
                      <Box component="tr" sx={{ bgcolor: color.band }}>
                        <Box component="td" sx={td} />
                        <Box component="td" sx={{ ...td, fontWeight: font.weight.bold }}>TOTAL</Box>
                        <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={preview.totalDr} decimals bold /></Box>
                        <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={preview.totalCr} decimals bold /></Box>
                        <Box component="td" sx={td} />
                      </Box>
                    </tbody>
                  </Box>

                  <Alert severity={preview.balanced ? 'success' : 'error'} sx={{ mt: 1 }}>
                    {preview.balanced
                      ? 'Balanced in every currency and book. The document may be submitted.'
                      : `Out of balance by ₹${inr(Math.abs(preview.totalDr - preview.totalCr))}. An unbalanced document never reaches the ledger (VR-035).`}
                  </Alert>

                  <Typography variant="h2" sx={{ mt: 1.5, mb: 0.5 }}>What happens on approval</Typography>
                  <DefRow label="Series number">Allocated from {voucherCode}/2026-27 at posting</DefRow>
                  <DefRow label="Subledgers updated">{[...new Set(preview.lines.map((l: any) => l.subledgerKey).filter(Boolean))].join(', ') || 'None'}</DefRow>
                  <DefRow label="Books posted">{preview.rule.book}</DefRow>
                  <DefRow label="Immutability">Posted documents cannot be amended; correction is by reversal (HBIE-VCH-021)</DefRow>
                  <DefRow label="Retained">Rule code, version, branch taken and inputs evaluated (HBIE-ACC-061)</DefRow>
                </>
              ) : <Loading label="Computing posting" />}
            </Box>
          </Section>
        </Box>
      </Box>

      <Dialog open={confirm} onClose={() => setConfirm(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Submit voucher for approval</DialogTitle>
        <DialogContent>
          <DefRow label="Voucher type">{voucherCode} — {vt?.name}</DefRow>
          <DefRow label="Event">{EVENTS.find((e) => e.value === event)?.label}</DefRow>
          <DefRow label="Posting rule">{preview?.rule?.code} {preview?.rule?.version}</DefRow>
          <DefRow label="Total">₹{inr(preview?.totalDr ?? 0, { decimals: true })}</DefRow>
          <DefRow label="Approver">{vt?.approvalMatrix}</DefRow>
          <Alert severity="info" sx={{ mt: 1.5 }}>
            Preparer and approver must differ, and no user may approve at two levels of the same document (VR-045).
          </Alert>
          {submitError && <Alert severity="error" sx={{ mt: 1.5 }}>{submitError}</Alert>}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirm(false)} disabled={submitting}>Cancel</Button>
          <Button variant="outlined" onClick={() => submitVoucher(false)} disabled={submitting}>Park (submit for approval)</Button>
          {can('voucher:post') && (
            <Button variant="contained" onClick={() => submitVoucher(true)} disabled={submitting}>
              {submitting ? 'Working…' : 'Park & post'}
            </Button>
          )}
        </DialogActions>
      </Dialog>
      <Snackbar open={Boolean(toast)} autoHideDuration={7000} onClose={() => setToast(null)} message={toast} />
    </Box>
  );
}

/* ========================================================================== */
/*  VOUCHER DETAIL                                                            */
/* ========================================================================== */
export function VoucherDetail() {
  const { id } = useParams();
  const nav = useNavigate();
  const [tab, setTab] = React.useState('posting');
  const { can } = useAuth();
  const { data: v, isLoading, error, refetch } = useApi<any>(['voucher', id], `/vouchers/${id}`);
  const [posting, setPosting] = React.useState(false);
  const [postError, setPostError] = React.useState<string | null>(null);

  if (isLoading) return <Loading label="Loading voucher" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  if (!v) return null;

  const missingEvidence = v.evidence.filter((e: any) => e.mandatory && !e.attached);
  const canPost = can('voucher:post');

  const doPost = async () => {
    setPosting(true); setPostError(null);
    try { await post(`/vouchers/${id}/post`, {}); await refetch(); }
    catch (e: any) { setPostError(e.message ?? 'Post failed'); }
    finally { setPosting(false); }
  };
  const doReverse = async () => {
    setPosting(true); setPostError(null);
    try { const r = await reverseVoucher(id!); await refetch(); if (r?.reversedBy) nav(`/accounting/vouchers/${r.reversedBy}`); }
    catch (e: any) { setPostError(e.message ?? 'Reverse failed'); }
    finally { setPosting(false); }
  };

  return (
    <Box>
      <PageHeader
        onBack
        title={`${v.number}`}
        subtitle={`${v.voucherTypeName} · ${date(v.date)} · book ${v.book} · rule ${v.postingRule} ${v.postingRuleVersion}`}
        meta={<StatusChip status={v.status} />}
        actions={
          <>
            {v.status === 'posted' && (
              <Button onClick={doReverse} disabled={posting || !canPost} title={!canPost ? 'Requires posting permission' : 'Correct by reversal'}>
                {posting ? 'Reversing…' : 'Reverse'}
              </Button>
            )}
            {v.status === 'reversed' && <Chip label="Reversed" sx={{ bgcolor: color.band, color: color.muted }} />}
            {v.status !== 'posted' && (
              <Button
                variant="contained"
                disabled={missingEvidence.length > 0 || !canPost || posting}
                onClick={doPost}
                title={!canPost ? 'Your role does not permit posting (voucher:post)' : missingEvidence.length ? 'Attach mandatory evidence first' : undefined}
              >
                {posting ? 'Posting…' : 'Approve and post'}
              </Button>
            )}
            <Button onClick={() => openPrint(`/print/voucher/${id}`).catch((e) => setPostError(e.message))}>Print voucher</Button>
            <Button>Audit file</Button>
          </>
        }
      />
      {postError && (
        <Box sx={{ px: 2, pt: 1 }}>
          <Alert severity="error" onClose={() => setPostError(null)}>{postError}</Alert>
        </Box>
      )}

      <KpiStrip
        tiles={[
          { label: 'Total debit', value: `₹ ${inr(v.totalDr, { decimals: true })}` },
          { label: 'Total credit', value: `₹ ${inr(v.totalCr, { decimals: true })}` },
          { label: 'Balanced', value: Math.abs(v.totalDr - v.totalCr) < 0.01 ? 'Yes' : 'No', tone: Math.abs(v.totalDr - v.totalCr) < 0.01 ? 'success' : 'danger' },
          { label: 'Posting lines', value: v.lines.length },
          { label: 'Evidence', value: `${v.evidence.filter((e: any) => e.attached).length} / ${v.evidence.length}`, tone: missingEvidence.length ? 'warning' : 'default' },
          { label: 'Status', value: v.status },
        ]}
      />

      {missingEvidence.length > 0 && (
        <>
          <Band />
          <Box sx={{ p: 1.5, bgcolor: color.surface }}>
            <Alert severity="warning">
              <AlertTitle sx={{ fontSize: font.size.body, mb: 0.25 }}>Mandatory evidence missing — approval blocked</AlertTitle>
              <Typography sx={{ fontSize: font.size.label }}>
                {missingEvidence.map((e: any) => e.docType).join('; ')}. Attach the item, or record an authorised override which
                will appear in the override register for independent review (control C-19).
              </Typography>
            </Alert>
          </Box>
        </>
      )}

      <PillTabs
        value={tab} onChange={setTab}
        tabs={[
          { value: 'posting', label: 'Posting' },
          { value: 'evidence', label: 'Evidence', badge: missingEvidence.length, warn: missingEvidence.length > 0 },
          { value: 'rule', label: 'Posting rule' },
          { value: 'audit', label: 'Audit trail' },
        ]}
      />
      <Band />

      {tab === 'posting' && (
        <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
          <Typography sx={{ fontSize: font.size.body, mb: 1 }}><strong>Narration:</strong> {v.narration}</Typography>
          <Box component="table" sx={{ width: '100%', borderCollapse: 'collapse', fontSize: font.size.table }}>
            <thead>
              <Box component="tr" sx={{ bgcolor: color.tableHeader }}>
                {['', 'Account', 'Dimensions', 'Currency', 'Rate', 'Debit', 'Credit'].map((h, i) => (
                  <Box component="th" key={h + i} sx={{ p: '6px 8px', textAlign: i >= 5 ? 'right' : 'left', fontWeight: font.weight.bold, color: color.label, borderBottom: `1px solid ${color.borderStrong}` }}>{h}</Box>
                ))}
              </Box>
            </thead>
            <tbody>
              {v.lines.map((l: any) => (
                <Box component="tr" key={l.id} sx={{ '&:hover': { bgcolor: color.primarySoft } }}>
                  <Box component="td" sx={{ ...td, fontWeight: font.weight.bold, width: 28 }}>{l.drCr}</Box>
                  <Box component="td" sx={td}>
                    <Typography sx={{ fontSize: font.size.table }}>{l.accountCode} {l.accountName}</Typography>
                    {l.ruleBranch && <Typography sx={{ fontSize: font.size.small, color: color.primary }}>branch: {l.ruleBranch}</Typography>}
                  </Box>
                  <Box component="td" sx={{ ...td, fontSize: font.size.small, color: color.muted }}>
                    {Object.entries(l.dimensions).map(([k, val]) => `${k}: ${val}`).join(' · ')}
                  </Box>
                  <Box component="td" sx={td}>{l.currency}</Box>
                  <Box component="td" sx={tdNum}>{l.fxRate}</Box>
                  <Box component="td" sx={tdNum}>{l.drCr === 'Dr' ? <Money value={l.amountFunc} decimals /> : ''}</Box>
                  <Box component="td" sx={tdNum}>{l.drCr === 'Cr' ? <Money value={l.amountFunc} decimals /> : ''}</Box>
                </Box>
              ))}
              <Box component="tr" sx={{ bgcolor: color.band }}>
                <Box component="td" sx={td} colSpan={5}><Typography sx={{ fontWeight: font.weight.bold, fontSize: font.size.table }}>TOTAL</Typography></Box>
                <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={v.totalDr} decimals bold /></Box>
                <Box component="td" sx={{ ...tdNum, fontWeight: font.weight.bold }}><Money value={v.totalCr} decimals bold /></Box>
              </Box>
            </tbody>
          </Box>
        </Box>
      )}

      {tab === 'evidence' && (
        <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
          {v.evidence.map((e: any) => (
            <Stack key={e.id} direction="row" alignItems="center" spacing={1.25} sx={{ py: 0.75, borderBottom: `1px solid ${color.border}` }}>
              {e.attached ? <CheckCircleIcon sx={{ fontSize: 16, color: color.success }} /> : <RadioButtonUncheckedIcon sx={{ fontSize: 16, color: color.warning }} />}
              <Box sx={{ flex: 1 }}>
                <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold }}>{e.docType}</Typography>
                <Typography sx={{ fontSize: font.size.small, color: color.muted }}>
                  {e.attached ? `${e.name} · v${e.version}${e.issuer ? ` · ${e.issuer}` : ''}${e.ref ? ` · ${e.ref}` : ''}${e.date ? ` · ${date(e.date)}` : ''}${e.sizeKb ? ` · ${e.sizeKb} KB` : ''}` : 'Not attached'}
                </Typography>
              </Box>
              <Chip label={e.mandatory ? 'Mandatory' : 'Optional'} sx={{ bgcolor: e.mandatory ? color.band : 'transparent', color: color.label }} />
              <Button disabled={!e.attached}>Preview</Button>
            </Stack>
          ))}
          <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 1 }}>
            Evidence is immutable once the document is posted; a replacement creates a new version with the reason, and the
            superseded version remains retrievable (HBIE-DOC-032).
          </Typography>
        </Box>
      )}

      {tab === 'rule' && (
        <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
          {v.rule ? (
            <>
              <DefRow label="Rule code">{v.rule.code}</DefRow>
              <DefRow label="Version">{v.rule.version}</DefRow>
              <DefRow label="Effective from">{date(v.rule.effectiveFrom)}</DefRow>
              <DefRow label="Event">{v.rule.event}</DefRow>
              <DefRow label="Voucher type">{v.rule.voucherType}</DefRow>
              <DefRow label="Book">{v.rule.book}</DefRow>
              <DefRow label="Description">{v.rule.description}</DefRow>
              <DefRow label="Standard reference">{v.rule.standardRef ?? '—'}</DefRow>
              <Typography variant="h2" sx={{ mt: 1.5, mb: 0.5 }}>Rule definition</Typography>
              <Box component="pre" sx={{ fontFamily: font.mono, fontSize: 11, bgcolor: color.canvas, p: 1.25, border: `1px solid ${color.border}`, borderRadius: `${shape.radius}px`, overflow: 'auto' }}>
{JSON.stringify(v.rule.lines, null, 2)}
              </Box>
            </>
          ) : (
            <EmptyState
              title="Manual journal — no posting rule"
              detail="This voucher was posted as a manual journal. Manual journals are permitted only for events without a defined document type, require a reason and evidence, and are reported monthly as a control indicator (HBIE-ACC-004)."
            />
          )}
          {v.voucherTypeDef && (
            <>
              <Typography variant="h2" sx={{ mt: 2, mb: 0.5 }}>Voucher type configuration</Typography>
              <DefRow label="Statutory series">{v.voucherTypeDef.statutorySeries ? 'Yes — gapless' : 'No'}</DefRow>
              <DefRow label="Posts on">{v.voucherTypeDef.postsOn}</DefRow>
              <DefRow label="Reversible">{v.voucherTypeDef.reversible ? 'Yes' : 'No — correct by adjustment'}</DefRow>
              <DefRow label="Approval matrix">{v.voucherTypeDef.approvalMatrix}</DefRow>
              <DefRow label="Print format">{v.voucherTypeDef.printFormat}</DefRow>
              <DefRow label="Retention">{v.voucherTypeDef.retentionYears} years</DefRow>
              <DefRow label="Books">{v.voucherTypeDef.books.join(', ')}</DefRow>
            </>
          )}
        </Box>
      )}

      {tab === 'audit' && (
        <Box sx={{ bgcolor: color.surface, p: 1.5 }}>
          <DefRow label="Prepared by">{v.preparedBy}</DefRow>
          <DefRow label="Approved by">{v.approvedBy ?? '— pending'}</DefRow>
          <DefRow label="Posted at">{v.postedAt ? dateTime(v.postedAt) : '— not posted'}</DefRow>
          <DefRow label="Source">{v.sourceType ? `${v.sourceType} · ${v.sourceId}` : 'Manual'}</DefRow>
          <DefRow label="Reversal">{v.reversalOf ? `Reverses ${v.reversalOf}` : v.reversedBy ? `Reversed by ${v.reversedBy}` : 'Not reversed'}</DefRow>
          <DefRow label="Immutable">Yes — posted documents cannot be amended or deleted</DefRow>
          <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 1 }}>
            The full audit trail records every create, change, approval, override, determination and access, with user,
            timestamp, before and after values, retained for the statutory period and not modifiable by any role (HBIE-SEC-030).
          </Typography>
        </Box>
      )}
    </Box>
  );
}

const td = { p: '5px 8px', borderBottom: `1px solid ${color.border}`, verticalAlign: 'top' } as const;
const tdNum = { ...td, textAlign: 'right', fontVariantNumeric: 'tabular-nums' } as const;
