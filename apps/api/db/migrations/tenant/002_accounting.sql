-- ============================================================================
--  HB TRADE — 002 ACCOUNTING CORE
--
--  This is where volume lives. Design decisions for 250M posting lines:
--
--  1. posting_line and voucher are RANGE-partitioned on period_key (YYYYMM as
--     INT). A trial balance, ledger enquiry or register for one period touches
--     one partition. Dropping an archived year is a metadata operation.
--     MySQL requires every UNIQUE/PK to contain the partitioning column, so the
--     PK is (period_key, id) and `id` alone is covered by a non-unique index.
--
--  2. account_period_balance is a rollup maintained inside the posting
--     transaction. The trial balance NEVER aggregates posting_line: it reads
--     one row per account per period. This is the difference between a 40 ms
--     trial balance and a 4 minute one.
--
--  3. Dimensions are denormalised onto posting_line as FK columns rather than a
--     key/value side table. An EAV dimension table would triple the row count
--     and make every analytical query a pivot.
--
--  4. Money is DECIMAL(20,4); three currency amounts are stored (transaction,
--     functional, group) so no downstream process re-derives them.
-- ============================================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------ chart of accounts ---
CREATE TABLE gl_account (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id         BIGINT UNSIGNED NOT NULL,
  code              VARCHAR(20)  NOT NULL,
  name              VARCHAR(200) NOT NULL,
  account_class     ENUM('ASSET','LIABILITY','EQUITY','INCOME','EXPENSE') NOT NULL,
  account_type      ENUM('ORDINARY','CONTROL','CLEARING','MEMORANDUM','STATISTICAL') NOT NULL DEFAULT 'ORDINARY',
  account_group     VARCHAR(80)  NOT NULL,
  schedule_iii_group VARCHAR(160) NULL,
  cash_flow_class   ENUM('OPERATING','INVESTING','FINANCING','NONE') NOT NULL DEFAULT 'NONE',
  subledger         ENUM('NONE','AP','AR','BANK','INVENTORY','TAX','ASSET','INSTRUMENT','ENTITLEMENT','BONDED','OBLIGATION') NOT NULL DEFAULT 'NONE',
  is_monetary       TINYINT(1)   NOT NULL DEFAULT 0,   -- restated at closing rate
  manual_posting_allowed TINYINT(1) NOT NULL DEFAULT 0,
  mandatory_dimensions VARCHAR(200) NOT NULL DEFAULT '',
  recon_frequency   ENUM('NONE','DAILY','WEEKLY','MONTHLY','QUARTERLY') NOT NULL DEFAULT 'NONE',
  currency          CHAR(3)      NULL,                 -- NULL = multi-currency
  is_blocked        TINYINT(1)   NOT NULL DEFAULT 0,
  valid_from        DATE         NOT NULL,
  valid_to          DATE         NULL,
  row_version       INT UNSIGNED NOT NULL DEFAULT 1,
  created_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_account (entity_id, code),
  KEY ix_account_group (entity_id, account_group),
  KEY ix_account_type (entity_id, account_type),
  KEY ix_account_subledger (entity_id, subledger),
  CONSTRAINT fk_acct_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- --------------------------------------------------------- books & periods ---
CREATE TABLE book (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id  BIGINT UNSIGNED NOT NULL,
  code       VARCHAR(20)  NOT NULL,
  name       VARCHAR(80)  NOT NULL,
  basis      ENUM('PRIMARY','TAX','GROUP','MEMORANDUM') NOT NULL,
  gaap       ENUM('IND_AS','AS','IFRS','TAX','NA') NOT NULL DEFAULT 'IND_AS',
  is_active  TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_book (entity_id, code),
  CONSTRAINT fk_book_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

CREATE TABLE accounting_period (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id   BIGINT UNSIGNED NOT NULL,
  book_id     BIGINT UNSIGNED NOT NULL,
  period_key  INT UNSIGNED NOT NULL,        -- YYYYMM
  fiscal_year VARCHAR(9)   NOT NULL,        -- 2026-27
  starts_on   DATE         NOT NULL,
  ends_on     DATE         NOT NULL,
  status      ENUM('OPEN','SOFT_CLOSED','HARD_CLOSED') NOT NULL DEFAULT 'OPEN',
  locked_by   BIGINT UNSIGNED NULL,
  locked_at   DATETIME(3)  NULL,
  lock_override_reason VARCHAR(1000) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_period (entity_id, book_id, period_key),
  KEY ix_period_status (entity_id, status),
  CONSTRAINT fk_period_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_period_book FOREIGN KEY (book_id) REFERENCES book (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------- voucher config ---
CREATE TABLE voucher_type (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id          BIGINT UNSIGNED NOT NULL,
  code               VARCHAR(10)  NOT NULL,
  name               VARCHAR(160) NOT NULL,
  document_class     ENUM('FINANCIAL','INVENTORY','STATUTORY','MEMORANDUM') NOT NULL,
  statutory_series   TINYINT(1)   NOT NULL DEFAULT 0,
  posts_on           ENUM('SAVE','APPROVAL') NOT NULL DEFAULT 'APPROVAL',
  reversible         TINYINT(1)   NOT NULL DEFAULT 1,
  required_evidence  VARCHAR(600) NOT NULL DEFAULT '',
  approval_matrix    VARCHAR(300) NULL,
  print_format       VARCHAR(120) NULL,
  retention_years    TINYINT UNSIGNED NOT NULL DEFAULT 8,
  books              VARCHAR(80)  NOT NULL DEFAULT 'PRIMARY',
  allow_soft_closed  TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vtype (entity_id, code),
  CONSTRAINT fk_vt_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- Gapless statutory numbering. next_no is bumped under SELECT ... FOR UPDATE
-- inside the posting transaction, so the number is allocated at POSTING, never
-- at creation (HBIE-VCH-011).
CREATE TABLE number_series (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  voucher_type_id BIGINT UNSIGNED NOT NULL,
  site_id        BIGINT UNSIGNED NULL,
  gstin          VARCHAR(15)  NULL,
  book_id        BIGINT UNSIGNED NULL,
  fiscal_year    VARCHAR(9)   NOT NULL,
  prefix         VARCHAR(30)  NOT NULL,
  suffix         VARCHAR(20)  NOT NULL DEFAULT '',
  width          TINYINT UNSIGNED NOT NULL DEFAULT 5,
  next_no        BIGINT UNSIGNED NOT NULL DEFAULT 1,
  is_gapless     TINYINT(1)   NOT NULL DEFAULT 1,
  is_active      TINYINT(1)   NOT NULL DEFAULT 1,
  -- MySQL treats NULLs as distinct in a UNIQUE index, so an entity-wide series
  -- (site_id NULL) could be inserted twice. Collapse NULL to 0 in a stored
  -- generated column and make THAT part of the key.
  site_key       BIGINT UNSIGNED
                 GENERATED ALWAYS AS (IFNULL(site_id, 0)) STORED NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_series (entity_id, voucher_type_id, fiscal_year, site_key),
  CONSTRAINT fk_ns_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_ns_vt FOREIGN KEY (voucher_type_id) REFERENCES voucher_type (id)
) ENGINE=InnoDB;

-- Posting rules: declarative, versioned, effective dated (HBIE-ACC-060).
CREATE TABLE posting_rule (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  code           VARCHAR(30)  NOT NULL,
  version        VARCHAR(10)  NOT NULL,
  business_event VARCHAR(60)  NOT NULL,
  voucher_type_code VARCHAR(10) NOT NULL,
  book_code      VARCHAR(20)  NOT NULL DEFAULT 'PRIMARY',
  description    VARCHAR(400) NOT NULL,
  standard_ref   VARCHAR(120) NULL,
  gaap_dependent TINYINT(1)   NOT NULL DEFAULT 0,
  effective_from DATE         NOT NULL,
  effective_to   DATE         NULL,
  prepared_by    BIGINT UNSIGNED NULL,
  approved_by    BIGINT UNSIGNED NULL,
  approved_at    DATETIME(3)  NULL,
  test_result    ENUM('PASSED','FAILED','NOT_RUN') NOT NULL DEFAULT 'NOT_RUN',
  is_active      TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rule (entity_id, code, version),
  KEY ix_rule_event (entity_id, business_event, book_code, effective_from DESC),
  CONSTRAINT fk_pr_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

CREATE TABLE posting_rule_line (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rule_id       BIGINT UNSIGNED NOT NULL,
  seq_no        SMALLINT UNSIGNED NOT NULL,
  dr_cr         ENUM('DR','CR') NOT NULL,
  account_key   VARCHAR(40)  NOT NULL,   -- resolved via account_determination
  amount_key    VARCHAR(40)  NOT NULL,
  tax_code      VARCHAR(30)  NULL,
  condition_expr VARCHAR(300) NULL,
  branch_note   VARCHAR(200) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_prl (rule_id, seq_no),
  CONSTRAINT fk_prl_rule FOREIGN KEY (rule_id) REFERENCES posting_rule (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Account determination: never a literal account number in code (HBIE-ACC-060).
CREATE TABLE account_determination (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id    BIGINT UNSIGNED NOT NULL,
  account_key  VARCHAR(40)  NOT NULL,
  qualifier    VARCHAR(60)  NOT NULL DEFAULT '*',  -- item group / party group / levy code / charge code
  account_id   BIGINT UNSIGNED NOT NULL,
  valid_from   DATE         NOT NULL,
  valid_to     DATE         NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ad (entity_id, account_key, qualifier, valid_from),
  CONSTRAINT fk_ad_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_ad_account FOREIGN KEY (account_id) REFERENCES gl_account (id)
) ENGINE=InnoDB;

-- =========================================================================
--  VOUCHER — partitioned by period_key
-- =========================================================================
CREATE TABLE voucher (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  period_key        INT UNSIGNED NOT NULL,
  entity_id         BIGINT UNSIGNED NOT NULL,
  book_id           BIGINT UNSIGNED NOT NULL,
  voucher_type_id   BIGINT UNSIGNED NOT NULL,
  voucher_no        VARCHAR(40)  NULL,       -- NULL while parked: allocated at posting
  voucher_date      DATE         NOT NULL,
  narration         VARCHAR(1000) NOT NULL,
  status            ENUM('PARKED','PENDING_APPROVAL','POSTED','REVERSED','CANCELLED') NOT NULL DEFAULT 'PARKED',
  source_type       VARCHAR(40)  NULL,
  source_id         BIGINT UNSIGNED NULL,
  business_event    VARCHAR(60)  NULL,
  posting_rule_code VARCHAR(30)  NULL,
  posting_rule_version VARCHAR(10) NULL,
  currency          CHAR(3)      NOT NULL DEFAULT 'INR',
  fx_rate           DECIMAL(18,8) NOT NULL DEFAULT 1,
  total_dr          DECIMAL(20,4) NOT NULL DEFAULT 0,
  total_cr          DECIMAL(20,4) NOT NULL DEFAULT 0,
  prepared_by       BIGINT UNSIGNED NOT NULL,
  approved_by       BIGINT UNSIGNED NULL,
  posted_at         DATETIME(3)  NULL,
  reversal_of_id    BIGINT UNSIGNED NULL,
  reversed_by_id    BIGINT UNSIGNED NULL,
  cancel_reason     VARCHAR(500) NULL,
  evidence_complete TINYINT(1)   NOT NULL DEFAULT 0,
  row_version       INT UNSIGNED NOT NULL DEFAULT 1,
  created_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (period_key, id),
  KEY ix_voucher_id (id),
  UNIQUE KEY uq_voucher_no (entity_id, voucher_type_id, voucher_no, period_key),
  KEY ix_voucher_register (entity_id, period_key, voucher_type_id, status),
  KEY ix_voucher_status (entity_id, status, voucher_date),
  KEY ix_voucher_source (source_type, source_id),
  KEY ix_voucher_date (entity_id, voucher_date, id)
) ENGINE=InnoDB
PARTITION BY RANGE (period_key) (
  PARTITION p2025 VALUES LESS THAN (202601),
  PARTITION p202601 VALUES LESS THAN (202602),
  PARTITION p202602 VALUES LESS THAN (202603),
  PARTITION p202603 VALUES LESS THAN (202604),
  PARTITION p202604 VALUES LESS THAN (202605),
  PARTITION p202605 VALUES LESS THAN (202606),
  PARTITION p202606 VALUES LESS THAN (202607),
  PARTITION p202607 VALUES LESS THAN (202608),
  PARTITION p202608 VALUES LESS THAN (202609),
  PARTITION p202609 VALUES LESS THAN (202610),
  PARTITION p202610 VALUES LESS THAN (202611),
  PARTITION p202611 VALUES LESS THAN (202612),
  PARTITION p202612 VALUES LESS THAN (202701),
  PARTITION p2027 VALUES LESS THAN (202801),
  PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- =========================================================================
--  POSTING LINE — the big table. 250M rows at target volume.
--  Dimensions are real columns, not EAV. Covering indexes serve the ledger
--  enquiry and the reconciliation queries without touching the clustered row.
-- =========================================================================
CREATE TABLE posting_line (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  period_key      INT UNSIGNED NOT NULL,
  voucher_id      BIGINT UNSIGNED NOT NULL,
  entity_id       BIGINT UNSIGNED NOT NULL,
  book_id         BIGINT UNSIGNED NOT NULL,
  line_no         SMALLINT UNSIGNED NOT NULL,
  account_id      BIGINT UNSIGNED NOT NULL,
  dr_cr           ENUM('DR','CR') NOT NULL,
  amount_txn      DECIMAL(20,4) NOT NULL,
  amount_func     DECIMAL(20,4) NOT NULL,
  amount_group    DECIMAL(20,4) NOT NULL,
  currency        CHAR(3)       NOT NULL DEFAULT 'INR',
  fx_rate         DECIMAL(18,8) NOT NULL DEFAULT 1,
  fx_rate_type    ENUM('ACCOUNTING','CUSTOMS','CLOSING','SETTLEMENT','FORWARD') NOT NULL DEFAULT 'ACCOUNTING',
  voucher_date    DATE          NOT NULL,
  -- dimensions ------------------------------------------------------------
  site_id         BIGINT UNSIGNED NULL,
  cost_centre     VARCHAR(20)  NULL,
  profit_centre   VARCHAR(20)  NULL,
  project_code    VARCHAR(30)  NULL,
  party_id        BIGINT UNSIGNED NULL,
  item_id         BIGINT UNSIGNED NULL,
  lot_no          VARCHAR(40)  NULL,
  shipment_id     BIGINT UNSIGNED NULL,
  declaration_id  BIGINT UNSIGNED NULL,
  declaration_line_id BIGINT UNSIGNED NULL,
  instrument_id   BIGINT UNSIGNED NULL,
  licence_id      BIGINT UNSIGNED NULL,
  scheme_id       BIGINT UNSIGNED NULL,
  charge_type_id  BIGINT UNSIGNED NULL,
  tax_code        VARCHAR(30)  NULL,
  subledger_key   VARCHAR(60)  NULL,
  rule_branch     VARCHAR(200) NULL,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (period_key, id),
  KEY ix_pl_id (id),
  -- ledger enquiry: one account, one period, in voucher order
  KEY ix_pl_ledger (entity_id, book_id, account_id, period_key, voucher_date, id),
  -- drill from a voucher
  KEY ix_pl_voucher (voucher_id),
  -- trade analytics
  KEY ix_pl_shipment (entity_id, shipment_id),
  KEY ix_pl_declaration (entity_id, declaration_id),
  KEY ix_pl_party (entity_id, party_id, period_key),
  KEY ix_pl_item (entity_id, item_id, period_key),
  KEY ix_pl_scheme (entity_id, scheme_id, period_key),
  KEY ix_pl_charge (entity_id, charge_type_id, period_key),
  -- clearing-account ageing: account + shipment + date
  KEY ix_pl_clearing (entity_id, account_id, shipment_id, voucher_date)
) ENGINE=InnoDB
PARTITION BY RANGE (period_key) (
  PARTITION p2025 VALUES LESS THAN (202601),
  PARTITION p202601 VALUES LESS THAN (202602),
  PARTITION p202602 VALUES LESS THAN (202603),
  PARTITION p202603 VALUES LESS THAN (202604),
  PARTITION p202604 VALUES LESS THAN (202605),
  PARTITION p202605 VALUES LESS THAN (202606),
  PARTITION p202606 VALUES LESS THAN (202607),
  PARTITION p202607 VALUES LESS THAN (202608),
  PARTITION p202608 VALUES LESS THAN (202609),
  PARTITION p202609 VALUES LESS THAN (202610),
  PARTITION p202610 VALUES LESS THAN (202611),
  PARTITION p202611 VALUES LESS THAN (202612),
  PARTITION p202612 VALUES LESS THAN (202701),
  PARTITION p2027 VALUES LESS THAN (202801),
  PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- =========================================================================
--  ROLLUP: one row per account per period per book.
--  Maintained inside the posting transaction. The trial balance reads THIS,
--  never posting_line. Opening balance is carried, so a trial balance for any
--  period is a single-partition, index-only scan of a few thousand rows.
-- =========================================================================
CREATE TABLE account_period_balance (
  entity_id     BIGINT UNSIGNED NOT NULL,
  book_id       BIGINT UNSIGNED NOT NULL,
  account_id    BIGINT UNSIGNED NOT NULL,
  period_key    INT UNSIGNED NOT NULL,
  opening_dr    DECIMAL(24,4) NOT NULL DEFAULT 0,
  opening_cr    DECIMAL(24,4) NOT NULL DEFAULT 0,
  period_dr     DECIMAL(24,4) NOT NULL DEFAULT 0,
  period_cr     DECIMAL(24,4) NOT NULL DEFAULT 0,
  line_count    BIGINT UNSIGNED NOT NULL DEFAULT 0,
  updated_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (entity_id, book_id, period_key, account_id),
  KEY ix_apb_account (entity_id, account_id, period_key)
) ENGINE=InnoDB;

-- Evidence attached to a voucher; immutable once posted (HBIE-DOC-032).
CREATE TABLE voucher_evidence (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  voucher_id   BIGINT UNSIGNED NOT NULL,
  period_key   INT UNSIGNED NOT NULL,
  doc_type     VARCHAR(80)  NOT NULL,
  file_name    VARCHAR(300) NULL,
  storage_key  VARCHAR(400) NULL,
  checksum     CHAR(64)     NULL,
  issuer       VARCHAR(160) NULL,
  doc_ref      VARCHAR(80)  NULL,
  doc_date     DATE         NULL,
  is_mandatory TINYINT(1)   NOT NULL DEFAULT 1,
  is_attached  TINYINT(1)   NOT NULL DEFAULT 0,
  version_no   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  superseded_by BIGINT UNSIGNED NULL,
  size_kb      INT UNSIGNED NULL,
  uploaded_by  BIGINT UNSIGNED NULL,
  uploaded_at  DATETIME(3)  NULL,
  PRIMARY KEY (id),
  KEY ix_ve_voucher (voucher_id),
  KEY ix_ve_missing (voucher_id, is_mandatory, is_attached)
) ENGINE=InnoDB;

-- ------------------------------------------------------------ close & recon ---
CREATE TABLE close_task (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  period_key    INT UNSIGNED NOT NULL,
  day_offset    VARCHAR(6)   NOT NULL,   -- D-3, D+1 …
  area          VARCHAR(60)  NOT NULL,
  step          VARCHAR(300) NOT NULL,
  owner_role    VARCHAR(60)  NOT NULL,
  is_mandatory  TINYINT(1)   NOT NULL DEFAULT 1,
  status        ENUM('NOT_STARTED','IN_PROGRESS','BLOCKED','COMPLETE') NOT NULL DEFAULT 'NOT_STARTED',
  derived_check VARCHAR(60)  NULL,       -- name of the query that derives status
  blocking_count INT UNSIGNED NOT NULL DEFAULT 0,
  blocking_detail VARCHAR(600) NULL,
  evidence_ref  VARCHAR(200) NULL,
  signed_off_by BIGINT UNSIGNED NULL,
  signed_off_at DATETIME(3)  NULL,
  seq_no        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_close_task (entity_id, period_key, seq_no),
  KEY ix_close_status (entity_id, period_key, status)
) ENGINE=InnoDB;

CREATE TABLE reconciliation (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  code          VARCHAR(20)  NOT NULL,
  name          VARCHAR(200) NOT NULL,
  source_a      VARCHAR(120) NOT NULL,
  source_b      VARCHAR(120) NOT NULL,
  frequency     ENUM('DAILY','WEEKLY','MONTHLY','QUARTERLY') NOT NULL,
  owner_role    VARCHAR(60)  NOT NULL,
  control_account_id BIGINT UNSIGNED NULL,
  as_of         DATE         NULL,
  matched_count INT UNSIGNED NOT NULL DEFAULT 0,
  unmatched_a   INT UNSIGNED NOT NULL DEFAULT 0,
  unmatched_b   INT UNSIGNED NOT NULL DEFAULT 0,
  value_at_risk DECIMAL(20,4) NOT NULL DEFAULT 0,
  oldest_days   INT UNSIGNED NOT NULL DEFAULT 0,
  status        ENUM('CLEAN','EXCEPTIONS','CRITICAL') NOT NULL DEFAULT 'CLEAN',
  signed_off_by BIGINT UNSIGNED NULL,
  signed_off_at DATETIME(3)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_recon (entity_id, code),
  KEY ix_recon_status (entity_id, status)
) ENGINE=InnoDB;

CREATE TABLE reconciliation_item (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reconciliation_id BIGINT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  item_ref       VARCHAR(120) NOT NULL,
  item_date      DATE         NOT NULL,
  description    VARCHAR(400) NOT NULL,
  amount_a       DECIMAL(20,4) NULL,
  amount_b       DECIMAL(20,4) NULL,
  difference     DECIMAL(20,4) NOT NULL DEFAULT 0,
  cause          VARCHAR(200) NULL,
  age_days       INT UNSIGNED NOT NULL DEFAULT 0,
  limitation_date DATE        NULL,
  status         ENUM('UNMATCHED','MATCHED_AUTO','MATCHED_MANUAL','DISPUTED','WRITTEN_OFF') NOT NULL DEFAULT 'UNMATCHED',
  matched_by     BIGINT UNSIGNED NULL,
  match_basis    VARCHAR(400) NULL,
  matched_at     DATETIME(3)  NULL,
  PRIMARY KEY (id),
  KEY ix_ri_recon (reconciliation_id, status, age_days DESC),
  KEY ix_ri_limitation (entity_id, limitation_date),
  CONSTRAINT fk_ri_recon FOREIGN KEY (reconciliation_id) REFERENCES reconciliation (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Statement presentation mapping — statements are produced by mapping, not by
-- regrouping a trial balance (HBIE-CLS-020).
CREATE TABLE statement_mapping (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id    BIGINT UNSIGNED NOT NULL,
  statement    ENUM('BALANCE_SHEET','PROFIT_AND_LOSS','CASH_FLOW','EQUITY','NOTE') NOT NULL,
  caption      VARCHAR(200) NOT NULL,
  note_ref     VARCHAR(10)  NULL,
  seq_no       SMALLINT UNSIGNED NOT NULL,
  sign         TINYINT      NOT NULL DEFAULT 1,
  version      VARCHAR(20)  NOT NULL DEFAULT 'v1',
  PRIMARY KEY (id),
  UNIQUE KEY uq_sm (entity_id, statement, caption, version),
  KEY ix_sm_seq (entity_id, statement, seq_no)
) ENGINE=InnoDB;

CREATE TABLE statement_mapping_account (
  mapping_id BIGINT UNSIGNED NOT NULL,
  account_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (mapping_id, account_id),
  CONSTRAINT fk_sma_mapping FOREIGN KEY (mapping_id) REFERENCES statement_mapping (id) ON DELETE CASCADE,
  CONSTRAINT fk_sma_account FOREIGN KEY (account_id) REFERENCES gl_account (id)
) ENGINE=InnoDB;
