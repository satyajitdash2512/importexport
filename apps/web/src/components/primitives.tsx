import * as React from 'react';
import {
  Box, Stack, Typography, Chip, Tooltip, Paper, Button, Menu, MenuItem, IconButton,
  CircularProgress, Alert, AlertTitle, LinearProgress, Divider, Tabs, Tab,
} from '@mui/material';
import ArrowBackIosNewIcon from '@mui/icons-material/ArrowBackIosNew';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import RadioButtonUncheckedIcon from '@mui/icons-material/RadioButtonUnchecked';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import InboxIcon from '@mui/icons-material/Inbox';
import { useNavigate } from 'react-router-dom';
import { color, font, shape, severity as sevTokens, type SeverityKey } from '../context/tokens';
import { inr, money, relativeDeadline, date } from '../utils/format';

/* ========================================================================== */
/*  BAND  —  the light blue-grey separator strip between content blocks        */
/* ========================================================================== */
export const Band = ({ height = 10 }: { height?: number }) => (
  <Box sx={{ height, bgcolor: color.band, flex: '0 0 auto' }} aria-hidden />
);

/* ========================================================================== */
/*  PAGE HEADER  —  back chevron · blue title · right-aligned actions          */
/* ========================================================================== */
export function PageHeader({
  title, subtitle, onBack, actions, newMenu, meta,
}: {
  title: string; subtitle?: React.ReactNode; onBack?: boolean;
  actions?: React.ReactNode; newMenu?: { label: string; onClick?: () => void }[];
  meta?: React.ReactNode;
}) {
  const nav = useNavigate();
  const [anchor, setAnchor] = React.useState<null | HTMLElement>(null);
  return (
    <Box sx={{ bgcolor: color.surface, px: 1.5, pt: 1, pb: 1 }}>
      <Stack direction="row" alignItems="flex-start" spacing={1}>
        {onBack && (
          <IconButton aria-label="Back" onClick={() => nav(-1)} sx={{ mt: 0.1, color: color.primary }}>
            <ArrowBackIosNewIcon sx={{ fontSize: 14 }} />
          </IconButton>
        )}
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography variant="h1" component="h1" noWrap={false}>{title}</Typography>
          {subtitle && (
            <Typography sx={{ fontSize: font.size.label, color: color.muted, mt: 0.25 }}>{subtitle}</Typography>
          )}
        </Box>
        <Stack direction="row" spacing={0.75} alignItems="center" sx={{ flexShrink: 0 }}>
          {meta}
          {actions}
          {newMenu && (
            <>
              <Button endIcon={<KeyboardArrowDownIcon sx={{ fontSize: 16 }} />} onClick={(e) => setAnchor(e.currentTarget)}>
                New
              </Button>
              <Menu anchorEl={anchor} open={Boolean(anchor)} onClose={() => setAnchor(null)}>
                {newMenu.map((m) => (
                  <MenuItem key={m.label} onClick={() => { setAnchor(null); m.onClick?.(); }}>{m.label}</MenuItem>
                ))}
              </Menu>
            </>
          )}
        </Stack>
      </Stack>
    </Box>
  );
}

/* ========================================================================== */
/*  KPI STRIP  —  equal-width filled blue tiles, label over value              */
/* ========================================================================== */
export interface KpiTileDef {
  label: string; value: string | number; sub?: string;
  tone?: 'default' | 'danger' | 'warning' | 'success'; onClick?: () => void; ariaLabel?: string;
}

