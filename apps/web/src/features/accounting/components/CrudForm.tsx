import * as React from 'react';
import {
  Drawer, Box, Stack, Typography, TextField, MenuItem, Button, IconButton, Alert, Checkbox, FormControlLabel, CircularProgress, Divider,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import { color, font } from '../../../context/tokens';
import { get } from '../../../lib/api';
import { getRaw, createRow, updateRow } from '../../../lib/crud';
import { CRUD_FIELDS, type CrudField } from '../../../config/crudRegistry';

interface Props {
  resource: string;
  mode: 'create' | 'edit';
  id?: string | number;          // for edit
  title: string;
  onClose: () => void;
  onSaved: () => void;
}

export function CrudForm({ resource, mode, id, title, onClose, onSaved }: Props) {
  const fields = CRUD_FIELDS[resource] ?? [];
  const [values, setValues] = React.useState<Record<string, any>>({});
  const [loading, setLoading] = React.useState(mode === 'edit');
  const [saving, setSaving] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [dynOptions, setDynOptions] = React.useState<Record<string, { value: any; label: string }[]>>({});

  // load dynamic option lists (e.g. counterparties)
  React.useEffect(() => {
    let live = true;
    fields.filter((f) => f.optionsFrom).forEach(async (f) => {
      try {
        const rows = await get<any[]>(f.optionsFrom!.endpoint.replace('/crud', '/crud'));
        if (!live) return;
        setDynOptions((o) => ({ ...o, [f.name]: rows.map((r) => ({ value: r[f.optionsFrom!.value], label: String(r[f.optionsFrom!.label]) })) }));
      } catch { /* leave empty */ }
    });
    return () => { live = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resource]);

  // load current values on edit
  React.useEffect(() => {
    if (mode !== 'edit' || id === undefined) return;
    let live = true;
    getRaw(resource, id).then((row) => {
      if (!live) return;
      const v: Record<string, any> = {};
      for (const f of fields) v[f.name] = row[f.name] ?? (f.type === 'bool' ? 0 : '');
      setValues(v); setLoading(false);
    }).catch((e) => { setError(e.message); setLoading(false); });
    return () => { live = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resource, id, mode]);

  const set = (name: string, v: any) => setValues((s) => ({ ...s, [name]: v }));

  const submit = async () => {
    setSaving(true); setError(null);
    try {
      const payload: Record<string, any> = {};
      for (const f of fields) {
        let v = values[f.name];
        if (f.type === 'bool') v = v ? 1 : 0;
        if (f.type === 'number' && v !== '' && v !== undefined && v !== null) v = Number(v);
        payload[f.name] = v;
      }
      if (mode === 'create') await createRow(resource, payload);
      else await updateRow(resource, id!, payload);
      onSaved(); onClose();
    } catch (e: any) { setError(e.message ?? 'Save failed'); } finally { setSaving(false); }
  };

  const optionsFor = (f: CrudField) => f.options ?? dynOptions[f.name] ?? [];

  return (
    <Drawer anchor="right" open onClose={onClose}>
      <Box sx={{ width: 460, height: '100%', display: 'flex', flexDirection: 'column' }}>
        <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ px: 2, py: 1.5, borderBottom: `1px solid ${color.border}`, bgcolor: color.surface }}>
          <Typography sx={{ fontSize: font.size.pageTitle, fontWeight: font.weight.bold, color: color.text }}>
            {mode === 'create' ? 'New' : 'Edit'} · {title}
          </Typography>
          <IconButton aria-label="Close" onClick={onClose}><CloseIcon sx={{ fontSize: 18 }} /></IconButton>
        </Stack>

        <Box sx={{ flex: 1, overflowY: 'auto', p: 2 }}>
          {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>{error}</Alert>}
          {loading ? (
            <Stack alignItems="center" sx={{ py: 6 }}><CircularProgress size={24} /></Stack>
          ) : (
            <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 1.25 }}>
              {fields.map((f) => {
                const full = !f.half;
                const common = {
                  key: f.name, size: 'small' as const, fullWidth: true, label: f.label + (f.required ? ' *' : ''),
                  value: values[f.name] ?? '', onChange: (e: any) => set(f.name, e.target.value),
                  sx: { gridColumn: full ? '1 / span 2' : 'auto' },
                  inputProps: { 'aria-label': f.label },
                };
                if (f.type === 'bool') {
                  return (
                    <FormControlLabel
                      key={f.name} sx={{ gridColumn: full ? '1 / span 2' : 'auto' }}
                      control={<Checkbox checked={!!values[f.name]} onChange={(e) => set(f.name, e.target.checked ? 1 : 0)} size="small" />}
                      label={<Typography sx={{ fontSize: font.size.label }}>{f.label}</Typography>}
                    />
                  );
                }
                if (f.type === 'select') {
                  return (
                    <TextField {...common} select>
                      {optionsFor(f).map((o) => <MenuItem key={String(o.value)} value={o.value}>{o.label}</MenuItem>)}
                    </TextField>
                  );
                }
                return (
                  <TextField
                    {...common}
                    type={f.type === 'number' ? 'number' : f.type === 'date' ? 'date' : 'text'}
                    multiline={f.type === 'multiline'} minRows={f.type === 'multiline' ? 2 : undefined}
                    InputLabelProps={f.type === 'date' ? { shrink: true } : undefined}
                  />
                );
              })}
            </Box>
          )}
        </Box>

        <Divider />
        <Stack direction="row" spacing={1} justifyContent="flex-end" sx={{ p: 1.5, bgcolor: color.surface }}>
          <Button variant="outlined" onClick={onClose} disabled={saving}>Cancel</Button>
          <Button variant="contained" onClick={submit} disabled={saving || loading} sx={{ bgcolor: color.primaryTile, '&:hover': { bgcolor: color.primaryDark } }}>
            {saving ? <CircularProgress size={16} sx={{ color: '#fff' }} /> : mode === 'create' ? 'Create' : 'Save changes'}
          </Button>
        </Stack>
      </Box>
    </Drawer>
  );
}
