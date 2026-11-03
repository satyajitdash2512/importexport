import * as React from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Box, Stack, Typography, TextField, MenuItem, Button, IconButton, Alert, Checkbox, CircularProgress, Table, TableHead, TableRow, TableCell, TableBody, Tooltip,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import { color, font } from '../../../context/tokens';
import { get } from '../../../lib/api';
import { getChildren, replaceChildren } from '../../../lib/crud';
import { CHILD_COLLECTIONS, type CrudField } from '../../../config/crudRegistry';

interface Props {
  resource: string;
  parentId: string;         // public id (O-001, CS-001 …)
  parentLabel: string;
  onClose: () => void;
  onSaved: () => void;
}

/** Edit a document's child rows in place (order lines, cost lines, blocks …). */
export function LinesEditor({ resource, parentId, parentLabel, onClose, onSaved }: Props) {
  const spec = CHILD_COLLECTIONS[resource];
  const [rows, setRows] = React.useState<any[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [saving, setSaving] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [dynOptions, setDynOptions] = React.useState<Record<string, { value: any; label: string }[]>>({});

  React.useEffect(() => {
    let live = true;
    getChildren(resource, parentId, spec.child)
      .then((r) => { if (live) { setRows(r.map((x) => ({ ...x }))); setLoading(false); } })
      .catch((e) => { setError(e.message); setLoading(false); });
    // load any dynamic option lists
    spec.fields.filter((f) => f.optionsFrom).forEach(async (f) => {
      try { const opts = await get<any[]>(f.optionsFrom!.endpoint); if (live) setDynOptions((o) => ({ ...o, [f.name]: opts.map((r) => ({ value: r[f.optionsFrom!.value], label: String(r[f.optionsFrom!.label]) })) })); } catch { /* */ }
    });
    return () => { live = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resource, parentId]);

  const setCell = (i: number, name: string, v: any) => setRows((rs) => rs.map((r, idx) => (idx === i ? { ...r, [name]: v } : r)));
  const addRow = () => setRows((rs) => [...rs, Object.fromEntries(spec.fields.map((f) => [f.name, f.type === 'bool' ? 0 : '']))]);
  const removeRow = (i: number) => setRows((rs) => rs.filter((_, idx) => idx !== i));

  const optionsFor = (f: CrudField) => f.options ?? dynOptions[f.name] ?? [];

  const save = async () => {
    setSaving(true); setError(null);
    try {
      const payload = rows.map((r) => {
        const o: any = {};
        for (const f of spec.fields) {
          let v = r[f.name];
          if (f.type === 'bool') v = v ? 1 : 0;
          else if (f.type === 'number' && v !== '' && v != null) v = Number(v);
          o[f.name] = v;
        }
        return o;
      });
      await replaceChildren(resource, parentId, spec.child, payload);
      onSaved(); onClose();
    } catch (e: any) { setError(e.message ?? 'Save failed'); } finally { setSaving(false); }
  };

  return (
    <Dialog open onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle sx={{ fontSize: font.size.pageTitle, fontWeight: font.weight.bold }}>
        {spec.label} · {parentLabel}
      </DialogTitle>
      <DialogContent>
        {error && <Alert severity="error" sx={{ mb: 1.5 }} onClose={() => setError(null)}>{error}</Alert>}
        {loading ? (
          <Stack alignItems="center" sx={{ py: 5 }}><CircularProgress size={24} /></Stack>
        ) : (
          <Table size="small" sx={{ '& td, & th': { px: 0.75, py: 0.5 } }}>
            <TableHead>
              <TableRow>
                {spec.fields.map((f) => <TableCell key={f.name} sx={{ fontSize: font.size.small, fontWeight: font.weight.semibold, color: color.label }}>{f.label}</TableCell>)}
                <TableCell />
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((r, i) => (
                <TableRow key={i}>
                  {spec.fields.map((f) => (
                    <TableCell key={f.name}>
                      {f.type === 'bool' ? (
                        <Checkbox size="small" checked={!!r[f.name]} onChange={(e) => setCell(i, f.name, e.target.checked ? 1 : 0)} />
                      ) : f.type === 'select' ? (
                        <TextField select size="small" fullWidth value={r[f.name] ?? ''} onChange={(e) => setCell(i, f.name, e.target.value)} inputProps={{ 'aria-label': f.label }} sx={{ minWidth: 120 }}>
                          {optionsFor(f).map((o) => <MenuItem key={String(o.value)} value={o.value}>{o.label}</MenuItem>)}
                        </TextField>
                      ) : (
                        <TextField
                          size="small" fullWidth type={f.type === 'number' ? 'number' : f.type === 'date' ? 'date' : 'text'}
                          value={r[f.name] ?? ''} onChange={(e) => setCell(i, f.name, e.target.value)}
                          inputProps={{ 'aria-label': f.label }} sx={{ minWidth: f.type === 'number' ? 90 : 120 }}
                          InputLabelProps={f.type === 'date' ? { shrink: true } : undefined}
                        />
                      )}
                    </TableCell>
                  ))}
                  <TableCell>
                    <Tooltip title="Remove line"><IconButton size="small" aria-label="Remove line" onClick={() => removeRow(i)}><DeleteOutlineIcon sx={{ fontSize: 16, color: color.danger }} /></IconButton></Tooltip>
                  </TableCell>
                </TableRow>
              ))}
              {rows.length === 0 && (
                <TableRow><TableCell colSpan={spec.fields.length + 1}><Typography sx={{ fontSize: font.size.label, color: color.muted, py: 1 }}>No lines yet — add one below.</Typography></TableCell></TableRow>
              )}
            </TableBody>
          </Table>
        )}
        <Button startIcon={<AddIcon sx={{ fontSize: 16 }} />} onClick={addRow} sx={{ mt: 1 }}>Add line</Button>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>Cancel</Button>
        <Button variant="contained" onClick={save} disabled={saving || loading} sx={{ bgcolor: color.primaryTile, '&:hover': { bgcolor: color.primaryDark } }}>
          {saving ? <CircularProgress size={16} sx={{ color: '#fff' }} /> : 'Save lines'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