export function KpiStrip({ tiles }: { tiles: KpiTileDef[] }) {
  const bg = (tone?: string) =>
    tone === 'danger' ? color.danger : tone === 'warning' ? color.warning : tone === 'success' ? color.success : color.primaryTile;
  return (
    <Box sx={{ display: 'grid', gridTemplateColumns: `repeat(${tiles.length}, minmax(0, 1fr))`, gap: 1, px: 1.5, py: 1, bgcolor: color.surface }}>
      {tiles.map((t) => (
        <Box
          key={t.label}
          component={t.onClick ? 'button' : 'div'}
          onClick={t.onClick}
          aria-label={t.ariaLabel ?? `${t.label}: ${t.value}`}
          sx={{
            bgcolor: bg(t.tone), color: color.onPrimary, borderRadius: `${shape.radius}px`,
            px: 1.5, py: 1, textAlign: 'center', border: 'none', minWidth: 0,
            cursor: t.onClick ? 'pointer' : 'default', font: 'inherit',
            '&:hover': t.onClick ? { filter: 'brightness(0.94)' } : undefined,
          }}
        >
          <Typography sx={{ fontSize: font.size.tileLabel, fontWeight: font.weight.medium, opacity: 0.95 }} noWrap>
            {t.label}
          </Typography>
          <Typography sx={{ fontSize: font.size.tileValue, fontWeight: font.weight.semibold, lineHeight: 1.25 }} noWrap>
            {t.value}
          </Typography>
          {t.sub && <Typography sx={{ fontSize: font.size.small, opacity: 0.9 }} noWrap>{t.sub}</Typography>}
        </Box>
      ))}
    </Box>
  );
}

/* ========================================================================== */
/*  PILL TABS                                                                  */
/* ========================================================================== */
export function PillTabs({
  value, onChange, tabs,
}: { value: string; onChange: (v: string) => void; tabs: { value: string; label: string; badge?: number; warn?: boolean }[] }) {
  return (
    <Box sx={{ bgcolor: color.surface, px: 1 }}>
      <Tabs value={value} onChange={(_, v) => onChange(v)} variant="scrollable" scrollButtons="auto" allowScrollButtonsMobile>
        {tabs.map((t) => (
          <Tab
            key={t.value}
            value={t.value}
            label={
              <Stack direction="row" spacing={0.5} alignItems="center">
                <span>{t.label}</span>
                {t.badge !== undefined && t.badge > 0 && (
                  <Box
                    component="span"
                    sx={{
                      fontSize: font.size.small, fontWeight: font.weight.bold, px: 0.5, borderRadius: '3px',
                      bgcolor: t.warn ? color.dangerSoft : color.band, color: t.warn ? color.danger : color.muted,
                    }}
                  >
                    {t.badge}
                  </Box>
                )}
              </Stack>
            }
          />
        ))}
      </Tabs>
    </Box>
  );
}

/* ========================================================================== */
/*  FIELD GRID  —  four-column "Label:" bold + value                          */
/* ========================================================================== */
export interface FieldDef { label: string; value?: React.ReactNode; span?: number; verified?: boolean }

export function FieldGrid({ fields, columns = 4, dense }: { fields: FieldDef[]; columns?: number; dense?: boolean }) {
  return (
    <Box
      sx={{
        display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)', md: `repeat(${columns}, 1fr)` },
        columnGap: 2, rowGap: dense ? 1 : 1.5, px: 1.5, py: dense ? 1 : 1.5, bgcolor: color.surface,
      }}
    >
      {fields.map((f, i) => (
        <Box key={`${f.label}-${i}`} sx={{ gridColumn: f.span ? `span ${f.span}` : undefined, minWidth: 0 }}>
          <Typography component="span" sx={{ fontSize: font.size.label, fontWeight: font.weight.bold, color: color.label }}>
            {f.label}:
          </Typography>{' '}
          <Typography component="span" sx={{ fontSize: font.size.body, color: color.text, wordBreak: 'break-word' }}>
            {f.value ?? ''}
          </Typography>
          {f.verified && (
            <Stack component="span" direction="row" spacing={0.25} alignItems="center" sx={{ display: 'inline-flex', ml: 0.75, verticalAlign: 'middle' }}>
              <CheckCircleIcon sx={{ fontSize: 13, color: color.success }} />
              <Typography component="span" sx={{ fontSize: font.size.small, color: color.success, fontWeight: font.weight.semibold }}>Verified</Typography>
            </Stack>
          )}
        </Box>
      ))}
    </Box>
  );
}

