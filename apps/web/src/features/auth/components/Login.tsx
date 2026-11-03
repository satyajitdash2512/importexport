import * as React from 'react';
import { Box, Stack, Typography, TextField, Button, Alert, MenuItem, Divider, CircularProgress } from '@mui/material';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import { color, font, shape } from '../../../context/tokens';
import { useAuth } from '../../../context/AuthContext';
import { fetchTenants, type TenantOption } from '../../../lib/api';

const DEMO_USERS = [
  { u: 'controller', label: 'S. Menon — Finance controller' },
  { u: 'imports', label: 'A. Kulkarni — Import executive' },
  { u: 'compliance', label: 'D. Rao — Compliance officer' },
  { u: 'costing', label: 'M. Shah — Cost accountant' },
  { u: 'accounts', label: 'P. Nair — Accounts executive' },
  { u: 'tradefinance', label: 'V. Menon — Trade finance officer' },
  { u: 'audit', label: 'N. Fernandes — Internal auditor (read-only)' },
  { u: 'admin', label: 'System administrator' },
];

export function Login() {
  const { login } = useAuth();
  const [tenants, setTenants] = React.useState<TenantOption[]>([]);
  const [tenant, setTenant] = React.useState('');
  const [username, setUsername] = React.useState('controller');
  const [password, setPassword] = React.useState('hbtrade123');
  const [busy, setBusy] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  React.useEffect(() => {
    fetchTenants().then((t) => { setTenants(t); if (t.length && !tenant) setTenant(t.find((x) => x.code === 'HBML')?.code ?? t[0].code); });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true); setError(null);
    try { await login(username.trim(), password, tenant || undefined); } catch (err: any) { setError(err.message ?? 'Login failed'); } finally { setBusy(false); }
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: color.canvas, display: 'flex', alignItems: 'center', justifyContent: 'center', p: 2 }}>
      <Box sx={{ width: 400, bgcolor: color.surface, border: `1px solid ${color.border}`, borderRadius: `${shape.radius}px`, overflow: 'hidden' }}>
        <Box sx={{ bgcolor: color.primary, px: 3, py: 2.5 }}>
          <Stack direction="row" alignItems="baseline" spacing={0.75}>
            <Typography sx={{ fontSize: 20, fontWeight: font.weight.bold, color: color.onPrimary, letterSpacing: 0.5 }}>HostBooks</Typography>
            <Typography sx={{ fontSize: font.size.label, color: color.onPrimary, opacity: 0.85 }}>Import &amp; Export</Typography>
          </Stack>
          <Typography sx={{ fontSize: font.size.small, color: color.onPrimary, opacity: 0.8, mt: 0.5 }}>Accounting-anchored trade operations</Typography>
        </Box>

        <Box component="form" onSubmit={submit} sx={{ p: 3 }}>
          <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 2 }}>
            <LockOutlinedIcon sx={{ fontSize: 18, color: color.primary }} />
            <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold, color: color.text }}>Sign in</Typography>
          </Stack>

          {error && <Alert severity="error" sx={{ mb: 2, fontSize: font.size.label }}>{error}</Alert>}

          <TextField
            select fullWidth size="small" label="Business (tenant database)" value={tenant}
            onChange={(e) => setTenant(e.target.value)} sx={{ mb: 1.5 }} inputProps={{ 'aria-label': 'Business' }}
            helperText="Each business has its own database"
          >
            {tenants.map((t) => <MenuItem key={t.code} value={t.code}>{t.name}</MenuItem>)}
          </TextField>

          <TextField
            select fullWidth size="small" label="User" value={username}
            onChange={(e) => setUsername(e.target.value)} sx={{ mb: 1.5 }}
            inputProps={{ 'aria-label': 'User' }}
          >
            {DEMO_USERS.map((d) => <MenuItem key={d.u} value={d.u}>{d.label}</MenuItem>)}
          </TextField>
          <TextField
            fullWidth size="small" label="Username" value={username}
            onChange={(e) => setUsername(e.target.value)} sx={{ mb: 1.5 }} inputProps={{ 'aria-label': 'Username' }}
          />
          <TextField
            fullWidth size="small" type="password" label="Password" value={password}
            onChange={(e) => setPassword(e.target.value)} sx={{ mb: 2 }} inputProps={{ 'aria-label': 'Password' }}
          />
          <Button type="submit" fullWidth variant="contained" disabled={busy}
            sx={{ bgcolor: color.primaryTile, '&:hover': { bgcolor: color.primaryDark } }}>
            {busy ? <CircularProgress size={18} sx={{ color: color.onPrimary }} /> : 'Sign in'}
          </Button>

          <Divider sx={{ my: 2 }} />
          <Typography sx={{ fontSize: font.size.small, color: color.muted, lineHeight: 1.6 }}>
            Demo build — every user's password is <b>hbtrade123</b>. <b>Sign in as “controller”</b> (the default) to create and
            edit orders, shipments, declarations, vouchers, parties and the like: the <b>New</b> / <b>Edit</b> buttons enable
            for roles that hold the write permission. The <b>auditor</b> is deliberately read-only and the <b>admin</b> role
            only manages users — with those roles most New buttons stay disabled by design. Authorisation and row-level entity
            scoping are enforced by the API, not just the UI.
          </Typography>
        </Box>
      </Box>
    </Box>
  );
}
