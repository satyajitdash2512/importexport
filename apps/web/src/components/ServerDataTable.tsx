import * as React from 'react';
import { Box, Stack, TextField, Button, Typography, Menu, MenuItem, Checkbox, ListItemText, InputAdornment } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import ViewColumnIcon from '@mui/icons-material/ViewColumn';
import { DataGrid, type GridColDef, type GridRowParams, type GridRowClassNameParams, type GridPaginationModel } from '@mui/x-data-grid';
import { color, font, layout } from '../context/tokens';
import { dataGridSx } from '../context/hostbooksTheme';
import { EmptyState } from './primitives';
import { getPage } from '../lib/api';

export interface ServerDataTableProps {
  /** API path under /api, e.g. '/crud/parties'. */
  endpoint: string;
  columns: GridColDef[];
  onRowClick?: (row: any) => void;
  /** Enable the server-side search box (matches the resource's searchCols). */
  searchable?: boolean;
  searchPlaceholder?: string;
  toolbarExtras?: React.ReactNode;
  rowClassName?: (row: any) => string | undefined;
  emptyTitle?: string;
  emptyDetail?: string;
  initialPageSize?: number;
  hiddenByDefault?: string[];
  /** bump this to force a refetch (e.g. after create/delete). */
  refreshKey?: number;
}

/**
 * A DataGrid that pages, searches and counts on the server. Each page is a single
 * windowed SQL query (LIMIT/OFFSET) plus a COUNT, so a table with a million rows
 * loads one 50-row page at a time rather than shipping the whole set to the browser.
 */
export function ServerDataTable({
  endpoint, columns, onRowClick, searchable, searchPlaceholder = 'Search', toolbarExtras,
  rowClassName, emptyTitle = 'Nothing to show', emptyDetail, initialPageSize = 50,
  hiddenByDefault = [], refreshKey = 0,
}: ServerDataTableProps) {
  const [rows, setRows] = React.useState<any[]>([]);
  const [rowCount, setRowCount] = React.useState(0);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [model, setModel] = React.useState<GridPaginationModel>({ page: 0, pageSize: initialPageSize });
  const [q, setQ] = React.useState('');
  const [debouncedQ, setDebouncedQ] = React.useState('');
  const [colAnchor, setColAnchor] = React.useState<null | HTMLElement>(null);
  const [hidden, setHidden] = React.useState<string[]>(hiddenByDefault);

  // debounce the search box; reset to the first page when the term changes
  React.useEffect(() => {
    const t = setTimeout(() => { setDebouncedQ(q); setModel((m) => ({ ...m, page: 0 })); }, 300);
    return () => clearTimeout(t);
  }, [q]);

  React.useEffect(() => {
    let live = true;
    setLoading(true); setError(null);
    const sep = endpoint.includes('?') ? '&' : '?';
    const url = `${endpoint}${sep}paged=1&limit=${model.pageSize}&offset=${model.page * model.pageSize}${debouncedQ ? `&q=${encodeURIComponent(debouncedQ)}` : ''}`;
    getPage<any[]>(url)
      .then((res) => {
        if (!live) return;
        const data = (res.data ?? []).map((r: any, i: number) => (r?.id !== undefined ? r : { ...r, id: r?.code ?? r?.number ?? r?.ref ?? `row-${model.page}-${i}` }));
        setRows(data);
        setRowCount(res.page?.total ?? data.length);
      })
      .catch((e) => { if (live) setError(e.message ?? 'Load failed'); })
      .finally(() => { if (live) setLoading(false); });
    return () => { live = false; };
  }, [endpoint, model.page, model.pageSize, debouncedQ, refreshKey]);

  const visibleColumns = columns.filter((c) => !hidden.includes(c.field));

  return (
    <Box sx={{ bgcolor: color.surface }}>
      <Stack direction="row" spacing={1} alignItems="center" sx={{ px: 1.5, py: 0.75, flexWrap: 'wrap', rowGap: 0.75 }}>
        {searchable ? (
          <TextField
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder={searchPlaceholder}
            sx={{ width: 260 }}
            inputProps={{ 'aria-label': searchPlaceholder }}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 15, color: color.muted }} /></InputAdornment> }}
          />
        ) : null}
        {toolbarExtras}
        <Box sx={{ flex: 1 }} />
        <Typography sx={{ fontSize: font.size.small, color: color.muted }}>
          {error ? '—' : `${rowCount.toLocaleString('en-IN')} rows`}{debouncedQ ? ` · “${debouncedQ}”` : ''} · server-paged
        </Typography>
        <Button startIcon={<ViewColumnIcon sx={{ fontSize: 15 }} />} onClick={(e) => setColAnchor(e.currentTarget)}>Columns</Button>
        <Menu anchorEl={colAnchor} open={Boolean(colAnchor)} onClose={() => setColAnchor(null)}>
          {columns.map((c) => (
            <MenuItem key={c.field} onClick={() => setHidden((hh) => (hh.includes(c.field) ? hh.filter((x) => x !== c.field) : [...hh, c.field]))}>
              <Checkbox checked={!hidden.includes(c.field)} sx={{ p: 0, mr: 1 }} />
              <ListItemText primary={c.headerName ?? c.field} />
            </MenuItem>
          ))}
        </Menu>
      </Stack>
      <Box sx={{ width: '100%' }}>
        <DataGrid
          rows={error ? [] : rows}
          columns={visibleColumns}
          loading={loading}
          density="compact"
          rowHeight={layout.rowHeight}
          columnHeaderHeight={layout.headerHeight}
          autoHeight
          disableRowSelectionOnClick
          onRowClick={onRowClick ? (p: GridRowParams) => onRowClick(p.row) : undefined}
          getRowClassName={rowClassName ? (p: GridRowClassNameParams) => rowClassName(p.row) ?? '' : undefined}
          paginationMode="server"
          rowCount={rowCount}
          paginationModel={model}
          onPaginationModelChange={setModel}
          pageSizeOptions={[25, 50, 100, 200]}
          sx={{ ...dataGridSx, cursor: onRowClick ? 'pointer' : 'default' }}
          slots={{ noRowsOverlay: () => <EmptyState title={error ?? emptyTitle} detail={error ? 'The list could not be loaded.' : emptyDetail} /> }}
          aria-label={endpoint}
        />
      </Box>
    </Box>
  );
}