/* ========================================================================== */
/*  SECTION  —  plain title on white with a band above                        */
/* ========================================================================== */
export function Section({
  title, actions, children, noBand, dense,
}: { title?: string; actions?: React.ReactNode; children: React.ReactNode; noBand?: boolean; dense?: boolean }) {
  return (
    <>
      {!noBand && <Band />}
      <Box sx={{ bgcolor: color.surface }}>
        {title && (
          <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ px: 1.5, pt: dense ? 1 : 1.25, pb: 0.5 }}>
            <Typography variant="h2" component="h2">{title}</Typography>
            {actions && <Stack direction="row" spacing={0.75}>{actions}</Stack>}
          </Stack>
        )}
        {children}
      </Box>
    </>
  );
}

/* ========================================================================== */
/*  STATUS + SEVERITY + DEADLINE indicators                                   */
/* ========================================================================== */
const STATUS_TONE: Record<string, 'default' | 'success' | 'warning' | 'danger' | 'info'> = {
  posted: 'success', complete: 'success', cleared: 'success', matched: 'success', reconciled: 'success',
  clean: 'success', approved: 'success', realised: 'success',
  parked: 'warning', pendingapproval: 'warning', inprogress: 'warning', underassessment: 'warning',
  underclearance: 'warning', exceptions: 'warning', 'shortreceived': 'warning',
  blocked: 'danger', critical: 'danger', reversed: 'danger', cancelled: 'danger', rejected: 'danger',
  overdue: 'danger', discrepant: 'danger',
};

export function StatusChip({ status, size = 'small' }: { status: string; size?: 'small' | 'medium' }) {
  const key = status.toLowerCase().replace(/[^a-z]/g, '');
  const tone = STATUS_TONE[key] ?? 'default';
  const map = {
    success: { bg: color.successSoft, fg: color.success },
    warning: { bg: color.warningSoft, fg: color.warning },
    danger: { bg: color.dangerSoft, fg: color.danger },
    info: { bg: color.infoSoft, fg: color.primary },
    default: { bg: color.band, fg: color.label },
  }[tone];
  return (
    <Chip
      size={size}
      label={status}
      sx={{ bgcolor: map.bg, color: map.fg, border: `1px solid ${map.fg}22`, fontWeight: font.weight.semibold }}
    />
  );
}

const SEV_ICON: Record<SeverityKey, React.ReactElement> = {
  critical: <ErrorIcon sx={{ fontSize: 14 }} />,
  high: <WarningAmberIcon sx={{ fontSize: 14 }} />,
  medium: <InfoOutlinedIcon sx={{ fontSize: 14 }} />,
  info: <RadioButtonUncheckedIcon sx={{ fontSize: 14 }} />,
};

/** Severity is conveyed by icon shape + text + colour, never colour alone (WCAG). */
export function SeverityChip({ severity, showLabel = true }: { severity: SeverityKey; showLabel?: boolean }) {
  const t = sevTokens[severity];
  return (
    <Chip
      icon={SEV_ICON[severity]}
      label={showLabel ? t.label : ''}
      sx={{
        bgcolor: t.bg, color: t.fg, border: `1px solid ${t.fg}33`,
        '& .MuiChip-icon': { color: t.fg, marginLeft: '4px', marginRight: showLabel ? '-2px' : '4px' },
        ...(showLabel ? {} : { width: 22, '& .MuiChip-label': { display: 'none' } }),
      }}
    />
  );
}

