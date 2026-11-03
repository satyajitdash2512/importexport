-- ============================================================================
--  HB TRADE — 007 DENORMALIZED VOUCHER ACTOR NAMES
--
--  Under database-per-tenant, users live in the control database while vouchers
--  live in the tenant database, so a voucher cannot JOIN app_user for the
--  preparer/approver name. The display names are denormalized onto the voucher
--  at write time (the numeric prepared_by/approved_by remain the source of
--  truth in the control plane).
-- ============================================================================

SET NAMES utf8mb4;

ALTER TABLE voucher
  ADD COLUMN prepared_by_name VARCHAR(200) NULL AFTER prepared_by,
  ADD COLUMN approved_by_name VARCHAR(200) NULL AFTER approved_by;
