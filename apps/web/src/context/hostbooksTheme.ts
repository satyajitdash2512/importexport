import { createTheme, alpha } from '@mui/material/styles';
import { color, font, shape, layout, elevation } from './tokens';

/**
 * MUI theme that renders the HostBooks product language:
 *   flat surfaces · dense rows · pill tabs · filled blue KPI tiles ·
 *   outlined blue buttons · hairline borders instead of shadows.
 *
 * All values come from ./tokens.ts — do not add literal colours here.
 */
export const hostbooksTheme = createTheme({
  palette: {
    mode: 'light',
    primary: { main: color.primary, dark: color.primaryDark, light: color.primaryTile, contrastText: color.onPrimary },
    secondary: { main: color.primaryTile, contrastText: color.onPrimary },
    success: { main: color.success, light: color.successSoft },
    warning: { main: color.warning, light: color.warningSoft },
    error: { main: color.danger, light: color.dangerSoft },
    info: { main: color.info, light: color.infoSoft },
    background: { default: color.canvas, paper: color.surface },
    text: { primary: color.text, secondary: color.muted, disabled: alpha(color.text, 0.38) },
    divider: color.border,
  },
  shape: { borderRadius: shape.radius },
  typography: {
    fontFamily: font.family,
    fontSize: font.size.body,
    htmlFontSize: 16,
    h1: { fontSize: font.size.pageTitle, fontWeight: font.weight.semibold, color: color.primary, lineHeight: 1.3 },
    h2: { fontSize: font.size.sectionTitle, fontWeight: font.weight.semibold, color: color.text, lineHeight: 1.35 },
    h3: { fontSize: 14, fontWeight: font.weight.semibold, color: color.text },
    h4: { fontSize: 13, fontWeight: font.weight.semibold, color: color.label },
    subtitle1: { fontSize: 13, fontWeight: font.weight.semibold, color: color.text },
    subtitle2: { fontSize: font.size.label, fontWeight: font.weight.bold, color: color.label },
    body1: { fontSize: font.size.body, color: color.text },
    body2: { fontSize: font.size.label, color: color.text },
    caption: { fontSize: font.size.small, color: color.muted },
    button: { fontSize: font.size.label, fontWeight: font.weight.semibold, textTransform: 'none', letterSpacing: 0 },
  },
  shadows: [
    'none', elevation.popover, elevation.popover, elevation.popover, elevation.overlay,
    elevation.overlay, elevation.overlay, elevation.overlay, elevation.overlay, elevation.overlay,
    elevation.overlay, elevation.overlay, elevation.overlay, elevation.overlay, elevation.overlay,
    elevation.overlay, elevation.overlay, elevation.overlay, elevation.overlay, elevation.overlay,
    elevation.overlay, elevation.overlay, elevation.overlay, elevation.overlay, elevation.overlay,
  ] as any,
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        'html, body, #root': { height: '100%' },
        body: { backgroundColor: color.canvas, color: color.text, fontSize: font.size.body },
        '*::-webkit-scrollbar': { width: 10, height: 10 },
        '*::-webkit-scrollbar-thumb': { background: color.borderStrong, borderRadius: 5 },
        '*::-webkit-scrollbar-track': { background: color.band },
        ':focus-visible': { outline: `2px solid ${color.primary}`, outlineOffset: 1 },
        a: { color: color.primary, textDecorationColor: alpha(color.primary, 0.4) },
      },
    },
    MuiPaper: {
      defaultProps: { elevation: 0 },
      styleOverrides: {
        root: { backgroundImage: 'none' },
        outlined: { border: shape.border },
      },
    },
    MuiCard: {
      defaultProps: { elevation: 0, variant: 'outlined' },
      styleOverrides: { root: { border: shape.border, borderRadius: shape.radius } },
    },
    MuiCardHeader: {
      styleOverrides: {
        root: { padding: '8px 12px', borderBottom: shape.border, backgroundColor: color.surface },
        title: { fontSize: font.size.sectionTitle, fontWeight: font.weight.semibold, color: color.text },
        subheader: { fontSize: font.size.small, color: color.muted },
        action: { margin: 0, alignSelf: 'center' },
      },
    },
    MuiCardContent: { styleOverrides: { root: { padding: 12, '&:last-child': { paddingBottom: 12 } } } },
    MuiButton: {
      defaultProps: { size: 'small', variant: 'outlined', disableElevation: true },
      styleOverrides: {
        root: { borderRadius: shape.radius, minHeight: 28, padding: '3px 12px', whiteSpace: 'nowrap' },
        outlinedPrimary: {
          borderColor: color.primaryBorder, color: color.primary, backgroundColor: color.surface,
          '&:hover': { borderColor: color.primary, backgroundColor: color.primarySoft },
        },
        containedPrimary: {
          backgroundColor: color.primary, color: color.onPrimary,
          '&:hover': { backgroundColor: color.primaryDark },
        },
        textPrimary: { '&:hover': { backgroundColor: color.primarySoft } },
        sizeSmall: { fontSize: font.size.label },
      },
    },
    MuiIconButton: { defaultProps: { size: 'small' }, styleOverrides: { root: { borderRadius: shape.radius } } },
    MuiTabs: {
      styleOverrides: {
        root: { minHeight: 34, borderBottom: shape.border },
        indicator: { display: 'none' },
        flexContainer: { gap: 2 },
        scrollButtons: { width: 24 },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: {
          minHeight: 28, minWidth: 0, padding: '4px 10px', margin: '3px 0',
          fontSize: font.size.label, fontWeight: font.weight.medium, textTransform: 'none',
          color: color.text, borderRadius: shape.radius, border: '1px solid transparent',
          '&:hover': { backgroundColor: color.primarySoft, color: color.primary },
          '&.Mui-selected': {
            color: color.primary, backgroundColor: color.primarySoft,
            border: `1px solid ${color.primaryBorder}`, fontWeight: font.weight.semibold,
          },
        },
      },
    },
    MuiChip: {
      defaultProps: { size: 'small' },
      styleOverrides: {
        root: { borderRadius: shape.radiusSm, height: 20, fontSize: font.size.small, fontWeight: font.weight.semibold },
        label: { padding: '0 6px' },
        outlined: { backgroundColor: color.surface },
      },
    },
    MuiTextField: { defaultProps: { size: 'small', variant: 'outlined' } },
    MuiOutlinedInput: {
      styleOverrides: {
        root: { borderRadius: shape.radius, backgroundColor: color.surface, fontSize: font.size.body },
        input: { padding: '5px 8px', fontSize: font.size.body },
        notchedOutline: { borderColor: color.border },
      },
    },
    MuiInputLabel: { styleOverrides: { root: { fontSize: font.size.body } }, defaultProps: { shrink: true } },
    MuiSelect: { defaultProps: { size: 'small' } },
    MuiMenuItem: { styleOverrides: { root: { fontSize: font.size.body, minHeight: 28 } } },
    MuiFormControl: { defaultProps: { size: 'small' } },
    MuiFormControlLabel: { styleOverrides: { label: { fontSize: font.size.body } } },
    MuiCheckbox: { defaultProps: { size: 'small' } },
    MuiRadio: { defaultProps: { size: 'small' } },
    MuiSwitch: { defaultProps: { size: 'small' } },
    MuiTable: { defaultProps: { size: 'small' } },
    MuiTableCell: {
      styleOverrides: {
        root: { fontSize: font.size.table, padding: '5px 8px', borderBottom: `1px solid ${color.border}` },
        head: { backgroundColor: color.tableHeader, fontWeight: font.weight.bold, color: color.label, whiteSpace: 'nowrap' },
        footer: { fontSize: font.size.table, fontWeight: font.weight.bold, color: color.text, borderTop: `1px solid ${color.borderStrong}` },
      },
    },
    MuiTableRow: { styleOverrides: { root: { '&:hover': { backgroundColor: color.primarySoft } } } },
    MuiTooltip: {
      styleOverrides: {
        tooltip: { fontSize: font.size.small, backgroundColor: color.text, borderRadius: shape.radiusSm, padding: '4px 8px' },
      },
    },
    MuiDialog: { styleOverrides: { paper: { borderRadius: shape.radius, border: shape.border } } },
    MuiDialogTitle: { styleOverrides: { root: { fontSize: font.size.sectionTitle, fontWeight: font.weight.semibold, color: color.primary, padding: '10px 14px', borderBottom: shape.border } } },
    MuiDialogContent: { styleOverrides: { root: { padding: 14 } } },
    MuiDialogActions: { styleOverrides: { root: { padding: '8px 14px', borderTop: shape.border } } },
    MuiAlert: {
      styleOverrides: {
        root: { borderRadius: shape.radius, fontSize: font.size.body, padding: '4px 10px', alignItems: 'center' },
        standardError: { backgroundColor: color.dangerSoft, color: color.danger },
        standardWarning: { backgroundColor: color.warningSoft, color: color.warning },
        standardSuccess: { backgroundColor: color.successSoft, color: color.success },
        standardInfo: { backgroundColor: color.infoSoft, color: color.primary },
      },
    },
    MuiDivider: { styleOverrides: { root: { borderColor: color.border } } },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          minHeight: 30, paddingTop: 2, paddingBottom: 2, borderRadius: shape.radius, fontSize: font.size.body,
          '&.Mui-selected': { backgroundColor: color.primarySoft, color: color.primary, '&:hover': { backgroundColor: color.primarySoft } },
        },
      },
    },
    MuiListItemText: { styleOverrides: { primary: { fontSize: font.size.body }, secondary: { fontSize: font.size.small } } },
    MuiListItemIcon: { styleOverrides: { root: { minWidth: 28, color: 'inherit' } } },
    MuiBreadcrumbs: { styleOverrides: { root: { fontSize: font.size.small }, separator: { marginLeft: 4, marginRight: 4 } } },
    MuiLinearProgress: { styleOverrides: { root: { height: 6, borderRadius: 3, backgroundColor: color.band } } },
    MuiAccordion: {
      defaultProps: { disableGutters: true, elevation: 0 },
      styleOverrides: { root: { border: shape.border, '&:before': { display: 'none' } } },
    },
    MuiAccordionSummary: { styleOverrides: { root: { minHeight: 34, '&.Mui-expanded': { minHeight: 34 } }, content: { margin: '6px 0', '&.Mui-expanded': { margin: '6px 0' } } } },
    MuiStepLabel: { styleOverrides: { label: { fontSize: font.size.label } } },
    MuiToggleButton: { styleOverrides: { root: { padding: '2px 8px', fontSize: font.size.label, textTransform: 'none' } } },
    MuiSkeleton: { styleOverrides: { root: { backgroundColor: color.band } } },
  },
});

