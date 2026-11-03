-- ============================================================================
--  HB TRADE — 005 UI DISPLAY FIELDS
--
--  The RD-normalized schema (001–004) stores codes and foreign keys. A few
--  screens display free text that a code cannot round-trip: the exact bank
--  name printed on a letter of credit, the descriptive declaration type as the
--  authority worded it, a human-readable pipeline stage label. These are added
--  here as nullable columns so the relational detail endpoints reproduce the
--  screens exactly without a lossy code→label lookup. They are display-only:
--  no logic keys off them.
-- ============================================================================

SET NAMES utf8mb4;

-- Instruments carry counterparties that are not trade_party rows (the applicant
-- is often our own entity; correspondent banks are not maintained as parties).
ALTER TABLE instrument
  ADD COLUMN issuing_bank_name  VARCHAR(160) NULL AFTER issuing_bank_id,
  ADD COLUMN advising_bank_name VARCHAR(160) NULL AFTER advising_bank_id,
  ADD COLUMN applicant_name     VARCHAR(200) NULL AFTER applicant_party_id,
  ADD COLUMN beneficiary_name   VARCHAR(200) NULL AFTER beneficiary_party_id,
  ADD COLUMN type_label         VARCHAR(120) NULL,
  ADD COLUMN status_label       VARCHAR(80)  NULL,
  ADD COLUMN payment_note       VARCHAR(200) NULL;

-- The declaration type as worded by the authority is longer than a code and is
-- shown verbatim; the ENUM status carries a descriptive label for the screen.
ALTER TABLE declaration
  ADD COLUMN type_label   VARCHAR(160) NULL AFTER declaration_type,
  ADD COLUMN status_label VARCHAR(80)  NULL AFTER status;

-- Human-readable pipeline stage and workflow status as shown on Shipment 360.
ALTER TABLE shipment
  ADD COLUMN stage_label  VARCHAR(80) NULL AFTER stage;

-- Licence scheme label and obligation phrasing shown on the obligation ledger.
ALTER TABLE licence
  ADD COLUMN scheme_label      VARCHAR(120) NULL,
  ADD COLUMN obligation_label  VARCHAR(160) NULL,
  ADD COLUMN status_label      VARCHAR(80)  NULL;

-- Cost line descriptive status (e.g. "Variance beyond tolerance") shown on the
-- landed-cost sheet; the ENUM status remains the queryable one.
ALTER TABLE cost_line
  ADD COLUMN status_label VARCHAR(120) NULL;

-- Voucher status label (the UI uses lower-case lifecycle names) and book label.
ALTER TABLE voucher
  ADD COLUMN book_label VARCHAR(40) NULL;
