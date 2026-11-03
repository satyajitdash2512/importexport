import * as React from 'react';
import {
  Box, Stack, Typography, Button, Chip, Alert, IconButton, Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions, Tooltip, Snackbar,
} from '@mui/material';
import EditOutlinedIcon from '@mui/icons-material/EditOutlined';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import FormatListBulletedIcon from '@mui/icons-material/FormatListBulleted';
import { useNavigate } from 'react-router-dom';
import { color, font } from '../../../context/tokens';
import { useApi } from '../../../lib/api';
import { inr, date, pct, qty } from '../../../utils/format';
import {
  Band, PageHeader, Section, KpiStrip, StatusChip, SeverityChip, Loading, ErrorState, Money,
  DefRow, EmptyState, FieldGrid,
} from '../../../components/primitives';
import { DataTable, type GridColDef } from '../../../components/DataTable';
import { ServerDataTable } from '../../../components/ServerDataTable';
import type { ScreenSpec } from '../../../config/screenRegistry';
import { PATH_RESOURCE, RESOURCE_PERM, CRUD_FIELDS, CHILD_COLLECTIONS } from '../../../config/crudRegistry';
import { CrudForm } from '../../accounting/components/CrudForm';
import { LinesEditor } from '../../accounting/components/LinesEditor';
import { deleteRow } from '../../../lib/crud';
import { useAuth } from '../../../context/AuthContext';

/**
 * Registry-driven screen. Renders a list (and optional summary tiles, notes and
 * field panels) from a declarative spec, so the whole screen inventory is
 * covered from shared patterns rather than one bespoke component per screen
 * (RD 19.4 — four layout patterns cover every screen).
 */
