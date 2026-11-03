import * as React from 'react';
import {
  Box, Stack, Typography, Button, TextField, MenuItem, Alert, Chip, IconButton, Tooltip, Snackbar,
  Dialog, DialogTitle, DialogContent, DialogActions, Table, TableHead, TableRow, TableCell, TableBody, Switch,
} from '@mui/material';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import LockOpenIcon from '@mui/icons-material/LockOpen';
import { color, font } from '../../../context/tokens';
import { useApi, get } from '../../../lib/api';
import { apiPost, apiPut, apiDelete } from '../../../lib/crud';
import { PageHeader, Band, Section, KpiStrip, Loading, ErrorState, StatusChip } from '../../../components/primitives';
import { DataTable } from '../../../components/DataTable';
import { date, dateTime } from '../../../utils/format';

/* ============================== Users & access ============================= */
export function AdminUsers() {
  const { data: users = [], isLoading, error, refetch } = useApi<any[]>(['admin-users'], '/admin/users');
  const { data: roles = [] } = useApi<any[]>(['admin-roles'], '/admin/roles');
  const [toast, setToast] = React.useState<string | null>(null);
  const [newOpen, setNewOpen] = React.useState(false);
  const [roleFor, setRoleFor] = React.useState<any | null>(null);
  const [pwFor, setPwFor] = React.useState<any | null>(null);
  const say = (m: string) => setToast(m);
  const run = async (fn: () => Promise<any>, ok: string) => { try { await fn(); say(ok); refetch(); } catch (e: any) { say(e.message); } };

  if (isLoading) return <Loading label="Loading users" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;

  return (
    <Box>
      <PageHeader title="Users & access" subtitle="Manage the users, roles and legal-entity access for this business (RD §23)."
        actions={<Button variant="contained" onClick={() => setNewOpen(true)}>New user</Button>} />
      <KpiStrip tiles={[
        { label: 'Users', value: users.length },
        { label: 'Active', value: users.filter((u) => u.active).length },
        { label: 'External', value: users.filter((u) => u.external).length },
        { label: 'Roles defined', value: roles.length },
      ]} />
      <Band />
      <Section title="Users" noBand>
        <Table size="small" sx={{ '& td, & th': { px: 1.25, py: 0.6 } }}>
          <TableHead><TableRow>
            {['User', 'Email', 'Roles', 'Entities', 'Active', 'Actions'].map((h) => <TableCell key={h} sx={{ fontWeight: font.weight.semibold, color: color.label, fontSize: font.size.small }}>{h}</TableCell>)}
          </TableRow></TableHead>
          <TableBody>
            {users.map((u) => (
              <TableRow key={u.id} hover>
                <TableCell><b>{u.fullName}</b><br /><span style={{ color: color.muted, fontSize: 11 }}>{u.username}{u.external ? ' · external' : ''}</span></TableCell>
                <TableCell sx={{ fontSize: font.size.label }}>{u.email}</TableCell>
                <TableCell>{u.roleNames?.map((r: string, i: number) => (
                  <Chip key={i} label={r} onDelete={() => run(() => apiDelete(`/admin/users/${u.id}/roles/${u.roles[i]}`), 'Role revoked')} sx={{ m: 0.2, bgcolor: color.primarySoft, color: color.primary, fontSize: 11 }} />
                ))}</TableCell>
                <TableCell sx={{ fontSize: font.size.label }}>{(u.entities ?? []).join(', ')}</TableCell>
                <TableCell><Switch size="small" checked={!!u.active} onChange={(e) => run(() => apiPut(`/admin/users/${u.id}/active`, { active: e.target.checked }), 'Updated')} /></TableCell>
                <TableCell>
                  <Button size="small" onClick={() => setRoleFor(u)}>Add role</Button>
                  <Button size="small" onClick={() => setPwFor(u)}>Reset password</Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Section>

      <NewUserDialog open={newOpen} roles={roles} onClose={() => setNewOpen(false)} onDone={(m: string) => { say(m); refetch(); }} />
      <AddRoleDialog user={roleFor} roles={roles} onClose={() => setRoleFor(null)} onDone={(m: string) => { say(m); refetch(); }} />
      <ResetPwDialog user={pwFor} onClose={() => setPwFor(null)} onDone={(m: string) => say(m)} />
      <Snackbar open={!!toast} autoHideDuration={5000} onClose={() => setToast(null)} message={toast ?? ''} />
    </Box>
  );
}

function NewUserDialog({ open, roles, onClose, onDone }: any) {
  const [f, setF] = React.useState<any>({ username: '', fullName: '', email: '', roleCode: '' });
  const [err, setErr] = React.useState<string | null>(null);
  const submit = async () => { try { await apiPost('/admin/users', f); onDone('User created (password hbtrade123)'); onClose(); } catch (e: any) { setErr(e.message); } };
  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>New user</DialogTitle>
      <DialogContent>
        {err && <Alert severity="error" sx={{ mb: 1.5 }}>{err}</Alert>}
        <Stack spacing={1.5} sx={{ mt: 0.5 }}>
          <TextField size="small" label="Username" value={f.username} onChange={(e) => setF({ ...f, username: e.target.value })} inputProps={{ 'aria-label': 'Username' }} />
          <TextField size="small" label="Full name" value={f.fullName} onChange={(e) => setF({ ...f, fullName: e.target.value })} inputProps={{ 'aria-label': 'Full name' }} />
          <TextField size="small" label="Email" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} inputProps={{ 'aria-label': 'Email' }} />
          <TextField size="small" select label="Initial role" value={f.roleCode} onChange={(e) => setF({ ...f, roleCode: e.target.value })} inputProps={{ 'aria-label': 'Initial role' }}>
            {roles.map((r: any) => <MenuItem key={r.code} value={r.code}>{r.name}</MenuItem>)}
          </TextField>
          <Typography sx={{ fontSize: font.size.small, color: color.muted }}>The user is created with password <b>hbtrade123</b> and scoped to entity 1.</Typography>
        </Stack>
      </DialogContent>
      <DialogActions><Button onClick={onClose}>Cancel</Button><Button variant="contained" onClick={submit}>Create</Button></DialogActions>
    </Dialog>
  );
}
function AddRoleDialog({ user, roles, onClose, onDone }: any) {
  const [roleCode, setRole] = React.useState('');
  const [err, setErr] = React.useState<string | null>(null);
  React.useEffect(() => { setRole(''); setErr(null); }, [user]);
  if (!user) return null;
  const submit = async () => { try { await apiPost(`/admin/users/${user.id}/roles`, { roleCode }); onDone('Role assigned'); onClose(); } catch (e: any) { setErr(e.message); } };
  return (
    <Dialog open onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>Assign role to {user.fullName}</DialogTitle>
      <DialogContent>
        {err && <Alert severity="error" sx={{ mb: 1.5 }}>{err}</Alert>}
        <TextField size="small" select fullWidth label="Role" value={roleCode} onChange={(e) => setRole(e.target.value)} sx={{ mt: 0.5 }} inputProps={{ 'aria-label': 'Role' }}>
          {roles.map((r: any) => <MenuItem key={r.code} value={r.code}>{r.name}</MenuItem>)}
        </TextField>
        <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 1 }}>A grant that breaches segregation of duties is refused with the reason.</Typography>
      </DialogContent>
      <DialogActions><Button onClick={onClose}>Cancel</Button><Button variant="contained" disabled={!roleCode} onClick={submit}>Assign</Button></DialogActions>
    </Dialog>
  );
}
function ResetPwDialog({ user, onClose, onDone }: any) {
  const [pw, setPw] = React.useState('');
  const [err, setErr] = React.useState<string | null>(null);
  React.useEffect(() => { setPw(''); setErr(null); }, [user]);
  if (!user) return null;
  const submit = async () => { try { await apiPut(`/admin/users/${user.id}/password`, { password: pw }); onDone('Password reset; sessions revoked'); onClose(); } catch (e: any) { setErr(e.message); } };
  return (
    <Dialog open onClose={onClose} fullWidth maxWidth="xs">
      <DialogTitle>Reset password — {user.username}</DialogTitle>
      <DialogContent>
        {err && <Alert severity="error" sx={{ mb: 1.5 }}>{err}</Alert>}
        <TextField size="small" fullWidth type="password" label="New password (min 6)" value={pw} onChange={(e) => setPw(e.target.value)} sx={{ mt: 0.5 }} inputProps={{ 'aria-label': 'New password' }} />
      </DialogContent>
      <DialogActions><Button onClick={onClose}>Cancel</Button><Button variant="contained" disabled={pw.length < 6} onClick={submit}>Reset</Button></DialogActions>
    </Dialog>
  );
}