export const dataGridSx = {
  border: 'none',
  fontSize: font.size.table,
  '& .MuiDataGrid-columnHeaders': {
    backgroundColor: color.tableHeader,
    borderBottom: `1px solid ${color.borderStrong}`,
    minHeight: `${layout.headerHeight}px !important`,
    maxHeight: `${layout.headerHeight}px !important`,
  },
  '& .MuiDataGrid-columnHeaderTitle': { fontWeight: font.weight.bold, color: color.label, fontSize: font.size.table },
  '& .MuiDataGrid-cell': { borderBottom: `1px solid ${color.border}`, paddingLeft: '8px', paddingRight: '8px' },
  '& .MuiDataGrid-row:hover': { backgroundColor: color.primarySoft },
  '& .MuiDataGrid-row.Mui-selected': { backgroundColor: color.primarySoft },
  '& .MuiDataGrid-footerContainer': { minHeight: 34, borderTop: `1px solid ${color.border}` },
  '& .MuiTablePagination-root': { fontSize: font.size.small },
  '& .MuiDataGrid-overlay': { fontSize: font.size.body, color: color.muted },
  '& .MuiDataGrid-columnSeparator': { color: color.border },
  '& .row-severity-critical': { borderLeft: `3px solid ${color.danger}` },
  '& .row-severity-high': { borderLeft: `3px solid ${color.warning}` },
  '& .row-severity-medium': { borderLeft: `3px solid ${color.info}` },
} as const;