export function GenericScreen({ spec }: { spec: ScreenSpec }) {
  const nav = useNavigate();
  const { can } = useAuth();
  const { data, isLoading, error, refetch } = useApi<any>(
    ['generic', spec.path, spec.endpoint ?? 'static'],
    spec.endpoint ?? '/health',
    { enabled: !spec.serverPaged },
  );
  // server-paged screens fetch inside ServerDataTable; bump this to force a reload
  const [serverRefresh, setServerRefresh] = React.useState(0);

  // CRUD wiring: a screen is editable when its path maps to a resource that has
  // field specs, and the user holds the write permission for it.
  const resource = PATH_RESOURCE[spec.path];
  const writable = !!resource && !!CRUD_FIELDS[resource];
  const permBase = (resource && RESOURCE_PERM[resource]) || resource;
  const canWrite = writable && can(`${permBase}:write`);
  const childSpec = resource ? CHILD_COLLECTIONS[resource] : undefined;
  const [form, setForm] = React.useState<{ mode: 'create' | 'edit'; id?: string } | null>(null);
  const [linesFor, setLinesFor] = React.useState<any | null>(null);
  const [confirmDel, setConfirmDel] = React.useState<any | null>(null);
  const [busy, setBusy] = React.useState(false);
  const [toast, setToast] = React.useState<string | null>(null);

  const doDelete = async () => {
    if (!confirmDel) return;
    setBusy(true);
    try { await deleteRow(resource!, confirmDel.id); setToast('Deleted'); setConfirmDel(null); refetch(); setServerRefresh((n) => n + 1); }
    catch (e: any) { setToast(e.message ?? 'Delete failed'); }
    finally { setBusy(false); }
  };

  const rows: any[] = React.useMemo(() => {
    const raw = spec.rows ?? (data ? (spec.pick ? spec.pick(data) : data) : []);
    if (!Array.isArray(raw)) return [];
    // The grid requires a unique id on every row. Some resources are keyed by a
    // natural key (account code, voucher type code) rather than by `id`.
    return raw.map((r: any, i: number) => (
      r?.id !== undefined ? r : { ...r, id: r?.code ?? r?.number ?? r?.ref ?? `row-${i}` }
    ));
  }, [data, spec]);

  if (spec.endpoint && isLoading) return <Loading label={`Loading ${spec.title.toLowerCase()}`} />;
  if (spec.endpoint && error) return <ErrorState error={error} onRetry={refetch} />;

  // tiles are derived from the full row set; suppress them under server paging,
  // where only one page is in memory and page-based counts would mislead.
  const tiles = spec.tiles && !spec.serverPaged ? spec.tiles(rows, data) : undefined;

  return (
    <Box>
      <PageHeader
        title={spec.title}
        subtitle={spec.subtitle}
        actions={
          <>
            {spec.actions?.map((a) => {
              const isPrimary = a === spec.primaryAction;
              // Every action responds to a click — a button is never a silent,
              // greyed-out dead control. The primary "New …" action opens the
              // create form when the screen is writable and the user holds the
              // permission; otherwise it explains, in a toast, exactly why not.
              const onClick = () => {
                if (!isPrimary) {
                  setToast(/export/i.test(a)
                    ? 'Use the Export button on the table toolbar below to download this list.'
                    : `“${a}” isn’t wired to a backend action in this build.`);
                  return;
                }
                if (canWrite) { setForm({ mode: 'create' }); return; }
                if (spec.newRoute) { nav(spec.newRoute); return; }
                if (resource) {
                  setToast(`Creating a record here needs the “${permBase}:write” permission. Sign in as “controller” (or another business role that has it) — the “${a}” form will then open.`);
                  return;
                }
                setToast(`“${spec.title}” shows sample data in this build and isn’t backed by the database yet, so “${a}” has nothing to save to. Tell me if you’d like this screen wired to full create/edit/delete.`);
              };
              return (
                <Button key={a} variant={isPrimary ? 'contained' : 'outlined'} onClick={onClick}>{a}</Button>
              );
            })}
          </>
        }
        meta={spec.rdRef ? <Chip label={spec.rdRef} sx={{ bgcolor: color.band, color: color.label }} /> : undefined}
      />

      {tiles && tiles.length > 0 && <KpiStrip tiles={tiles} />}

      {spec.note && (
        <>
          <Band />
          <Box sx={{ p: 1.5, bgcolor: color.surface }}>
            <Alert severity={spec.noteSeverity ?? 'info'}>
              <Typography sx={{ fontSize: font.size.label }}>{spec.note}</Typography>
            </Alert>
          </Box>
        </>
      )}

      {spec.fields && (
        <Section title={spec.fieldsTitle ?? 'Details'}>
          <FieldGrid fields={spec.fields} columns={4} />
        </Section>
      )}

      <Band />
      {spec.serverPaged ? (
        <ServerDataTable
          endpoint={spec.endpoint!}
          columns={[
            ...(canWrite ? [actionsColumn(
              (row: any) => setForm({ mode: 'edit', id: String(row.id) }),
              (row: any) => setConfirmDel(row),
              childSpec ? (row: any) => setLinesFor(row) : undefined,
              childSpec?.label,
            )] : []),
            ...spec.columns.map((c) => materialise(c, nav)),
          ]}
          searchable={!!spec.searchFields?.length}
          searchPlaceholder={`Search ${spec.title.toLowerCase()}`}
          onRowClick={spec.rowRoute ? (r: any) => nav(spec.rowRoute!(r)) : undefined}
          rowClassName={spec.rowClassName}
          initialPageSize={spec.pageSize ?? 50}
          refreshKey={serverRefresh}
        />
      ) : rows.length === 0 ? (
        <EmptyState
          title={spec.emptyTitle ?? 'Nothing to show yet'}
          detail={spec.emptyDetail ?? 'Records appear here as they are created. This screen is wired to the same design system and API as the rest of the module.'}
          action={spec.newRoute ? <Button variant="contained" onClick={() => nav(spec.newRoute!)}>Create</Button> : undefined}
        />
      ) : (
        <DataTable
          rows={rows}
          columns={[
            ...(canWrite ? [actionsColumn(
              (row: any) => setForm({ mode: 'edit', id: String(row.id) }),
              (row: any) => setConfirmDel(row),
              childSpec ? (row: any) => setLinesFor(row) : undefined,
              childSpec?.label,
            )] : []),
            ...spec.columns.map((c) => materialise(c, nav)),
          ]}
          searchFields={spec.searchFields as any}
          exportName={spec.path.replace(/\//g, '-').slice(1)}
          onRowClick={spec.rowRoute ? (r: any) => nav(spec.rowRoute!(r)) : undefined}
          rowClassName={spec.rowClassName}
          initialPageSize={spec.pageSize ?? 25}
        />
      )}

      {form && writable && (
        <CrudForm
          resource={resource!}
          mode={form.mode}
          id={form.id}
          title={spec.title.replace(/s$/, '')}
          onClose={() => setForm(null)}
          onSaved={() => { setToast(form.mode === 'create' ? 'Created' : 'Saved'); refetch(); setServerRefresh((n) => n + 1); }}
        />
      )}

      {linesFor && childSpec && (
        <LinesEditor
          resource={resource!}
          parentId={String(linesFor.id)}
          parentLabel={linesFor.number || linesFor.name || linesFor.code || String(linesFor.id)}
          onClose={() => setLinesFor(null)}
          onSaved={() => { setToast('Lines saved'); refetch(); setServerRefresh((n) => n + 1); }}
        />
      )}

      <Dialog open={!!confirmDel} onClose={() => setConfirmDel(null)}>
        <DialogTitle>Delete this record?</DialogTitle>
        <DialogContent>
          <DialogContentText sx={{ fontSize: font.size.body }}>
            {confirmDel?.name || confirmDel?.number || confirmDel?.code || confirmDel?.id} will be permanently removed. This cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmDel(null)} disabled={busy}>Cancel</Button>
          <Button color="error" variant="contained" onClick={doDelete} disabled={busy}>Delete</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={!!toast} autoHideDuration={3000} onClose={() => setToast(null)} message={toast ?? ''} anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }} />

      {spec.footnote && (
        <>
          <Band />
          <Box sx={{ px: 1.5, py: 1.25, bgcolor: color.surface }}>
            <Typography sx={{ fontSize: font.size.small, color: color.muted }}>{spec.footnote}</Typography>
          </Box>
        </>
      )}
    </Box>
  );
}