/* ============================== Tenants ================================== */
export function Tenants() {
  const { data: tenants = [], isLoading, error, refetch } = useApi<any[]>(['tenants'], '/admin/tenants');
  const [f, setF] = React.useState({ code: '', name: '' });
  const [busy, setBusy] = React.useState(false);
  const [result, setResult] = React.useState<any | null>(null);
  const [err, setErr] = React.useState<string | null>(null);

  const provision = async () => {
    setBusy(true); setErr(null); setResult(null);
    try { const r = await apiPost('/admin/tenants', f); setResult(r); setF({ code: '', name: '' }); refetch(); }
    catch (e: any) { setErr(e.message); } finally { setBusy(false); }
  };
  if (isLoading) return <Loading label="Loading businesses" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;

  return (
    <Box>
      <PageHeader title="Businesses (tenants)" subtitle="Each business runs in its own database. Provisioning creates the database, applies every migration, seeds a chart of accounts and voucher types, and creates an administrator." />
      <KpiStrip tiles={[{ label: 'Businesses', value: tenants.length }, { label: 'Active', value: tenants.filter((t) => t.status === 'ACTIVE').length }, { label: 'Total users', value: tenants.reduce((s, t) => s + (t.users || 0), 0) }]} />
      <Band />
      <Section title="Provision a new business" noBand>
        <Box sx={{ px: 1.5, pb: 1.5 }}>
          {err && <Alert severity="error" sx={{ mb: 1.5 }}>{err}</Alert>}
          {result && <Alert severity="success" sx={{ mb: 1.5 }}>Provisioned <b>{result.code}</b> in database <code>{result.db}</code>. Sign in with <b>{result.adminUser}</b> / <b>{result.adminPassword}</b> and business <b>{result.code}</b>.</Alert>}
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems="flex-start">
            <TextField size="small" label="Code (e.g. NEWCO)" value={f.code} onChange={(e) => setF({ ...f, code: e.target.value.toUpperCase() })} inputProps={{ 'aria-label': 'Code' }} />
            <TextField size="small" label="Business name" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} sx={{ minWidth: 260 }} inputProps={{ 'aria-label': 'Business name' }} />
            <Button variant="contained" disabled={busy || !f.code || !f.name} onClick={provision}>{busy ? 'Provisioning…' : 'Provision business'}</Button>
          </Stack>
        </Box>
      </Section>
      <Band />
      <Section title="Businesses" noBand>
        <Table size="small" sx={{ '& td, & th': { px: 1.25, py: 0.6 } }}>
          <TableHead><TableRow>{['Code', 'Name', 'Database', 'Status', 'Users'].map((h) => <TableCell key={h} sx={{ fontWeight: font.weight.semibold, color: color.label, fontSize: font.size.small }}>{h}</TableCell>)}</TableRow></TableHead>
          <TableBody>{tenants.map((t) => (
            <TableRow key={t.id}><TableCell><b>{t.code}</b></TableCell><TableCell>{t.name}</TableCell><TableCell><code style={{ fontSize: 11 }}>{t.db}</code></TableCell><TableCell><StatusChip status={t.status} /></TableCell><TableCell>{t.users}</TableCell></TableRow>
          ))}</TableBody>
        </Table>
      </Section>
    </Box>
  );
}

