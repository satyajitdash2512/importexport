import * as React from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { Box, Button } from '@mui/material';
import { AppShell } from '../layouts/AppShell';
import { EmptyState, PageHeader } from '../components/primitives';
import { screens } from '../config/screenRegistry';
import { GenericScreen } from '../features/generic/components/GenericScreen';
import { useAuth } from '../context/AuthContext';
import { Login } from '../features/auth/components/Login';

import CockpitScreen from '../features/cockpit/components/Cockpit';
import Shipment360 from '../features/trade/components/Shipment360';
import DeclarationWorkbench from '../features/trade/components/DeclarationWorkbench';
import LandedCostSheet from '../features/accounting/components/LandedCostSheet';
import ObligationLedger from '../features/trade/components/ObligationLedger';
import { VoucherEntry, VoucherDetail } from '../features/accounting/components/VoucherEntry';
import {
  TrialBalance, CloseChecklist, ReconciliationList, ReconciliationDetail,
  ComplianceMonitor, BankPresentation, ScreeningReview,
} from '../features/accounting/components/AccountingScreens';
import { AdminUsers, Tenants, Periods, Integrations, AuditLog } from '../features/admin/components/Admin';

function NotFound() {
  const loc = useLocation();
  return (
    <Box>
      <PageHeader title="Screen not found" subtitle={loc.pathname} onBack />
      <EmptyState
        title="No screen is mapped to this route"
        detail="Every route in the navigation is implemented. If you reached this from a link, the link target is wrong."
        action={<Button variant="contained" href="/">Return to the cockpit</Button>}
      />
    </Box>
  );
}

export default function AppRoutes() {
  const { user } = useAuth();
  if (!user) return <Login />;
  return (
    <AppShell>
      <Routes>
        {/* ---------------------------------------------- flagship screens */}
        <Route path="/" element={<CockpitScreen />} />

        <Route path="/import/shipments/:id" element={<Shipment360 />} />
        <Route path="/export/shipments/:id" element={<Shipment360 />} />
        <Route path="/import/declarations/:id" element={<DeclarationWorkbench />} />
        <Route path="/export/declarations/:id" element={<DeclarationWorkbench />} />
        <Route path="/finance/landed-cost/:id" element={<LandedCostSheet />} />
        <Route path="/compliance/licences/:id" element={<ObligationLedger />} />
        <Route path="/compliance/monitor" element={<ComplianceMonitor />} />
        <Route path="/compliance/screening" element={<ScreeningReview />} />
        <Route path="/finance/presentations/:id" element={<BankPresentation />} />
        <Route path="/finance/instruments/:id" element={<BankPresentation />} />

        <Route path="/accounting/vouchers/new" element={<VoucherEntry />} />
        <Route path="/accounting/vouchers/:id" element={<VoucherDetail />} />
        <Route path="/accounting/trial-balance" element={<TrialBalance />} />
        <Route path="/close/checklist" element={<CloseChecklist />} />
        <Route path="/close/reconciliations" element={<ReconciliationList />} />
        <Route path="/close/reconciliations/:id" element={<ReconciliationDetail />} />

        {/* ------------------------------------------- administration */}
        <Route path="/admin/users" element={<AdminUsers />} />
        <Route path="/admin/tenants" element={<Tenants />} />
        <Route path="/accounting/periods" element={<Periods />} />
        <Route path="/admin/integrations" element={<Integrations />} />
        <Route path="/admin/audit" element={<AuditLog />} />

        {/* ------------------------------------- registry-driven screens */}
        {screens.map((s) => (
          <Route key={s.path} path={s.path} element={<GenericScreen spec={s} />} />
        ))}

        {/* ----------------------------------------------------- aliases */}
        <Route path="/import/orders/:id" element={<Navigate to="/import/orders" replace />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </AppShell>
  );
}
