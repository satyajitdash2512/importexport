import * as React from 'react';
import { Box, Stack, TextField, Button, Typography, Menu, MenuItem, Checkbox, ListItemText, InputAdornment } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import ViewColumnIcon from '@mui/icons-material/ViewColumn';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import { DataGrid, type GridColDef, type GridRowParams, type GridRowClassNameParams } from '@mui/x-data-grid';
import { color, font, layout } from '../context/tokens';
import { dataGridSx } from '../context/hostbooksTheme';
import { EmptyState } from './primitives';

export interface DataTableProps<T extends { id: string }> {
  rows: T[];
  columns: GridColDef[];
  loading?: boolean;
  onRowClick?: (row: T) => void;
  /** Free-text search across these fields. */
  searchFields?: string[];
  searchPlaceholder?: string;
  toolbarExtras?: React.ReactNode;
  height?: number | string;
  rowClassName?: (row: T) => string | undefined;
  emptyTitle?: string;
  emptyDetail?: string;
  exportName?: string;
  initialPageSize?: number;
  /** Column fields hidden by default; user can restore them from the column menu. */
  hiddenByDefault?: string[];
}

export function DataTable<T extends { id: string }>({
  rows, columns, loading, onRowClick, searchFields, searchPlaceholder = 'Search',
  toolbarExtras, height = 'auto', rowClassName, emptyTitle = 'Nothing to show',
  emptyDetail, exportName = 'export', initialPageSize = 25, hiddenByDefault = [],
}: DataTableProps<T>) {
  const [q, setQ] = React.useState('');
  const [colAnchor, setColAnchor] = React.useState<null | HTMLElement>(null);
  const [hidden, setHidden] = React.useState<string[]>(hiddenByDefault);

  const filtered = React.useMemo(() => {
    if (!q || !searchFields?.length) return rows;
    const needle = q.toLowerCase();
    return rows.filter((r) => searchFields.some((f) => String((r as any)[f] ?? '').toLowerCase().includes(needle)));
  }, [rows, q, searchFields]);

  const visibleColumns = columns.filter((c) => !hidden.includes(c.field));

  const exportCsv = () => {
    const head = visibleColumns.map((c) => `"${String(c.headerName ?? c.field).replace(/"/g, '""')}"`).join(',');
    const body = filtered.map((r) =>
      visibleColumns.map((c) => {
        const raw = c.valueGetter ? (c.valueGetter as any)({ row: r, value: (r as any)[c.field] }) : (r as any)[c.field];
        return `"${String(raw ?? '').replace(/"/g, '""')}"`;
      }).join(','),
    ).join('\n');
    const blob = new Blob([`${head}\n${body}`], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `${exportName}.csv`; a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <Box sx={{ bgcolor: color.surface }}>
      <Stack direction="row" spacing={1} alignItems="center" sx={{ px: 1.5, py: 0.75, flexWrap: 'wrap', rowGap: 0.75 }}>
        {searchFields?.length ? (
          <TextField
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder={searchPlaceholder}
            sx={{ width: 240 }}
            inputProps={{ 'aria-label': searchPlaceholder }}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 15, color: color.muted }} /></InputAdornment> }}
          />
        ) : null}
        {toolbarExtras}
        <Box sx={{ flex: 1 }} />
        <Typography sx={{ fontSize: font.size.small, color: color.muted }}>
          {filtered.length === rows.length ? `${rows.length} rows` : `${filtered.length} of ${rows.length} rows`}
        </Typography>
        <Button startIcon={<ViewColumnIcon sx={{ fontSize: 15 }} />} onClick={(e) => setColAnchor(e.currentTarget)}>Columns</Button>
        <Menu anchorEl={colAnchor} open={Boolean(colAnchor)} onClose={() => setColAnchor(null)}>
          {columns.map((c) => (
            <MenuItem
              key={c.field}
              onClick={() => setHidden((h) => (h.includes(c.field) ? h.filter((x) => x !== c.field) : [...h, c.field]))}
            >
              <Checkbox checked={!hidden.includes(c.field)} sx={{ p: 0, mr: 1 }} />
              <ListItemText primary={c.headerName ?? c.field} />
            </MenuItem>
          ))}
        </Menu>
        <Button startIcon={<FileDownloadIcon sx={{ fontSize: 15 }} />} onClick={exportCsv}>Export</Button>
      </Stack>
      <Box sx={{ height, width: '100%' }}>
        <DataGrid
          rows={filtered}
          columns={visibleColumns}
          loading={loading}
          density="compact"
          rowHeight={layout.rowHeight}
          columnHeaderHeight={layout.headerHeight}
          autoHeight={height === 'auto'}
          disableRowSelectionOnClick
          onRowClick={onRowClick ? (p: GridRowParams) => onRowClick(p.row as T) : undefined}
          getRowClassName={rowClassName ? (p: GridRowClassNameParams) => rowClassName(p.row as T) ?? '' : undefined}
          initialState={{ pagination: { paginationModel: { pageSize: initialPageSize } } }}
          pageSizeOptions={[10, 25, 50, 100]}
          sx={{ ...dataGridSx, cursor: onRowClick ? 'pointer' : 'default' }}
          slots={{
            noRowsOverlay: () => <EmptyState title={emptyTitle} detail={emptyDetail} />,
          }}
          aria-label={exportName}
        />
      </Box>
    </Box>
  );
}

export type { GridColDef };