/* ============================== Periods ================================== */
export function Periods() {
  const { data: periods = [], isLoading, error, refetch } = useApi<any[]>(['periods'], '/periods');
  const [toast, setToast] = React.useState<string | null>(null);
  const set = async (key: number, status: string) => {
    try { await apiPut(`/periods/${key}/status`, { status, reason: `${status} via admin` }); setToast(`Period ${key} → ${status}`); refetch(); }
    catch (e: any) { setToast(e.message); }
  };
  if (isLoading) return <Loading label="Loading periods" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  return (
    <Box>
      <PageHeader title="Accounting periods" subtitle="Open, soft-close and hard-close periods for the primary book. Lock overrides are recorded to the audit trail." />
      <Band />
      <Section title="Periods" noBand>
        <Table size="small" sx={{ '& td, & th': { px: 1.25, py: 0.6 } }}>
          <TableHead><TableRow>{['Period', 'Fiscal year', 'Dates', 'Status', 'Actions'].map((h) => <TableCell key={h} sx={{ fontWeight: font.weight.semibold, color: color.label, fontSize: font.size.small }}>{h}</TableCell>)}</TableRow></TableHead>
          <TableBody>{periods.map((p) => (
            <TableRow key={p.periodKey}>
              <TableCell><b>{p.periodKey}</b></TableCell>
              <TableCell>{p.fiscalYear}</TableCell>
              <TableCell sx={{ fontSize: font.size.label }}>{date(p.startsOn)} – {date(p.endsOn)}</TableCell>
              <TableCell><StatusChip status={p.status} /></TableCell>
              <TableCell>
                {p.status !== 'OPEN' && <Tooltip title="Re-open"><IconButton size="small" aria-label="Open" onClick={() => set(p.periodKey, 'OPEN')}><LockOpenIcon sx={{ fontSize: 17, color: color.success }} /></IconButton></Tooltip>}
                {p.status === 'OPEN' && <Button size="small" onClick={() => set(p.periodKey, 'SOFT_CLOSED')}>Soft close</Button>}
                {p.status !== 'HARD_CLOSED' && <Tooltip title="Hard close"><IconButton size="small" aria-label="Hard close" onClick={() => set(p.periodKey, 'HARD_CLOSED')}><LockOutlinedIcon sx={{ fontSize: 17, color: color.danger }} /></IconButton></Tooltip>}
              </TableCell>
            </TableRow>
          ))}</TableBody>
        </Table>
      </Section>
      <Snackbar open={!!toast} autoHideDuration={4000} onClose={() => setToast(null)} message={toast ?? ''} />
    </Box>
  );
}

