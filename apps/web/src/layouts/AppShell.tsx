import * as React from 'react';
import {
  Box, Stack, Typography, IconButton, InputAdornment, TextField, Badge, Drawer, List, ListItemButton,
  ListItemText, ListItemIcon, Collapse, Tooltip, Divider, Popover, Menu, MenuItem, Avatar, Chip,
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import MenuIcon from '@mui/icons-material/Menu';
import ExpandLess from '@mui/icons-material/ExpandLess';
import ExpandMore from '@mui/icons-material/ExpandMore';
import DashboardIcon from '@mui/icons-material/Dashboard';
import DownloadIcon from '@mui/icons-material/Download';
import UploadIcon from '@mui/icons-material/Upload';
import VerifiedIcon from '@mui/icons-material/VerifiedUser';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import CalculateIcon from '@mui/icons-material/Calculate';
import MenuBookIcon from '@mui/icons-material/MenuBook';
import TaskAltIcon from '@mui/icons-material/TaskAlt';
import SettingsIcon from '@mui/icons-material/Settings';
import CloseIcon from '@mui/icons-material/Close';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import LogoutIcon from '@mui/icons-material/Logout';
import { color, font, layout, shape } from '../context/tokens';
import { navigation, allRoutes } from '../config/navigation';
import { useApi } from '../lib/api';
import { useAuth } from '../context/AuthContext';
import { SeverityChip, DeadlineChip } from '../components/primitives';

const ICONS: Record<string, React.ReactElement> = {
  dashboard: <DashboardIcon sx={{ fontSize: 17 }} />,
  download: <DownloadIcon sx={{ fontSize: 17 }} />,
  upload: <UploadIcon sx={{ fontSize: 17 }} />,
  verified: <VerifiedIcon sx={{ fontSize: 17 }} />,
  local_shipping: <LocalShippingIcon sx={{ fontSize: 17 }} />,
  account_balance: <AccountBalanceIcon sx={{ fontSize: 17 }} />,
  calculate: <CalculateIcon sx={{ fontSize: 17 }} />,
  menu_book: <MenuBookIcon sx={{ fontSize: 17 }} />,
  task_alt: <TaskAltIcon sx={{ fontSize: 17 }} />,
  settings: <SettingsIcon sx={{ fontSize: 17 }} />,
};

interface TaskItem {
  id: string; title: string; detail: string; severity: 'critical' | 'high' | 'medium' | 'info';
  route: string; dueOn?: string; owner: string; kind: string;
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const loc = useLocation();
  const nav = useNavigate();
  const [navOpen, setNavOpen] = React.useState(true);
  const [inboxOpen, setInboxOpen] = React.useState(false);
  const [openGroups, setOpenGroups] = React.useState<string[]>(() => {
    const active = navigation.find((g) => g.items.some((i) => loc.pathname.startsWith(i.path) && i.path !== '/'));
    return active ? [active.label] : ['Import'];
  });
  const [search, setSearch] = React.useState('');
  const [searchAnchor, setSearchAnchor] = React.useState<null | HTMLElement>(null);
  const [userMenu, setUserMenu] = React.useState<null | HTMLElement>(null);
  const { user, logout } = useAuth();
  const { data: tasks = [] } = useApi<TaskItem[]>(['tasks'], '/tasks');
  const initials = (user?.fullName ?? 'HB').split(/\s+/).map((w) => w[0]).slice(0, 2).join('').toUpperCase();
  const roleLabel = (user?.roles?.[0] ?? '').replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());

  const critical = tasks.filter((t) => t.severity === 'critical').length;

  const toggleGroup = (label: string) =>
    setOpenGroups((g) => (g.includes(label) ? g.filter((x) => x !== label) : [...g, label]));

  const matches = React.useMemo(() => {
    if (search.trim().length < 2) return [];
    const n = search.toLowerCase();
    return allRoutes.filter((r) => r.label.toLowerCase().includes(n) || r.group.toLowerCase().includes(n)).slice(0, 10);
  }, [search]);

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100vh', bgcolor: color.canvas }}>
      {/* ------------------------------------------------------------ top bar */}
      <Stack
        direction="row" alignItems="center" spacing={1}
        component="header"
        sx={{ height: layout.topBarHeight, flexShrink: 0, bgcolor: color.surface, borderBottom: `1px solid ${color.border}`, px: 1 }}
      >
        <IconButton aria-label="Toggle navigation" onClick={() => setNavOpen((o) => !o)}>
          <MenuIcon sx={{ fontSize: 19, color: color.primary }} />
        </IconButton>
        <Stack direction="row" alignItems="baseline" spacing={0.75} component={Link} to="/" sx={{ textDecoration: 'none' }}>
          <Typography sx={{ fontSize: 17, fontWeight: font.weight.bold, color: color.primary, letterSpacing: 0.5 }}>
            HostBooks
          </Typography>
          <Typography sx={{ fontSize: font.size.label, color: color.muted }}>Import &amp; Export</Typography>
        </Stack>
        <Box sx={{ flex: 1 }} />
        <TextField
          value={search}
          onChange={(e) => { setSearch(e.target.value); setSearchAnchor(e.currentTarget); }}
          placeholder="Search order, shipment, container, declaration, voucher…"
          sx={{ width: { xs: 180, md: 420 } }}
          inputProps={{ 'aria-label': 'Search orders, shipments, containers, declarations and vouchers' }}
          InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 15, color: color.muted }} /></InputAdornment> }}
        />
        <Popover
          open={matches.length > 0}
          anchorEl={searchAnchor}
          onClose={() => setSearch('')}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
          disableAutoFocus
          disableEnforceFocus
        >
          <List dense sx={{ width: 420, py: 0 }}>
            {matches.map((m) => (
              <ListItemButton key={m.path} onClick={() => { nav(m.path); setSearch(''); }}>
                <ListItemText primary={m.label} secondary={m.group} />
              </ListItemButton>
            ))}
          </List>
        </Popover>
        <Tooltip title="Task inbox">
          <IconButton aria-label={`Task inbox, ${tasks.length} items`} onClick={() => setInboxOpen(true)}>
            <Badge badgeContent={tasks.length} color="error" sx={{ '& .MuiBadge-badge': { fontSize: 9, height: 15, minWidth: 15 } }}>
              <NotificationsNoneIcon sx={{ fontSize: 19, color: color.primary }} />
            </Badge>
          </IconButton>
        </Tooltip>
        <Chip
          label={`${user?.tenantCode ?? 'HBML'} · Jul 2026 · Primary book`}
          title="Active business (its own database) · period · book"
          sx={{ bgcolor: color.primarySoft, color: color.primary, border: `1px solid ${color.primaryBorder}`, display: { xs: 'none', lg: 'flex' } }}
        />
        <Tooltip title={user ? `${user.fullName} — ${roleLabel}` : 'Account'}>
          <Avatar
            onClick={(e) => setUserMenu(e.currentTarget)}
            sx={{ width: 26, height: 26, fontSize: 11, bgcolor: color.primaryTile, cursor: 'pointer' }}
            aria-label="Account menu"
          >
            {initials}
          </Avatar>
        </Tooltip>
        <Menu anchorEl={userMenu} open={Boolean(userMenu)} onClose={() => setUserMenu(null)}>
          <Box sx={{ px: 2, py: 1 }}>
            <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold, color: color.text }}>{user?.fullName}</Typography>
            <Typography sx={{ fontSize: font.size.small, color: color.muted }}>{roleLabel}</Typography>
            <Typography sx={{ fontSize: font.size.small, color: color.muted }}>{user?.perms.length} permissions · entity {user?.entities.join(', ')}</Typography>
          </Box>
          <Divider />
          <MenuItem onClick={() => { setUserMenu(null); logout(); }}>
            <ListItemIcon><LogoutIcon sx={{ fontSize: 17 }} /></ListItemIcon>
            <ListItemText primary="Sign out" />
          </MenuItem>
        </Menu>
      </Stack>

      <Box sx={{ display: 'flex', flex: 1, minHeight: 0 }}>
        {/* --------------------------------------------------------- sidebar */}
        <Box
          component="nav"
          aria-label="Main navigation"
          sx={{
            width: navOpen ? layout.sidebarWidth : 0, flexShrink: 0, overflowY: 'auto', overflowX: 'hidden',
            bgcolor: color.surface, borderRight: navOpen ? `1px solid ${color.border}` : 'none',
            transition: 'width 140ms ease',
          }}
        >
          <List dense sx={{ py: 0.5 }}>
            {navigation.map((g) => {
              const isSingle = g.items.length === 1;
              const groupActive = g.items.some((i) => (i.path === '/' ? loc.pathname === '/' : loc.pathname.startsWith(i.path)));
              return (
                <React.Fragment key={g.label}>
                  <ListItemButton
                    onClick={() => (isSingle ? nav(g.items[0].path) : toggleGroup(g.label))}
                    selected={isSingle && groupActive}
                    sx={{ mx: 0.5 }}
                  >
                    <ListItemIcon>{ICONS[g.icon]}</ListItemIcon>
                    <ListItemText primary={g.label} primaryTypographyProps={{ fontWeight: font.weight.semibold }} />
                    {!isSingle && (openGroups.includes(g.label) ? <ExpandLess sx={{ fontSize: 16 }} /> : <ExpandMore sx={{ fontSize: 16 }} />)}
                  </ListItemButton>
                  {!isSingle && (
                    <Collapse in={openGroups.includes(g.label)} timeout="auto" unmountOnExit>
                      <List dense disablePadding>
                        {g.items.map((i) => (
                          <ListItemButton
                            key={i.path}
                            component={Link}
                            to={i.path}
                            selected={loc.pathname === i.path || (i.path !== '/' && loc.pathname.startsWith(`${i.path}/`))}
                            sx={{ pl: 4.5, mx: 0.5 }}
                          >
                            <ListItemText primary={i.label} />
                            {i.badge === 'exceptions' && critical > 0 && (
                              <Box component="span" sx={{ fontSize: font.size.small, fontWeight: font.weight.bold, color: color.danger, bgcolor: color.dangerSoft, px: 0.5, borderRadius: '3px' }}>
                                {critical}
                              </Box>
                            )}
                          </ListItemButton>
                        ))}
                      </List>
                    </Collapse>
                  )}
                </React.Fragment>
              );
            })}
          </List>
          <Divider />
          <Box sx={{ p: 1 }}>
            <Typography sx={{ fontSize: font.size.small, color: color.muted, lineHeight: 1.5 }}>
              Theme derived from the HostBooks product screenshot. All tokens live in
              <Box component="code" sx={{ display: 'block', mt: 0.5, fontFamily: font.mono, fontSize: 10.5 }}>
                src/theme/tokens.ts
              </Box>
            </Typography>
          </Box>
        </Box>

        {/* ----------------------------------------------------------- content */}
        <Box component="main" sx={{ flex: 1, minWidth: 0, overflowY: 'auto', bgcolor: color.canvas }}>
          {children}
        </Box>
      </Box>

      {/* ------------------------------------------------------- task inbox */}
      <Drawer anchor="right" open={inboxOpen} onClose={() => setInboxOpen(false)}>
        <Box sx={{ width: 420, height: '100%', display: 'flex', flexDirection: 'column' }}>
          <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ px: 1.5, py: 1, borderBottom: `1px solid ${color.border}` }}>
            <Typography variant="h2">Task inbox</Typography>
            <IconButton aria-label="Close task inbox" onClick={() => setInboxOpen(false)}><CloseIcon sx={{ fontSize: 17 }} /></IconButton>
          </Stack>
          <Box sx={{ overflowY: 'auto', flex: 1 }}>
            {tasks.map((t) => (
              <Box
                key={t.id}
                onClick={() => { nav(t.route); setInboxOpen(false); }}
                sx={{ px: 1.5, py: 1, borderBottom: `1px solid ${color.border}`, cursor: 'pointer', '&:hover': { bgcolor: color.primarySoft } }}
              >
                <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.4 }}>
                  <SeverityChip severity={t.severity} />
                  <Typography sx={{ fontSize: font.size.small, color: color.muted, textTransform: 'capitalize' }}>{t.kind}</Typography>
                  <Box sx={{ flex: 1 }} />
                  {t.dueOn && <DeadlineChip iso={t.dueOn} />}
                </Stack>
                <Typography sx={{ fontSize: font.size.body, fontWeight: font.weight.semibold, color: color.text }}>{t.title}</Typography>
                <Typography sx={{ fontSize: font.size.label, color: color.muted }}>{t.detail}</Typography>
                <Typography sx={{ fontSize: font.size.small, color: color.muted, mt: 0.25 }}>Owner: {t.owner}</Typography>
              </Box>
            ))}
          </Box>
        </Box>
      </Drawer>
    </Box>
  );
}