/** A trailing Edit / Delete (and optional line-editor) column when writable. */
function actionsColumn(onEdit: (row: any) => void, onDelete: (row: any) => void, onLines?: (row: any) => void, linesLabel?: string): GridColDef {
  return {
    field: '__actions', headerName: '', width: onLines ? 100 : 72, sortable: false, filterable: false, align: 'center', headerAlign: 'center',
    renderCell: (p) => (
      <Stack direction="row" spacing={0.25}>
        <Tooltip title="Edit"><IconButton size="small" aria-label="Edit" onClick={(e) => { e.stopPropagation(); onEdit(p.row); }}><EditOutlinedIcon sx={{ fontSize: 16 }} /></IconButton></Tooltip>
        {onLines && <Tooltip title={linesLabel ?? 'Edit lines'}><IconButton size="small" aria-label="Edit lines" onClick={(e) => { e.stopPropagation(); onLines(p.row); }}><FormatListBulletedIcon sx={{ fontSize: 16, color: color.primary }} /></IconButton></Tooltip>}
        <Tooltip title="Delete"><IconButton size="small" aria-label="Delete" onClick={(e) => { e.stopPropagation(); onDelete(p.row); }}><DeleteOutlineIcon sx={{ fontSize: 16, color: color.danger }} /></IconButton></Tooltip>
      </Stack>
    ),
  };
}

/** Turn a compact column spec into a MUI DataGrid column with the right renderer. */
function materialise(c: any, nav: (to: string) => void): GridColDef {
  const base: GridColDef = { field: c.field, headerName: c.header, width: c.width, flex: c.flex, minWidth: c.minWidth };
  switch (c.kind) {
    case 'money':
      return { ...base, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value ?? null} currency={c.currencyField ? p.row[c.currencyField] : 'INR'} /> };
    case 'variance':
      return { ...base, align: 'right', headerAlign: 'right', renderCell: (p) => <Money value={p.value ?? null} variance /> };
    case 'number':
      return { ...base, align: 'right', headerAlign: 'right', renderCell: (p) => (p.value === undefined || p.value === null ? '—' : Number(p.value).toLocaleString('en-IN')) };
    case 'qty':
      return { ...base, align: 'right', headerAlign: 'right', renderCell: (p) => qty(p.value, c.unit ?? p.row[c.unitField ?? '']) };
    case 'pct':
      return { ...base, align: 'right', headerAlign: 'right', renderCell: (p) => pct(p.value, c.dp ?? 1) };
    case 'date':
      return { ...base, renderCell: (p) => date(p.value) };
    case 'status':
      return { ...base, renderCell: (p) => (p.value ? <StatusChip status={String(p.value)} /> : '—') };
    case 'severity':
      return { ...base, renderCell: (p) => (p.value ? <SeverityChip severity={p.value} /> : '—') };
    case 'chip':
      return { ...base, renderCell: (p) => (p.value ? <Chip label={String(p.value)} sx={{ bgcolor: color.band, color: color.label }} /> : '—') };
    case 'bool':
      return { ...base, renderCell: (p) => (p.value ? <Typography sx={{ fontSize: 'inherit', color: color.success }}>Yes</Typography> : <Typography sx={{ fontSize: 'inherit', color: color.muted }}>No</Typography>) };
    case 'link':
      return { ...base, renderCell: (p) => <Button variant="text" size="small" onClick={(e) => { e.stopPropagation(); nav(c.to(p.row)); }}>{p.value}</Button> };
    case 'list':
      return { ...base, renderCell: (p) => (Array.isArray(p.value) ? p.value.join(', ') : String(p.value ?? '—')) };
    default:
      return { ...base, renderCell: (p) => (p.value === undefined || p.value === null || p.value === '' ? '—' : String(p.value)) };
  }
}