export function DeadlineChip({ iso, label }: { iso?: string | null; label?: string }) {
  const rel = relativeDeadline(iso);
  const overdue = rel.includes('overdue');
  const urgent = rel === 'today' || rel === 'tomorrow' || /^[0-2] days$/.test(rel);
  const tone = overdue ? { bg: color.dangerSoft, fg: color.danger, mark: '!' }
    : urgent ? { bg: color.warningSoft, fg: color.warning, mark: '▲' }
    : { bg: color.band, fg: color.label, mark: '' };
  return (
    <Tooltip title={`${label ? label + ' — ' : ''}${date(iso)}`}>
      <Chip
        label={`${tone.mark ? tone.mark + ' ' : ''}${date(iso)} · ${rel}`}
        sx={{ bgcolor: tone.bg, color: tone.fg, border: `1px solid ${tone.fg}33`, fontWeight: font.weight.semibold }}
      />
    </Tooltip>
  );
}

/* ========================================================================== */
/*  MONEY / QUANTITY cells                                                     */
/* ========================================================================== */
export function Money({
  value, currency = 'INR', decimals, bold, variance, funcValue,
}: { value?: number | null; currency?: string; decimals?: boolean; bold?: boolean; variance?: boolean; funcValue?: number }) {
  const v = value ?? null;
  const tone = variance && v !== null ? (v > 0 ? color.varianceUp : v < 0 ? color.varianceDown : color.text) : color.text;
  const text = money(v, currency, decimals);
  const body = (
    <Typography
      component="span"
      sx={{
        fontVariantNumeric: 'tabular-nums', fontSize: 'inherit', color: tone,
        fontWeight: bold ? font.weight.semibold : font.weight.regular,
      }}
    >
      {variance && v !== null && v > 0 ? '+' : ''}{text}
    </Typography>
  );
  if (funcValue !== undefined && currency !== 'INR') {
    return <Tooltip title={`₹ ${inr(funcValue)} at the recorded rate`}>{body}</Tooltip>;
  }
  return body;
}

/* ========================================================================== */
/*  COMPUTATION TREE  —  show the working (design principle 4)                 */
/* ========================================================================== */
export interface ComputationStep {
  label: string; detail?: string; amount?: number; currency?: string;
  emphasis?: boolean; note?: string; children?: ComputationStep[];
}

export function ComputationTree({ steps, currency = 'INR' }: { steps: ComputationStep[]; currency?: string }) {
  return (
    <Box sx={{ fontFamily: font.family }}>
      {steps.map((s, i) => <Row key={i} step={s} depth={0} currency={currency} />)}
    </Box>
  );
}

function Row({ step, depth, currency }: { step: ComputationStep; depth: number; currency: string }) {
  const [open, setOpen] = React.useState(true);
  const hasKids = Boolean(step.children?.length);
  return (
    <>
      <Stack
        direction="row" alignItems="baseline" spacing={1}
        sx={{
          px: 1.5, py: 0.4, pl: 1.5 + depth * 2, borderBottom: `1px solid ${color.border}`,
          bgcolor: step.emphasis ? color.primarySoft : undefined,
        }}
      >
        {hasKids ? (
          <IconButton aria-label={open ? 'Collapse' : 'Expand'} onClick={() => setOpen(!open)} sx={{ p: 0, mr: -0.5 }}>
            {open ? <ExpandMoreIcon sx={{ fontSize: 15 }} /> : <ChevronRightIcon sx={{ fontSize: 15 }} />}
          </IconButton>
        ) : <Box sx={{ width: 11 }} />}
        <Typography sx={{ fontSize: font.size.body, fontWeight: step.emphasis ? font.weight.semibold : font.weight.regular, flex: 1, minWidth: 0 }}>
          {step.label}
          {step.detail && <Typography component="span" sx={{ fontSize: font.size.small, color: color.muted, ml: 0.75 }}>{step.detail}</Typography>}
        </Typography>
        {step.note && (
          <Typography sx={{ fontSize: font.size.small, color: color.warning, fontWeight: font.weight.semibold, whiteSpace: 'nowrap' }}>
            {step.note}
          </Typography>
        )}
        <Box sx={{ minWidth: 116, textAlign: 'right', fontSize: font.size.body }}>
          {step.amount !== undefined && <Money value={step.amount} currency={step.currency ?? currency} decimals bold={step.emphasis} />}
        </Box>
      </Stack>
      {hasKids && open && step.children!.map((c, i) => <Row key={i} step={c} depth={depth + 1} currency={currency} />)}
    </>
  );
}