/* ============================== Integrations ============================= */
export function Integrations() {
  const { data: log = [], isLoading, error, refetch } = useApi<any[]>(['integ-log'], '/integrations/log');
  const [decl, setDecl] = React.useState('D-001');
  const [instr, setInstr] = React.useState('I-001');
  const [toast, setToast] = React.useState<string | null>(null);
  const act = async (fn: () => Promise<any>) => { try { const r = await fn(); setToast(`${r.channel || 'OK'} · ${r.status || ''} ${r.gatewayRef || r.detail || ''}`); refetch(); } catch (e: any) { setToast(e.message); } };

  if (isLoading) return <Loading label="Loading integration log" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  return (
    <Box>
      <PageHeader title="Integrations" subtitle="Connectors to ICEGATE (customs), EDPMS (export realisation) and the bank host. In this build the gateways are simulated — messages move through the real lifecycle and are journalled, without a live endpoint." />
      <Box sx={{ p: 1.5 }}><Alert severity="info">Simulated connectors: the request/response lifecycle and message journal are production-shaped; swapping the simulator for a real HTTP client is the only change needed.</Alert></Box>
      <Band />
      <Section title="Send / query" noBand>
        <Box sx={{ px: 1.5, pb: 1.5, display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
          <Box>
            <Typography variant="h2" sx={{ mb: 0.75 }}>Customs (ICEGATE / EDPMS)</Typography>
            <Stack direction="row" spacing={1} alignItems="center">
              <TextField size="small" label="Declaration" value={decl} onChange={(e) => setDecl(e.target.value)} sx={{ width: 130 }} inputProps={{ 'aria-label': 'Declaration' }} />
              <Button variant="outlined" onClick={() => act(() => apiPost(`/integrations/icegate/transmit/${decl}`))}>Transmit</Button>
              <Button variant="outlined" onClick={() => act(() => apiPost(`/integrations/icegate/poll/${decl}`))}>Poll status</Button>
              <Button variant="outlined" onClick={() => act(() => apiPost(`/integrations/edpms/${decl}`))}>EDPMS</Button>
            </Stack>
          </Box>
          <Box>
            <Typography variant="h2" sx={{ mb: 0.75 }}>Bank host (SWIFT)</Typography>
            <Stack direction="row" spacing={1} alignItems="center">
              <TextField size="small" label="Instrument" value={instr} onChange={(e) => setInstr(e.target.value)} sx={{ width: 130 }} inputProps={{ 'aria-label': 'Instrument' }} />
              <Button variant="outlined" onClick={() => act(() => apiPost(`/integrations/bank/${instr}`))}>Send message</Button>
            </Stack>
          </Box>
        </Box>
      </Section>
      <Band />
      <Section title="Message journal" noBand>
        <Table size="small" sx={{ '& td, & th': { px: 1.25, py: 0.5 } }}>
          <TableHead><TableRow>{['Time', 'Channel', 'Dir', 'Type', 'Object', 'Gateway ref', 'Status'].map((h) => <TableCell key={h} sx={{ fontWeight: font.weight.semibold, color: color.label, fontSize: font.size.small }}>{h}</TableCell>)}</TableRow></TableHead>
          <TableBody>{log.map((m) => (
            <TableRow key={m.id}>
              <TableCell sx={{ fontSize: font.size.small, whiteSpace: 'nowrap' }}>{dateTime(m.at)}</TableCell>
              <TableCell><Chip label={m.channel} sx={{ bgcolor: color.band, color: color.label, fontSize: 11 }} /></TableCell>
              <TableCell sx={{ fontSize: font.size.small }}>{m.direction}</TableCell>
              <TableCell sx={{ fontSize: font.size.label }}>{m.messageType}</TableCell>
              <TableCell sx={{ fontSize: font.size.label }}>{m.objectRef}</TableCell>
              <TableCell sx={{ fontSize: font.size.small }}>{m.gatewayRef}</TableCell>
              <TableCell><StatusChip status={m.status} /></TableCell>
            </TableRow>
          ))}{log.length === 0 && <TableRow><TableCell colSpan={7}><Typography sx={{ color: color.muted, fontSize: font.size.label, py: 1 }}>No messages yet — send one above.</Typography></TableCell></TableRow>}</TableBody>
        </Table>
      </Section>
      <Snackbar open={!!toast} autoHideDuration={5000} onClose={() => setToast(null)} message={toast ?? ''} />
    </Box>
  );
}

/* ============================== Audit log ============================== */
export function AuditLog() {
  const { data: rows = [], isLoading, error, refetch } = useApi<any[]>(['audit'], '/audit');
  if (isLoading) return <Loading label="Loading audit log" />;
  if (error) return <ErrorState error={error} onRetry={refetch} />;
  const cols = [
    { field: 'at', headerName: 'Time', width: 175, renderCell: (p: any) => dateTime(p.value) },
    { field: 'user', headerName: 'User', width: 130 },
    { field: 'action', headerName: 'Action', width: 150, renderCell: (p: any) => <Chip label={p.value} sx={{ bgcolor: color.band, color: color.label, fontSize: 11 }} /> },
    { field: 'objectType', headerName: 'Object', width: 150 },
    { field: 'objectRef', headerName: 'Reference', width: 150 },
    { field: 'newValue', headerName: 'Detail', flex: 1, minWidth: 180 },
    { field: 'reason', headerName: 'Reason', flex: 1, minWidth: 160 },
  ];
  return (
    <Box>
      <PageHeader title="Audit log" subtitle="Append-only record of every create, edit, delete, post, reversal, transmission and period change (RD HBIE-SEC-030)." />
      <Band />
      <DataTable rows={rows} columns={cols as any} searchFields={['user', 'action', 'objectType', 'objectRef']} exportName="audit-log" initialPageSize={50} />
    </Box>
  );
}