/* ========================================================================== */
/*  STATE components                                                           */
/* ========================================================================== */
export function Loading({ label = 'Loading' }: { label?: string }) {
  return (
    <Stack alignItems="center" justifyContent="center" spacing={1} sx={{ py: 5, bgcolor: color.surface }}>
      <CircularProgress size={22} />
      <Typography sx={{ fontSize: font.size.label, color: color.muted }}>{label}…</Typography>
    </Stack>
  );
}

export function ErrorState({ error, onRetry }: { error: unknown; onRetry?: () => void }) {
  const message = error instanceof Error ? error.message : String(error);
  return (
    <Box sx={{ p: 1.5, bgcolor: color.surface }}>
      <Alert
        severity="error"
        action={onRetry ? <Button onClick={onRetry} color="inherit">Retry</Button> : undefined}
      >
        <AlertTitle sx={{ fontSize: font.size.body, mb: 0 }}>Could not load this content</AlertTitle>
        <Typography sx={{ fontSize: font.size.label }}>{message}</Typography>
        <Typography sx={{ fontSize: font.size.small, mt: 0.5 }}>
          Your entered data has not been lost. The API may not be running — start it with <code>npm run dev:api</code>.
        </Typography>
      </Alert>
    </Box>
  );
}

export function EmptyState({ title, detail, action }: { title: string; detail?: string; action?: React.ReactNode }) {
  return (
    <Stack alignItems="center" spacing={1} sx={{ py: 5, px: 2, bgcolor: color.surface, textAlign: 'center' }}>
      <InboxIcon sx={{ fontSize: 28, color: color.borderStrong }} />
      <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold }}>{title}</Typography>
      {detail && <Typography sx={{ fontSize: font.size.label, color: color.muted, maxWidth: 460 }}>{detail}</Typography>}
      {action}
    </Stack>
  );
}

/* ========================================================================== */
/*  PROGRESS BAR with label                                                    */
/* ========================================================================== */
export function LabelledProgress({
  value, label, right, tone = 'primary',
}: { value: number; label?: string; right?: React.ReactNode; tone?: 'primary' | 'success' | 'warning' | 'danger' }) {
  const barColor = tone === 'danger' ? color.danger : tone === 'warning' ? color.warning : tone === 'success' ? color.success : color.primaryTile;
  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="baseline" sx={{ mb: 0.4 }}>
        {label && <Typography sx={{ fontSize: font.size.label, color: color.label, fontWeight: font.weight.semibold }}>{label}</Typography>}
        {right}
      </Stack>
      <LinearProgress
        variant="determinate"
        value={Math.min(Math.max(value, 0), 100)}
        aria-label={label}
        sx={{ '& .MuiLinearProgress-bar': { backgroundColor: barColor } }}
      />
    </Box>
  );
}

/* ========================================================================== */
/*  DEFINITION ROW  —  compact label/value inside cards                        */
/* ========================================================================== */
export function DefRow({ label, children, tone }: { label: string; children: React.ReactNode; tone?: string }) {
  return (
    <Stack direction="row" spacing={1} sx={{ py: 0.35, borderBottom: `1px solid ${color.border}` }}>
      <Typography sx={{ fontSize: font.size.label, fontWeight: font.weight.bold, color: color.label, minWidth: 150 }}>{label}</Typography>
      <Box sx={{ fontSize: font.size.body, color: tone ?? color.text, flex: 1, minWidth: 0 }}>{children}</Box>
    </Stack>
  );
}

export { Divider, Paper };
