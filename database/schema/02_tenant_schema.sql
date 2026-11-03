-- ================================================================
-- HB Import & Export — TENANT (per-business) database schema
-- Apply once per business database (e.g. hb_tenant_hbml).
-- Concatenation of tenant migrations 001..010 in apply order.
-- ================================================================

-- >>> 001_core.sql ------------------------------------------------

-- ============================================================================
--  HB TRADE — 001 CORE: tenancy, security, reference and master data
--  MySQL 8.0. InnoDB throughout. utf8mb4.
--
--  Conventions
--    * Surrogate BIGINT UNSIGNED AUTO_INCREMENT PK named `id`.
--    * Natural/business keys carry a UNIQUE index (usually scoped by entity).
--    * Money: DECIMAL(20,4) — never FLOAT. Rates: DECIMAL(18,8).
--    * Quantities: DECIMAL(20,6).
--    * Every business table carries entity_id for row-level scoping.
--    * created_at / updated_at on every table; row_version for optimistic locking.
--    * Statutory content is effective-dated (valid_from / valid_to), never edited
--      in place — RD HBIE-ARC-011.
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------- tenancy ---
CREATE TABLE legal_entity (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code            VARCHAR(20)  NOT NULL,
  name            VARCHAR(200) NOT NULL,
  country_code    CHAR(2)      NOT NULL,
  functional_ccy  CHAR(3)      NOT NULL,
  group_ccy       CHAR(3)      NOT NULL DEFAULT 'INR',
  gaap_framework  ENUM('IND_AS','AS','IFRS') NOT NULL DEFAULT 'IND_AS',
  iec             VARCHAR(20)  NULL,
  pan             VARCHAR(10)  NULL,
  is_active       TINYINT(1)   NOT NULL DEFAULT 1,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_legal_entity_code (code)
) ENGINE=InnoDB;

CREATE TABLE site (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  code          VARCHAR(20)  NOT NULL,
  name          VARCHAR(200) NOT NULL,
  gstin         VARCHAR(15)  NULL,
  state_code    VARCHAR(10)  NULL,
  is_bonded     TINYINT(1)   NOT NULL DEFAULT 0,
  bond_licence  VARCHAR(50)  NULL,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_site (entity_id, code),
  CONSTRAINT fk_site_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- ------------------------------------------------------- reference / geo ---
CREATE TABLE country (
  code         CHAR(2)     NOT NULL,
  name         VARCHAR(100) NOT NULL,
  default_ccy  CHAR(3)     NULL,
  is_embargoed TINYINT(1)  NOT NULL DEFAULT 0,
  PRIMARY KEY (code)
) ENGINE=InnoDB;

CREATE TABLE currency (
  code      CHAR(3)     NOT NULL,
  name      VARCHAR(60) NOT NULL,
  precision_dp TINYINT UNSIGNED NOT NULL DEFAULT 2,
  PRIMARY KEY (code)
) ENGINE=InnoDB;

CREATE TABLE port (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code         VARCHAR(10)  NOT NULL,      -- authority-issued location code
  name         VARCHAR(120) NOT NULL,
  country_code CHAR(2)      NOT NULL,
  mode         ENUM('SEA','AIR','ROAD','RAIL','ICD','CFS','LCS') NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_port_code (code),
  KEY ix_port_country (country_code),
  CONSTRAINT fk_port_country FOREIGN KEY (country_code) REFERENCES country (code)
) ENGINE=InnoDB;

CREATE TABLE incoterm (
  code                CHAR(3)     NOT NULL,
  name                VARCHAR(80) NOT NULL,
  modes               VARCHAR(30) NOT NULL,
  risk_transfer       VARCHAR(120) NOT NULL,
  freight_in_value    TINYINT(1)  NOT NULL,
  insurance_by_seller TINYINT(1)  NOT NULL,
  import_cleared_by   ENUM('BUYER','SELLER') NOT NULL,
  ownership_event     VARCHAR(40) NOT NULL,   -- drives goods-in-transit recognition
  PRIMARY KEY (code)
) ENGINE=InnoDB;

-- Exchange rates dimensioned by TYPE — the accounting rate, the statutory customs
-- rate (fixed for a period), the closing rate and the settlement rate are never
-- interchangeable (RD HBIE-MDM-030).
CREATE TABLE fx_rate (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rate_type  ENUM('ACCOUNTING','CUSTOMS','CLOSING','SETTLEMENT','FORWARD') NOT NULL,
  from_ccy   CHAR(3) NOT NULL,
  to_ccy     CHAR(3) NOT NULL,
  valid_from DATE    NOT NULL,
  valid_to   DATE    NULL,
  rate       DECIMAL(18,8) NOT NULL,
  source     VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_fx (rate_type, from_ccy, to_ccy, valid_from),
  KEY ix_fx_lookup (from_ccy, to_ccy, rate_type, valid_from DESC)
) ENGINE=InnoDB;

CREATE TABLE uom (
  code       VARCHAR(10) NOT NULL,
  name       VARCHAR(60) NOT NULL,
  uom_class  VARCHAR(20) NOT NULL,
  PRIMARY KEY (code)
) ENGINE=InnoDB;

-- ------------------------------------------------- statutory content packs ---
CREATE TABLE content_pack (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  component    VARCHAR(60)  NOT NULL,
  jurisdiction CHAR(2)      NOT NULL,
  version      VARCHAR(40)  NOT NULL,
  effective_from DATE       NOT NULL,
  effective_to   DATE       NULL,
  status       ENUM('STAGED','ACTIVE','SUPERSEDED') NOT NULL DEFAULT 'STAGED',
  record_count INT UNSIGNED NOT NULL DEFAULT 0,
  ingested_at  DATETIME(3)  NULL,
  prepared_by  BIGINT UNSIGNED NULL,
  approved_by  BIGINT UNSIGNED NULL,
  approved_at  DATETIME(3)  NULL,
  test_result  ENUM('PASSED','FAILED','NOT_RUN') NOT NULL DEFAULT 'NOT_RUN',
  PRIMARY KEY (id),
  UNIQUE KEY uq_pack (component, jurisdiction, version),
  KEY ix_pack_active (jurisdiction, component, status, effective_from)
) ENGINE=InnoDB;

-- Tariff schedule: effective-dated, superseded versions retained indefinitely.
CREATE TABLE hs_code (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  jurisdiction  CHAR(2)      NOT NULL,
  code          VARCHAR(12)  NOT NULL,
  description   VARCHAR(500) NOT NULL,
  statutory_uom VARCHAR(10)  NOT NULL,
  chapter       CHAR(2)      NOT NULL,
  valid_from    DATE         NOT NULL,
  valid_to      DATE         NULL,
  pack_id       BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_hs (jurisdiction, code, valid_from),
  KEY ix_hs_code (code),
  KEY ix_hs_chapter (jurisdiction, chapter)
) ENGINE=InnoDB;

-- Levy definitions: the declarative cascade. base_expr references AV and prior levies.
CREATE TABLE levy_definition (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  jurisdiction  CHAR(2)      NOT NULL,
  code          VARCHAR(20)  NOT NULL,
  name          VARCHAR(120) NOT NULL,
  calc_type     ENUM('ADVALOREM','SPECIFIC','COMPOUND','HIGHER_OF') NOT NULL,
  base_expr     VARCHAR(200) NOT NULL,
  seq_no        SMALLINT UNSIGNED NOT NULL,
  default_rate  DECIMAL(10,4) NOT NULL DEFAULT 0,
  rate_per_unit DECIMAL(18,6) NULL,
  recoverable   TINYINT(1)   NOT NULL DEFAULT 0,
  round_dp      TINYINT UNSIGNED NOT NULL DEFAULT 2,
  valid_from    DATE         NOT NULL,
  valid_to      DATE         NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_levy (jurisdiction, code, valid_from),
  KEY ix_levy_active (jurisdiction, valid_from, seq_no)
) ENGINE=InnoDB;

-- Rate by HS code — the tariff rate table (millions of rows in production).
CREATE TABLE levy_rate (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  jurisdiction CHAR(2)     NOT NULL,
  levy_code   VARCHAR(20)  NOT NULL,
  hs_code     VARCHAR(12)  NOT NULL,
  origin_code CHAR(2)      NULL,           -- NULL = any origin
  rate_pct    DECIMAL(10,4) NOT NULL,
  rate_per_unit DECIMAL(18,6) NULL,
  notification_ref VARCHAR(60) NULL,
  valid_from  DATE         NOT NULL,
  valid_to    DATE         NULL,
  PRIMARY KEY (id),
  KEY ix_levy_rate_lookup (jurisdiction, hs_code, levy_code, valid_from DESC),
  KEY ix_levy_rate_origin (jurisdiction, hs_code, origin_code, valid_from DESC)
) ENGINE=InnoDB;

-- Trade agreements and preferential rates.
CREATE TABLE trade_agreement (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code        VARCHAR(20)  NOT NULL,
  name        VARCHAR(160) NOT NULL,
  in_force_from DATE       NOT NULL,
  proof_modes VARCHAR(120) NOT NULL,     -- AGENCY_COO,SELF_CERT,IMPORTER_DECL
  PRIMARY KEY (id),
  UNIQUE KEY uq_agreement (code)
) ENGINE=InnoDB;

CREATE TABLE preference_rate (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  agreement_id  BIGINT UNSIGNED NOT NULL,
  hs_code       VARCHAR(12)  NOT NULL,
  partner_code  CHAR(2)      NOT NULL,
  rate_pct      DECIMAL(10,4) NOT NULL,
  origin_rule   VARCHAR(300) NOT NULL,
  rule_type     ENUM('WO','CTC','CTSH','VALUE_CONTENT','PROCESS','COMBINATION') NOT NULL,
  threshold_pct DECIMAL(6,2) NULL,
  valid_from    DATE         NOT NULL,
  valid_to      DATE         NULL,
  PRIMARY KEY (id),
  KEY ix_pref_lookup (agreement_id, hs_code, partner_code, valid_from DESC),
  CONSTRAINT fk_pref_agreement FOREIGN KEY (agreement_id) REFERENCES trade_agreement (id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------- scheme reg ---
CREATE TABLE scheme (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code           VARCHAR(30)  NOT NULL,
  name           VARCHAR(160) NOT NULL,
  scheme_family  ENUM('REMISSION','REBATE','DRAWBACK','INPUT_AUTH','CAPITAL_AUTH','ZONE','BONDED','REFUND','CREDIT_SUPPORT') NOT NULL,
  obligation_type ENUM('NONE','VALUE','QUANTITY','MULTIPLE_OF_DUTY_SAVED') NOT NULL DEFAULT 'NONE',
  obligation_multiple DECIMAL(8,2) NULL,
  obligation_months  SMALLINT UNSIGNED NULL,
  min_value_addition_pct DECIMAL(6,2) NULL,
  recognition_point ENUM('ON_EXPORT','ON_FILING','ON_SANCTION','ON_RECEIPT') NOT NULL DEFAULT 'ON_SANCTION',
  valid_from     DATE NOT NULL,
  valid_to       DATE NULL,       -- schemes lapse; this is why it is dated
  PRIMARY KEY (id),
  UNIQUE KEY uq_scheme (code, valid_from)
) ENGINE=InnoDB;

CREATE TABLE scheme_rate (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  scheme_id   BIGINT UNSIGNED NOT NULL,
  hs_code     VARCHAR(12)   NOT NULL,
  rate_pct    DECIMAL(10,4) NOT NULL,
  cap_amount  DECIMAL(20,4) NULL,
  cap_uom     VARCHAR(10)   NULL,
  valid_from  DATE          NOT NULL,
  valid_to    DATE          NULL,
  PRIMARY KEY (id),
  KEY ix_scheme_rate (scheme_id, hs_code, valid_from DESC),
  CONSTRAINT fk_sr_scheme FOREIGN KEY (scheme_id) REFERENCES scheme (id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------ trade party ---
CREATE TABLE trade_party (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  contact_code   VARCHAR(30)  NOT NULL,
  name           VARCHAR(200) NOT NULL,
  legal_name     VARCHAR(200) NOT NULL,
  country_code   CHAR(2)      NOT NULL,
  currency       CHAR(3)      NOT NULL DEFAULT 'INR',
  gstin          VARCHAR(15)  NULL,
  pan            VARCHAR(10)  NULL,
  iec            VARCHAR(20)  NULL,
  ledger_group   VARCHAR(60)  NULL,
  ledger_account_id BIGINT UNSIGNED NULL,
  default_incoterm CHAR(3)    NULL,
  default_payment_term VARCHAR(60) NULL,
  is_related_party TINYINT(1) NOT NULL DEFAULT 0,
  bank_verified  TINYINT(1)   NOT NULL DEFAULT 0,
  bank_verified_by BIGINT UNSIGNED NULL,
  bank_changed_at DATETIME(3) NULL,
  screening_status ENUM('CLEAR','REVIEW','MATCH','NOT_SCREENED') NOT NULL DEFAULT 'NOT_SCREENED',
  screened_at    DATETIME(3)  NULL,
  is_active      TINYINT(1)   NOT NULL DEFAULT 1,
  row_version    INT UNSIGNED NOT NULL DEFAULT 1,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_party (entity_id, contact_code),
  KEY ix_party_name (entity_id, name),
  KEY ix_party_screening (entity_id, screening_status),
  KEY ix_party_country (entity_id, country_code),
  CONSTRAINT fk_party_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_party_country FOREIGN KEY (country_code) REFERENCES country (code)
) ENGINE=InnoDB;

CREATE TABLE trade_party_role (
  party_id BIGINT UNSIGNED NOT NULL,
  role     ENUM('CUSTOMER','SUPPLIER','MANUFACTURER','CONSIGNEE','NOTIFY','FORWARDER','BROKER','TRANSPORTER','INSPECTION','INSURER','BANK') NOT NULL,
  PRIMARY KEY (party_id, role),
  CONSTRAINT fk_tpr_party FOREIGN KEY (party_id) REFERENCES trade_party (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE screening_event (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id   BIGINT UNSIGNED NOT NULL,
  party_id    BIGINT UNSIGNED NOT NULL,
  list_ref    VARCHAR(80)  NOT NULL,
  list_entry  VARCHAR(300) NULL,
  score       SMALLINT UNSIGNED NULL,
  matched_tokens VARCHAR(300) NULL,
  verdict     ENUM('CLEAR','POTENTIAL','CONFIRMED','FALSE_POSITIVE') NOT NULL,
  disposition VARCHAR(500) NULL,
  reviewed_by BIGINT UNSIGNED NULL,
  screened_at DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY ix_screen_party (party_id, screened_at DESC),
  KEY ix_screen_open (entity_id, verdict, screened_at DESC),
  CONSTRAINT fk_se_party FOREIGN KEY (party_id) REFERENCES trade_party (id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------ items ---
CREATE TABLE item (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id       BIGINT UNSIGNED NOT NULL,
  item_code       VARCHAR(40)  NOT NULL,
  description     VARCHAR(300) NOT NULL,
  statutory_description VARCHAR(500) NULL,
  stock_uom       VARCHAR(10)  NOT NULL,
  valuation_method ENUM('WAVG','FIFO','STANDARD') NOT NULL DEFAULT 'WAVG',
  item_group      VARCHAR(60)  NULL,
  net_weight_kg   DECIMAL(20,6) NULL,
  gross_weight_kg DECIMAL(20,6) NULL,
  volume_cbm      DECIMAL(20,6) NULL,
  is_capital_good TINYINT(1)   NOT NULL DEFAULT 0,
  is_active       TINYINT(1)   NOT NULL DEFAULT 1,
  row_version     INT UNSIGNED NOT NULL DEFAULT 1,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_item (entity_id, item_code),
  KEY ix_item_desc (entity_id, description(80)),
  KEY ix_item_group (entity_id, item_group),
  CONSTRAINT fk_item_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- Trade attributes are per item PER COUNTRY PER DIRECTION and effective dated:
-- the same item can legitimately classify differently in two jurisdictions.
CREATE TABLE item_trade_attr (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  item_id       BIGINT UNSIGNED NOT NULL,
  jurisdiction  CHAR(2)      NOT NULL,
  direction     ENUM('IMPORT','EXPORT') NOT NULL,
  hs_code       VARCHAR(12)  NOT NULL,
  statutory_uom VARCHAR(10)  NOT NULL,
  uom_conversion DECIMAL(20,8) NOT NULL DEFAULT 1,
  default_origin CHAR(2)     NULL,
  restriction   ENUM('FREE','RESTRICTED','PROHIBITED','STATE_TRADING','CONDITIONAL') NOT NULL DEFAULT 'FREE',
  classification_basis VARCHAR(600) NULL,
  approved_by   BIGINT UNSIGNED NULL,
  approved_at   DATETIME(3)  NULL,
  status        ENUM('DRAFT','APPROVED','RECLASSIFY') NOT NULL DEFAULT 'DRAFT',
  valid_from    DATE         NOT NULL,
  valid_to      DATE         NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ita (item_id, jurisdiction, direction, valid_from),
  KEY ix_ita_hs (jurisdiction, hs_code),
  KEY ix_ita_status (status),
  CONSTRAINT fk_ita_item FOREIGN KEY (item_id) REFERENCES item (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE item_permit_requirement (
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  item_id  BIGINT UNSIGNED NOT NULL,
  agency   VARCHAR(60) NOT NULL,
  permit_type VARCHAR(80) NOT NULL,
  lead_time_days SMALLINT UNSIGNED NOT NULL DEFAULT 7,
  PRIMARY KEY (id),
  KEY ix_ipr_item (item_id),
  CONSTRAINT fk_ipr_item FOREIGN KEY (item_id) REFERENCES item (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------- charge master ---
CREATE TABLE charge_type (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id       BIGINT UNSIGNED NOT NULL,
  code            VARCHAR(20)  NOT NULL,
  name            VARCHAR(160) NOT NULL,
  category        ENUM('GOODS','FREIGHT','INSURANCE','DUTY','PORT','BROKERAGE','INLAND','BANK','AGENCY','INSPECTION','PENALTY','OTHER') NOT NULL,
  treatment       ENUM('CAPITALISE','EXPENSE','RECOVERABLE','CONDITIONAL') NOT NULL,
  treatment_rule  VARCHAR(400) NULL,
  allocation_basis ENUM('VALUE','GROSS_WEIGHT','VOLUME','QUANTITY','CHARGEABLE_WEIGHT','CONTAINER','DIRECT','EQUAL') NOT NULL DEFAULT 'VALUE',
  default_bearer  ENUM('ENTITY','COUNTERPARTY','PER_TERMS') NOT NULL DEFAULT 'ENTITY',
  tax_rate_pct    DECIMAL(6,2) NULL,
  credit_eligible TINYINT(1)   NOT NULL DEFAULT 1,
  tolerance_pct   DECIMAL(6,2) NOT NULL DEFAULT 5,
  accrual_account_id BIGINT UNSIGNED NULL,
  expense_account_id BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_charge (entity_id, code),
  CONSTRAINT fk_charge_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------- audit trail ---
-- Append-only. No UPDATE or DELETE grant is given to the application user in
-- production; retention is enforced by policy, never by convenience (HBIE-SEC-030).
CREATE TABLE audit_log (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id   BIGINT UNSIGNED NULL,
  occurred_at DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  user_id     BIGINT UNSIGNED NULL,
  username    VARCHAR(100) NULL,
  source_ip   VARCHAR(45)  NULL,
  action      VARCHAR(40)  NOT NULL,
  object_type VARCHAR(40)  NOT NULL,
  object_id   BIGINT UNSIGNED NULL,
  object_ref  VARCHAR(60)  NULL,
  field_name  VARCHAR(60)  NULL,
  old_value   TEXT         NULL,
  new_value   TEXT         NULL,
  reason      VARCHAR(500) NULL,
  correlation_id CHAR(36)  NULL,
  PRIMARY KEY (id),
  KEY ix_audit_object (object_type, object_id, occurred_at),
  KEY ix_audit_user (user_id, occurred_at),
  KEY ix_audit_time (occurred_at)
) ENGINE=InnoDB;

-- Override register: every override of a blocking control (HBIE-CMP-032).
CREATE TABLE override_register (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  control_code  VARCHAR(20)  NOT NULL,
  rule_code     VARCHAR(20)  NULL,
  object_type   VARCHAR(40)  NOT NULL,
  object_id     BIGINT UNSIGNED NOT NULL,
  object_ref    VARCHAR(60)  NULL,
  reason        VARCHAR(1000) NOT NULL,
  requested_by  BIGINT UNSIGNED NOT NULL,
  approved_by   BIGINT UNSIGNED NOT NULL,
  exposure_amount DECIMAL(20,4) NULL,
  created_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  reviewed_at   DATETIME(3)  NULL,
  reviewed_by   BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY ix_override_entity (entity_id, created_at DESC),
  KEY ix_override_review (entity_id, reviewed_at)
) ENGINE=InnoDB;

-- >>> 002_accounting.sql ------------------------------------------------

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

-- >>> 003_trade.sql ------------------------------------------------

-- ============================================================================
--  HB TRADE — 003 TRADE CYCLE
--  Orders → shipments → declarations → duty → landed cost → licences →
--  instruments → entitlements → documents → exceptions.
--
--  Volume notes
--    * declaration / declaration_line / declaration_levy are the high-volume
--      trade tables (1,000,000 declarations a year at the 10x target; ~5 lines
--      each; ~7 levies a line ⇒ ~35,000,000 levy rows a year). All three are
--      RANGE partitioned on period_key exactly like voucher / posting_line.
--    * MySQL 8 InnoDB does NOT support foreign keys on partitioned tables, so
--      the parent/child links between the partitioned trade tables are enforced
--      in the repository layer inside the same transaction, not by the engine.
--      Every such omission is marked  -- NO FK: partitioned
--    * Aggregates that a screen needs on every open (duty totals, cost sheet
--      totals, licence utilisation balance) are stored on the header and
--      maintained in the writing transaction. Screens never SUM a big table.
-- ============================================================================

SET NAMES utf8mb4;

-- =========================================================================
--  ORDERS
-- =========================================================================
CREATE TABLE trade_order (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id        BIGINT UNSIGNED NOT NULL,
  site_id          BIGINT UNSIGNED NULL,
  order_no         VARCHAR(40)  NOT NULL,
  direction        ENUM('IMPORT','EXPORT') NOT NULL,
  order_date       DATE         NOT NULL,
  party_id         BIGINT UNSIGNED NOT NULL,
  currency         CHAR(3)      NOT NULL,
  fx_rate_indicative DECIMAL(18,8) NOT NULL DEFAULT 1,
  incoterm         CHAR(3)      NOT NULL,
  named_place      VARCHAR(120) NOT NULL,
  transport_mode   ENUM('SEA','AIR','ROAD','RAIL','COURIER','PIPELINE') NOT NULL,
  port_of_loading  VARCHAR(10)  NOT NULL,
  port_of_discharge VARCHAR(10) NOT NULL,
  payment_term     VARCHAR(60)  NOT NULL,
  instrument_id    BIGINT UNSIGNED NULL,
  shipment_window_from DATE     NULL,
  shipment_window_to   DATE     NULL,
  -- export zero-rating route: LUT (no IGST) or IGST paid then refunded
  zero_rating_route ENUM('LUT','IGST','NA') NOT NULL DEFAULT 'NA',
  order_value      DECIMAL(20,4) NOT NULL DEFAULT 0,
  order_value_func DECIMAL(20,4) NOT NULL DEFAULT 0,
  shipped_value    DECIMAL(20,4) NOT NULL DEFAULT 0,
  status           ENUM('DRAFT','APPROVED','PART_SHIPPED','SHIPPED','CLOSED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  approved_by      BIGINT UNSIGNED NULL,
  approved_at      DATETIME(3)  NULL,
  row_version      INT UNSIGNED NOT NULL DEFAULT 1,
  created_by       BIGINT UNSIGNED NULL,
  created_at       DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at       DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_order (entity_id, order_no),
  KEY ix_order_list (entity_id, direction, order_date, id),
  KEY ix_order_party (entity_id, party_id, order_date),
  KEY ix_order_status (entity_id, status, order_date),
  KEY ix_order_instrument (instrument_id),
  CONSTRAINT fk_ord_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_ord_site   FOREIGN KEY (site_id)   REFERENCES site (id),
  CONSTRAINT fk_ord_party  FOREIGN KEY (party_id)  REFERENCES trade_party (id),
  CONSTRAINT fk_ord_ccy    FOREIGN KEY (currency)  REFERENCES currency (code),
  CONSTRAINT fk_ord_incoterm FOREIGN KEY (incoterm) REFERENCES incoterm (code)
) ENGINE=InnoDB;

CREATE TABLE trade_order_line (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id       BIGINT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  line_no        SMALLINT UNSIGNED NOT NULL,
  item_id        BIGINT UNSIGNED NULL,
  item_code      VARCHAR(40)  NOT NULL,
  description    VARCHAR(300) NOT NULL,
  hs_code        VARCHAR(12)  NULL,
  qty            DECIMAL(20,6) NOT NULL,
  uom            VARCHAR(10)  NOT NULL,
  unit_price     DECIMAL(20,6) NOT NULL,
  line_value     DECIMAL(20,4) NOT NULL,
  currency       CHAR(3)      NOT NULL,
  origin_country CHAR(2)      NULL,
  net_weight_kg  DECIMAL(20,6) NOT NULL DEFAULT 0,
  gross_weight_kg DECIMAL(20,6) NOT NULL DEFAULT 0,
  volume_cbm     DECIMAL(20,6) NOT NULL DEFAULT 0,
  -- intent captured at order time and tested again at declaration time
  preference_agreement VARCHAR(20) NULL,
  scheme_intent  VARCHAR(120) NULL,          -- comma list of scheme codes
  licence_id     BIGINT UNSIGNED NULL,
  est_landed_unit_cost DECIMAL(20,6) NULL,
  qty_shipped    DECIMAL(20,6) NOT NULL DEFAULT 0,
  qty_cleared    DECIMAL(20,6) NOT NULL DEFAULT 0,
  status         ENUM('OPEN','PART_SHIPPED','SHIPPED','CLOSED','CANCELLED') NOT NULL DEFAULT 'OPEN',
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_ol (order_id, line_no),
  KEY ix_ol_entity_item (entity_id, item_id),
  KEY ix_ol_licence (licence_id),
  KEY ix_ol_open (entity_id, status, order_id),
  CONSTRAINT fk_ol_order FOREIGN KEY (order_id) REFERENCES trade_order (id) ON DELETE CASCADE,
  CONSTRAINT fk_ol_item  FOREIGN KEY (item_id)  REFERENCES item (id)
) ENGINE=InnoDB;

-- =========================================================================
--  SHIPMENTS
-- =========================================================================
CREATE TABLE shipment (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id         BIGINT UNSIGNED NOT NULL,
  site_id           BIGINT UNSIGNED NULL,
  shipment_no       VARCHAR(40)  NOT NULL,
  direction         ENUM('IMPORT','EXPORT') NOT NULL,
  transport_mode    ENUM('SEA','AIR','ROAD','RAIL','COURIER','PIPELINE') NOT NULL,
  party_id          BIGINT UNSIGNED NOT NULL,
  forwarder_id      BIGINT UNSIGNED NULL,
  broker_id         BIGINT UNSIGNED NULL,
  carrier           VARCHAR(120) NULL,
  vessel            VARCHAR(120) NULL,
  voyage            VARCHAR(40)  NULL,
  transport_doc_no  VARCHAR(60)  NULL,        -- B/L or AWB
  transport_doc_date DATE        NULL,
  transport_doc_type ENUM('BL','AWB','LR','RR','CN','OTHER') NULL,
  port_of_loading   VARCHAR(10)  NOT NULL,
  port_of_discharge VARCHAR(10)  NOT NULL,
  place_of_delivery VARCHAR(120) NULL,
  incoterm          CHAR(3)      NOT NULL,
  etd DATE NULL, atd DATE NULL, eta DATE NULL, ata DATE NULL,
  free_time_expires_on DATE      NULL,
  stage             ENUM('PLANNED','BOOKED','IN_TRANSIT','ARRIVED','UNDER_CLEARANCE','CLEARED','DELIVERED','CLOSED') NOT NULL DEFAULT 'PLANNED',
  status            VARCHAR(40)  NOT NULL DEFAULT 'OPEN',
  currency          CHAR(3)      NOT NULL,
  goods_value       DECIMAL(20,4) NOT NULL DEFAULT 0,
  gross_weight_kg   DECIMAL(20,6) NOT NULL DEFAULT 0,
  net_weight_kg     DECIMAL(20,6) NOT NULL DEFAULT 0,
  volume_cbm        DECIMAL(20,6) NOT NULL DEFAULT 0,
  chargeable_weight_kg DECIMAL(20,6) NOT NULL DEFAULT 0,
  container_count   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  docs_required     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  docs_received     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  open_exceptions   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  -- accounting linkage
  goods_in_transit_open TINYINT(1) NOT NULL DEFAULT 0,
  cost_accrued      DECIMAL(20,4) NOT NULL DEFAULT 0,
  cost_actual       DECIMAL(20,4) NOT NULL DEFAULT 0,
  risk_transfer_date DATE        NULL,        -- from the Incoterm rule, drives cut-off
  row_version       INT UNSIGNED NOT NULL DEFAULT 1,
  created_by        BIGINT UNSIGNED NULL,
  created_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_shipment (entity_id, shipment_no),
  KEY ix_shp_list (entity_id, direction, stage, eta, id),
  KEY ix_shp_party (entity_id, party_id, eta),
  KEY ix_shp_doc (entity_id, transport_doc_no),
  KEY ix_shp_eta (entity_id, eta, id),
  KEY ix_shp_git (entity_id, goods_in_transit_open, ata),
  KEY ix_shp_freetime (entity_id, free_time_expires_on),
  CONSTRAINT fk_shp_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_shp_site   FOREIGN KEY (site_id)   REFERENCES site (id),
  CONSTRAINT fk_shp_party  FOREIGN KEY (party_id)  REFERENCES trade_party (id),
  CONSTRAINT fk_shp_fwd    FOREIGN KEY (forwarder_id) REFERENCES trade_party (id),
  CONSTRAINT fk_shp_brk    FOREIGN KEY (broker_id) REFERENCES trade_party (id),
  CONSTRAINT fk_shp_incoterm FOREIGN KEY (incoterm) REFERENCES incoterm (code)
) ENGINE=InnoDB;

-- A shipment can consolidate many orders; an order can split across shipments.
CREATE TABLE shipment_order (
  shipment_id BIGINT UNSIGNED NOT NULL,
  order_id    BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (shipment_id, order_id),
  KEY ix_so_order (order_id),
  CONSTRAINT fk_so_shp FOREIGN KEY (shipment_id) REFERENCES shipment (id) ON DELETE CASCADE,
  CONSTRAINT fk_so_ord FOREIGN KEY (order_id)    REFERENCES trade_order (id)
) ENGINE=InnoDB;

CREATE TABLE shipment_line (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  shipment_id    BIGINT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  line_no        SMALLINT UNSIGNED NOT NULL,
  order_line_id  BIGINT UNSIGNED NULL,
  item_id        BIGINT UNSIGNED NULL,
  item_code      VARCHAR(40)  NOT NULL,
  description    VARCHAR(300) NOT NULL,
  qty            DECIMAL(20,6) NOT NULL,
  uom            VARCHAR(10)  NOT NULL,
  unit_price     DECIMAL(20,6) NOT NULL,
  line_value     DECIMAL(20,4) NOT NULL,
  currency       CHAR(3)      NOT NULL,
  net_weight_kg  DECIMAL(20,6) NOT NULL DEFAULT 0,
  gross_weight_kg DECIMAL(20,6) NOT NULL DEFAULT 0,
  volume_cbm     DECIMAL(20,6) NOT NULL DEFAULT 0,
  container_no   VARCHAR(20)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sl (shipment_id, line_no),
  KEY ix_sl_orderline (order_line_id),
  KEY ix_sl_item (entity_id, item_id),
  CONSTRAINT fk_sl_shp FOREIGN KEY (shipment_id) REFERENCES shipment (id) ON DELETE CASCADE,
  CONSTRAINT fk_sl_ol  FOREIGN KEY (order_line_id) REFERENCES trade_order_line (id)
) ENGINE=InnoDB;

CREATE TABLE container (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  shipment_id     BIGINT UNSIGNED NOT NULL,
  entity_id       BIGINT UNSIGNED NOT NULL,
  container_no    VARCHAR(20)  NOT NULL,
  container_type  VARCHAR(20)  NOT NULL,
  seal_no         VARCHAR(30)  NULL,
  tare_kg         DECIMAL(20,6) NOT NULL DEFAULT 0,
  gross_kg        DECIMAL(20,6) NOT NULL DEFAULT 0,
  -- demurrage / detention: free days from this date, then per-day slabs
  free_from       DATE         NULL,
  free_days       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  days_used       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  projected_charge DECIMAL(20,4) NOT NULL DEFAULT 0,
  returned_on     DATE         NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_container (shipment_id, container_no),
  KEY ix_cnt_no (entity_id, container_no),
  KEY ix_cnt_free (entity_id, free_from, free_days),
  CONSTRAINT fk_cnt_shp FOREIGN KEY (shipment_id) REFERENCES shipment (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE shipment_milestone (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  shipment_id  BIGINT UNSIGNED NOT NULL,
  entity_id    BIGINT UNSIGNED NOT NULL,
  seq          SMALLINT UNSIGNED NOT NULL,
  milestone_key VARCHAR(40) NOT NULL,
  label        VARCHAR(120) NOT NULL,
  planned_on   DATE NULL,
  revised_on   DATE NULL,
  actual_on    DATE NULL,
  source       ENUM('MANUAL','CARRIER','BROKER','PORTAL','SYSTEM') NOT NULL DEFAULT 'MANUAL',
  PRIMARY KEY (id),
  UNIQUE KEY uq_sm (shipment_id, milestone_key),
  KEY ix_sm_due (entity_id, actual_on, planned_on),
  CONSTRAINT fk_sm_shp FOREIGN KEY (shipment_id) REFERENCES shipment (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =========================================================================
--  DECLARATION — partitioned. NO FK to or from this table.
-- =========================================================================
CREATE TABLE declaration (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  period_key        INT UNSIGNED NOT NULL,
  entity_id         BIGINT UNSIGNED NOT NULL,
  site_id           BIGINT UNSIGNED NULL,
  declaration_no    VARCHAR(40)  NOT NULL,
  declaration_type  VARCHAR(40)  NOT NULL,   -- BOE_HOME, BOE_WAREHOUSE, BOE_EX_BOND, SB, BOE_IMPORT_GENERAL…
  direction         ENUM('IMPORT','EXPORT') NOT NULL,
  jurisdiction      CHAR(2)      NOT NULL DEFAULT 'IN',
  shipment_id       BIGINT UNSIGNED NULL,      -- NO FK: partitioned
  party_id          BIGINT UNSIGNED NOT NULL,  -- NO FK: partitioned
  broker_id         BIGINT UNSIGNED NULL,
  port_code         VARCHAR(10)  NOT NULL,
  filing_channel    ENUM('ICEGATE','PORTAL','MANUAL','EDI','API') NOT NULL DEFAULT 'ICEGATE',
  authority_ref     VARCHAR(60)  NULL,         -- job / message id at the authority
  declaration_date  DATE         NOT NULL,
  filed_on          DATE         NULL,
  assessed_on       DATE         NULL,
  paid_on           DATE         NULL,
  cleared_on        DATE         NULL,
  leo_ref           VARCHAR(60)  NULL,         -- export: let-export order
  egm_matched       TINYINT(1)   NOT NULL DEFAULT 0,
  status            ENUM('DRAFT','VALIDATED','TRANSMITTED','QUERIED','ASSESSED','PAID','CLEARED','CANCELLED','AMENDED') NOT NULL DEFAULT 'DRAFT',
  is_provisional    TINYINT(1)   NOT NULL DEFAULT 0,
  provisional_reason VARCHAR(300) NULL,
  bond_id           BIGINT UNSIGNED NULL,
  amends_id         BIGINT UNSIGNED NULL,      -- NO FK: partitioned
  currency          CHAR(3)      NOT NULL,
  -- the statutory rate is the rate NOTIFIED for the declaration date, and is
  -- deliberately NOT the accounting rate (RD HBIE-FX-020)
  statutory_fx_rate DECIMAL(18,8) NOT NULL DEFAULT 1,
  accounting_fx_rate DECIMAL(18,8) NOT NULL DEFAULT 1,
  invoice_value_fc  DECIMAL(20,4) NOT NULL DEFAULT 0,
  freight_fc        DECIMAL(20,4) NOT NULL DEFAULT 0,
  insurance_fc      DECIMAL(20,4) NOT NULL DEFAULT 0,
  assessable_value  DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_total        DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_recoverable  DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_inventoriable DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_assessed     DECIMAL(20,4) NULL,        -- authority's figure, for the recon
  duty_paid         DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_saved        DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_blocked      DECIMAL(20,4) NOT NULL DEFAULT 0, -- eligible preference, proof absent
  fob_value         DECIMAL(20,4) NOT NULL DEFAULT 0, -- export: entitlement base
  error_count       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  warning_count     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  rule_pack_id      BIGINT UNSIGNED NULL,      -- content pack the duty was computed under
  computed_at       DATETIME(3)  NULL,
  prepared_by       BIGINT UNSIGNED NULL,
  approved_by       BIGINT UNSIGNED NULL,
  row_version       INT UNSIGNED NOT NULL DEFAULT 1,
  created_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (period_key, id),
  KEY ix_dec_id (id),
  UNIQUE KEY uq_dec_no (entity_id, jurisdiction, declaration_no, period_key),
  KEY ix_dec_list (entity_id, direction, status, declaration_date, id),
  KEY ix_dec_shipment (entity_id, shipment_id),
  KEY ix_dec_party (entity_id, party_id, declaration_date),
  KEY ix_dec_port (entity_id, port_code, declaration_date),
  KEY ix_dec_prov (entity_id, is_provisional, status),
  KEY ix_dec_authority (entity_id, authority_ref),
  KEY ix_dec_register (entity_id, period_key, direction, declaration_type),
  KEY ix_dec_bond (entity_id, bond_id)
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

CREATE TABLE declaration_line (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  period_key        INT UNSIGNED NOT NULL,
  declaration_id    BIGINT UNSIGNED NOT NULL,  -- NO FK: partitioned
  entity_id         BIGINT UNSIGNED NOT NULL,
  line_no           SMALLINT UNSIGNED NOT NULL,
  shipment_line_id  BIGINT UNSIGNED NULL,
  order_line_id     BIGINT UNSIGNED NULL,
  item_id           BIGINT UNSIGNED NULL,
  item_code         VARCHAR(40)  NOT NULL,
  description       VARCHAR(300) NOT NULL,
  statutory_description VARCHAR(500) NULL,
  hs_code           VARCHAR(12)  NOT NULL,
  -- statutory quantity and stock quantity are different units by design
  qty_statutory     DECIMAL(20,6) NOT NULL,
  statutory_uom     VARCHAR(10)  NOT NULL,
  qty_stock         DECIMAL(20,6) NOT NULL,
  stock_uom         VARCHAR(10)  NOT NULL,
  uom_conversion    DECIMAL(20,8) NOT NULL DEFAULT 1,
  unit_price_fc     DECIMAL(20,6) NOT NULL DEFAULT 0,
  invoice_value_fc  DECIMAL(20,4) NOT NULL DEFAULT 0,
  freight_fc        DECIMAL(20,4) NOT NULL DEFAULT 0,
  insurance_fc      DECIMAL(20,4) NOT NULL DEFAULT 0,
  other_addition_fc DECIMAL(20,4) NOT NULL DEFAULT 0,
  currency          CHAR(3)      NOT NULL,
  assessable_value  DECIMAL(20,4) NOT NULL DEFAULT 0,
  valuation_method  ENUM('TRANSACTION','IDENTICAL','SIMILAR','DEDUCTIVE','COMPUTED','RESIDUAL') NOT NULL DEFAULT 'TRANSACTION',
  origin_country    CHAR(2)      NULL,
  consignment_country CHAR(2)    NULL,
  preference_agreement VARCHAR(20) NULL,
  preference_claimed TINYINT(1)  NOT NULL DEFAULT 0,
  preference_proof_ref VARCHAR(80) NULL,
  preference_proof_doc_id BIGINT UNSIGNED NULL,
  exemption_ref     VARCHAR(60)  NULL,
  licence_id        BIGINT UNSIGNED NULL,
  scheme_id         BIGINT UNSIGNED NULL,
  duty_total        DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_recoverable  DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_inventoriable DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_saved        DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_blocked      DECIMAL(20,4) NOT NULL DEFAULT 0,
  net_weight_kg     DECIMAL(20,6) NOT NULL DEFAULT 0,
  gross_weight_kg   DECIMAL(20,6) NOT NULL DEFAULT 0,
  landed_unit_cost  DECIMAL(20,6) NULL,        -- filled at cost-sheet closure
  created_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (period_key, id),
  KEY ix_dl_id (id),
  UNIQUE KEY uq_dl (declaration_id, line_no, period_key),
  KEY ix_dl_declaration (declaration_id, line_no),
  KEY ix_dl_item (entity_id, item_id, period_key),
  KEY ix_dl_hs (entity_id, hs_code, period_key),
  KEY ix_dl_licence (entity_id, licence_id),
  KEY ix_dl_scheme (entity_id, scheme_id, period_key),
  KEY ix_dl_blocked (entity_id, period_key, duty_blocked)
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

-- One row per levy per line: the duty cascade, stored with its working so an
-- assessment can be reproduced years later without re-running the engine.
CREATE TABLE declaration_levy (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  period_key        INT UNSIGNED NOT NULL,
  declaration_line_id BIGINT UNSIGNED NOT NULL, -- NO FK: partitioned
  declaration_id    BIGINT UNSIGNED NOT NULL,   -- NO FK: partitioned
  entity_id         BIGINT UNSIGNED NOT NULL,
  seq               SMALLINT UNSIGNED NOT NULL,
  levy_code         VARCHAR(20)  NOT NULL,
  levy_name         VARCHAR(120) NOT NULL,
  base_expression   VARCHAR(300) NOT NULL,     -- e.g. AV + BCD + SWS
  base_amount       DECIMAL(20,4) NOT NULL,
  rate_type         ENUM('AD_VALOREM','SPECIFIC','COMPOUND','NIL') NOT NULL DEFAULT 'AD_VALOREM',
  rate_pct          DECIMAL(18,8) NOT NULL DEFAULT 0,
  rate_per_unit     DECIMAL(20,6) NULL,
  amount            DECIMAL(20,4) NOT NULL,
  rate_source       ENUM('SCHEDULE','PREFERENCE','EXEMPTION','NOTIFICATION','OVERRIDE') NOT NULL DEFAULT 'SCHEDULE',
  rate_source_ref   VARCHAR(80)  NULL,
  levy_rate_id      BIGINT UNSIGNED NULL,
  is_recoverable    TINYINT(1)   NOT NULL DEFAULT 0,
  gl_account_id     BIGINT UNSIGNED NULL,      -- resolved at computation, for posting
  overridden_by     BIGINT UNSIGNED NULL,
  override_reason   VARCHAR(300) NULL,
  PRIMARY KEY (period_key, id),
  KEY ix_dlv_id (id),
  UNIQUE KEY uq_dlv (declaration_line_id, levy_code, period_key),
  KEY ix_dlv_line (declaration_line_id, seq),
  KEY ix_dlv_dec (declaration_id),
  -- duty-by-levy register for a period, index only
  KEY ix_dlv_register (entity_id, period_key, levy_code, amount),
  KEY ix_dlv_source (entity_id, rate_source, period_key)
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

CREATE TABLE declaration_validation (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  declaration_id BIGINT UNSIGNED NOT NULL,     -- NO FK: partitioned parent
  entity_id      BIGINT UNSIGNED NOT NULL,
  rule_id        VARCHAR(30)  NOT NULL,
  severity       ENUM('ERROR','WARNING','INFO') NOT NULL,
  field_ref      VARCHAR(80)  NULL,
  line_no        SMALLINT UNSIGNED NULL,
  message        VARCHAR(500) NOT NULL,
  remedy         VARCHAR(500) NOT NULL,
  is_open        TINYINT(1)   NOT NULL DEFAULT 1,
  waived_by      BIGINT UNSIGNED NULL,
  waiver_reason  VARCHAR(300) NULL,
  detected_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY ix_dv_dec (declaration_id, is_open),
  KEY ix_dv_rule (entity_id, rule_id, is_open),
  KEY ix_dv_open (entity_id, severity, is_open)
) ENGINE=InnoDB;

-- =========================================================================
--  BOND / BONDED WAREHOUSE  (duty deferred until ex-bond clearance)
-- =========================================================================
CREATE TABLE bond_register (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  site_id        BIGINT UNSIGNED NULL,
  bond_no        VARCHAR(40)  NOT NULL,
  bond_type      ENUM('WAREHOUSE','MOOWR','EOU','SEZ','ADVANCE','EPCG','PROVISIONAL','GENERAL') NOT NULL,
  licence_id     BIGINT UNSIGNED NULL,
  executed_on    DATE         NOT NULL,
  valid_to       DATE         NULL,
  bond_amount    DECIMAL(20,4) NOT NULL,
  bg_amount      DECIMAL(20,4) NOT NULL DEFAULT 0,
  bg_waived      TINYINT(1)   NOT NULL DEFAULT 0,
  bg_expiry      DATE         NULL,
  utilised_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  available_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_deferred  DECIMAL(20,4) NOT NULL DEFAULT 0,
  interest_accrued DECIMAL(20,4) NOT NULL DEFAULT 0,
  status         ENUM('ACTIVE','EXHAUSTED','CANCELLED','CLOSED') NOT NULL DEFAULT 'ACTIVE',
  contingent_liability_disclosed TINYINT(1) NOT NULL DEFAULT 0,
  row_version    INT UNSIGNED NOT NULL DEFAULT 1,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_bond (entity_id, bond_no),
  KEY ix_bond_status (entity_id, status, valid_to),
  KEY ix_bond_bg (entity_id, bg_expiry),
  CONSTRAINT fk_bond_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- Bonded stock is a SEPARATE ledger from own stock: the goods are on the books
-- but the duty is not yet a liability. Ageing here drives the interest accrual.
CREATE TABLE bonded_stock_ledger (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  site_id        BIGINT UNSIGNED NULL,
  bond_id        BIGINT UNSIGNED NOT NULL,
  item_id        BIGINT UNSIGNED NOT NULL,
  lot_no         VARCHAR(40)  NOT NULL,
  in_declaration_id  BIGINT UNSIGNED NOT NULL, -- NO FK: partitioned
  out_declaration_id BIGINT UNSIGNED NULL,     -- NO FK: partitioned
  movement       ENUM('IN','OUT','TRANSFER','SHORTAGE','DESTRUCTION','REEXPORT') NOT NULL,
  movement_date  DATE         NOT NULL,
  qty            DECIMAL(20,6) NOT NULL,
  uom            VARCHAR(10)  NOT NULL,
  value          DECIMAL(20,4) NOT NULL,
  duty_deferred  DECIMAL(20,4) NOT NULL DEFAULT 0,
  warehoused_on  DATE         NULL,
  free_period_to DATE         NULL,
  interest_from  DATE         NULL,
  interest_accrued DECIMAL(20,4) NOT NULL DEFAULT 0,
  balance_qty    DECIMAL(20,6) NOT NULL DEFAULT 0,
  voucher_id     BIGINT UNSIGNED NULL,         -- NO FK: partitioned
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY ix_bsl_bond (entity_id, bond_id, movement_date),
  KEY ix_bsl_lot (entity_id, item_id, lot_no, movement_date),
  KEY ix_bsl_ageing (entity_id, bond_id, free_period_to),
  KEY ix_bsl_in (in_declaration_id),
  CONSTRAINT fk_bsl_bond FOREIGN KEY (bond_id) REFERENCES bond_register (id),
  CONSTRAINT fk_bsl_item FOREIGN KEY (item_id) REFERENCES item (id)
) ENGINE=InnoDB;

-- =========================================================================
--  LANDED COST
-- =========================================================================
CREATE TABLE cost_sheet (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id          BIGINT UNSIGNED NOT NULL,
  cost_sheet_no      VARCHAR(40)  NOT NULL,
  shipment_id        BIGINT UNSIGNED NOT NULL,
  declaration_id     BIGINT UNSIGNED NULL,     -- NO FK: partitioned
  direction          ENUM('IMPORT','EXPORT') NOT NULL,
  currency           CHAR(3)      NOT NULL,
  goods_value        DECIMAL(20,4) NOT NULL DEFAULT 0,
  -- maintained totals: the sheet screen opens without aggregating cost_line
  total_estimate     DECIMAL(20,4) NOT NULL DEFAULT 0,
  total_accrued      DECIMAL(20,4) NOT NULL DEFAULT 0,
  total_actual       DECIMAL(20,4) NOT NULL DEFAULT 0,
  -- variance is computed on INVOICED lines only; the uninvoiced part is
  -- reported separately, never netted (see README, "Variance compares only
  -- invoiced lines")
  variance_invoiced  DECIMAL(20,4) NOT NULL DEFAULT 0,
  uninvoiced_accrual DECIMAL(20,4) NOT NULL DEFAULT 0,
  capitalised_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  expensed_amount    DECIMAL(20,4) NOT NULL DEFAULT 0,
  recoverable_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  allocation_basis   ENUM('VALUE','GROSS_WEIGHT','VOLUME','QUANTITY','CHARGEABLE_WEIGHT','CONTAINER','DIRECT','EQUAL') NOT NULL DEFAULT 'VALUE',
  stock_on_hand_pct  DECIMAL(9,4) NOT NULL DEFAULT 100,
  status             ENUM('OPEN','ACCRUED','PART_ACTUAL','READY_TO_CLOSE','CLOSED','REOPENED') NOT NULL DEFAULT 'OPEN',
  closed_on          DATE         NULL,
  closed_by          BIGINT UNSIGNED NULL,
  closure_voucher_id BIGINT UNSIGNED NULL,     -- NO FK: partitioned
  tolerance_breaches SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  row_version        INT UNSIGNED NOT NULL DEFAULT 1,
  created_at         DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at         DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cs (entity_id, cost_sheet_no),
  UNIQUE KEY uq_cs_shipment (shipment_id),
  KEY ix_cs_status (entity_id, status, created_at),
  KEY ix_cs_breach (entity_id, tolerance_breaches),
  CONSTRAINT fk_cs_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_cs_shp FOREIGN KEY (shipment_id) REFERENCES shipment (id)
) ENGINE=InnoDB;

CREATE TABLE cost_line (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cost_sheet_id   BIGINT UNSIGNED NOT NULL,
  entity_id       BIGINT UNSIGNED NOT NULL,
  line_no         SMALLINT UNSIGNED NOT NULL,
  charge_type_id  BIGINT UNSIGNED NOT NULL,
  provider_id     BIGINT UNSIGNED NULL,
  basis           ENUM('VALUE','GROSS_WEIGHT','VOLUME','QUANTITY','CHARGEABLE_WEIGHT','CONTAINER','DIRECT','EQUAL') NOT NULL DEFAULT 'VALUE',
  treatment       ENUM('CAPITALISE','EXPENSE','RECOVERABLE') NOT NULL,
  treatment_basis VARCHAR(300) NULL,           -- why, for the audit trail
  currency        CHAR(3)      NOT NULL,
  fx_rate         DECIMAL(18,8) NOT NULL DEFAULT 1,
  estimate_fc     DECIMAL(20,4) NOT NULL DEFAULT 0,
  estimate        DECIMAL(20,4) NOT NULL DEFAULT 0,
  accrued         DECIMAL(20,4) NOT NULL DEFAULT 0,
  actual_fc       DECIMAL(20,4) NULL,
  actual          DECIMAL(20,4) NULL,
  invoice_ref     VARCHAR(60)  NULL,
  invoice_date    DATE         NULL,
  invoice_voucher_id BIGINT UNSIGNED NULL,     -- NO FK: partitioned
  accrual_voucher_id BIGINT UNSIGNED NULL,     -- NO FK: partitioned
  tolerance_pct   DECIMAL(9,4) NOT NULL DEFAULT 10,
  tolerance_breached TINYINT(1) NOT NULL DEFAULT 0,
  status          ENUM('ESTIMATED','ACCRUED','INVOICED','MATCHED','DISPUTED','CANCELLED') NOT NULL DEFAULT 'ESTIMATED',
  gl_account_id   BIGINT UNSIGNED NULL,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cl (cost_sheet_id, line_no),
  KEY ix_cl_sheet (cost_sheet_id, status),
  KEY ix_cl_charge (entity_id, charge_type_id),
  KEY ix_cl_provider (entity_id, provider_id, status),
  KEY ix_cl_uninvoiced (entity_id, status, accrued),
  CONSTRAINT fk_cl_sheet FOREIGN KEY (cost_sheet_id) REFERENCES cost_sheet (id) ON DELETE CASCADE,
  CONSTRAINT fk_cl_charge FOREIGN KEY (charge_type_id) REFERENCES charge_type (id),
  CONSTRAINT fk_cl_provider FOREIGN KEY (provider_id) REFERENCES trade_party (id)
) ENGINE=InnoDB;

-- The allocation result, kept so the inventory unit cost can be traced back
-- from a stock valuation to the charge that produced it.
CREATE TABLE cost_allocation (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cost_sheet_id   BIGINT UNSIGNED NOT NULL,
  cost_line_id    BIGINT UNSIGNED NOT NULL,
  entity_id       BIGINT UNSIGNED NOT NULL,
  target_type     ENUM('DECLARATION_LINE','SHIPMENT_LINE','ITEM','CONTAINER') NOT NULL,
  target_id       BIGINT UNSIGNED NOT NULL,
  basis           ENUM('VALUE','GROSS_WEIGHT','VOLUME','QUANTITY','CHARGEABLE_WEIGHT','CONTAINER','DIRECT','EQUAL') NOT NULL,
  basis_value     DECIMAL(20,6) NOT NULL,
  share_pct       DECIMAL(12,8) NOT NULL,
  amount          DECIMAL(20,4) NOT NULL,
  is_residual_adjustment TINYINT(1) NOT NULL DEFAULT 0,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_ca (cost_line_id, target_type, target_id),
  KEY ix_ca_sheet (cost_sheet_id),
  KEY ix_ca_target (entity_id, target_type, target_id),
  CONSTRAINT fk_ca_sheet FOREIGN KEY (cost_sheet_id) REFERENCES cost_sheet (id) ON DELETE CASCADE,
  CONSTRAINT fk_ca_line  FOREIGN KEY (cost_line_id)  REFERENCES cost_line (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =========================================================================
--  LICENCES AND EXPORT OBLIGATION
-- =========================================================================
CREATE TABLE licence (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id         BIGINT UNSIGNED NOT NULL,
  scheme_id         BIGINT UNSIGNED NOT NULL,
  licence_no        VARCHAR(40)  NOT NULL,
  issued_on         DATE         NOT NULL,
  issuing_authority VARCHAR(120) NULL,
  import_valid_to   DATE         NULL,
  export_valid_to   DATE         NULL,
  status            ENUM('APPLIED','ISSUED','ACTIVE','SUSPENDED','OBLIGATION_MET','REDEEMED','DEFAULTED','CANCELLED') NOT NULL DEFAULT 'ISSUED',
  currency          CHAR(3)      NOT NULL DEFAULT 'INR',
  cif_entitlement   DECIMAL(20,4) NOT NULL DEFAULT 0,
  cif_utilised      DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_saved        DECIMAL(20,4) NOT NULL DEFAULT 0,
  obligation_type   ENUM('VALUE','QUANTITY','VALUE_ADDITION','NONE') NOT NULL DEFAULT 'VALUE',
  obligation_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  obligation_fulfilled DECIMAL(20,4) NOT NULL DEFAULT 0,
  average_obligation DECIMAL(20,4) NULL,
  average_maintained TINYINT(1)  NULL,
  min_value_addition_pct DECIMAL(9,4) NULL,
  achieved_value_addition_pct DECIMAL(9,4) NULL,
  bond_id           BIGINT UNSIGNED NULL,
  bg_waived         TINYINT(1)   NOT NULL DEFAULT 0,
  -- exposure if the obligation is not met: duty + interest, disclosed as a
  -- contingent liability until redemption (RD HBIE-LIC-040)
  exposure_duty     DECIMAL(20,4) NOT NULL DEFAULT 0,
  exposure_interest DECIMAL(20,4) NOT NULL DEFAULT 0,
  contingent_disclosed TINYINT(1) NOT NULL DEFAULT 0,
  redeemed_on       DATE         NULL,
  redemption_ref    VARCHAR(60)  NULL,
  row_version       INT UNSIGNED NOT NULL DEFAULT 1,
  created_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_licence (entity_id, licence_no),
  KEY ix_lic_scheme (entity_id, scheme_id, status),
  KEY ix_lic_status (entity_id, status, export_valid_to),
  KEY ix_lic_exposure (entity_id, status, exposure_duty),
  CONSTRAINT fk_lic_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_lic_scheme FOREIGN KEY (scheme_id) REFERENCES scheme (id),
  CONSTRAINT fk_lic_bond   FOREIGN KEY (bond_id)   REFERENCES bond_register (id)
) ENGINE=InnoDB;

CREATE TABLE licence_item (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  licence_id     BIGINT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  side           ENUM('IMPORT','EXPORT') NOT NULL,
  line_no        SMALLINT UNSIGNED NOT NULL,
  item_id        BIGINT UNSIGNED NULL,
  description    VARCHAR(300) NOT NULL,
  hs_code        VARCHAR(12)  NULL,
  qty_allowed    DECIMAL(20,6) NULL,
  qty_used       DECIMAL(20,6) NOT NULL DEFAULT 0,
  uom            VARCHAR(10)  NULL,
  value_allowed  DECIMAL(20,4) NULL,
  value_used     DECIMAL(20,4) NOT NULL DEFAULT 0,
  norm_ref       VARCHAR(60)  NULL,            -- SION / ad-hoc norm
  wastage_pct    DECIMAL(9,4) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_li (licence_id, side, line_no),
  KEY ix_li_item (entity_id, item_id),
  CONSTRAINT fk_li_licence FOREIGN KEY (licence_id) REFERENCES licence (id) ON DELETE CASCADE,
  CONSTRAINT fk_li_item FOREIGN KEY (item_id) REFERENCES item (id)
) ENGINE=InnoDB;

CREATE TABLE licence_block (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  licence_id     BIGINT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  block_no       SMALLINT UNSIGNED NOT NULL,
  label          VARCHAR(60)  NOT NULL,
  share_pct      DECIMAL(9,4) NOT NULL,
  due_on         DATE         NOT NULL,
  obligation_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  fulfilled_amount  DECIMAL(20,4) NOT NULL DEFAULT 0,
  extended_to    DATE         NULL,
  extension_ref  VARCHAR(60)  NULL,
  status         ENUM('OPEN','MET','SHORT','EXTENDED','DEFAULTED') NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (id),
  UNIQUE KEY uq_lb (licence_id, block_no),
  KEY ix_lb_due (entity_id, due_on, status),
  CONSTRAINT fk_lb_licence FOREIGN KEY (licence_id) REFERENCES licence (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE licence_condition (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  licence_id   BIGINT UNSIGNED NOT NULL,
  entity_id    BIGINT UNSIGNED NOT NULL,
  name         VARCHAR(160) NOT NULL,
  detail       VARCHAR(600) NOT NULL,
  is_satisfied TINYINT(1)   NOT NULL DEFAULT 0,
  evidence_doc_id BIGINT UNSIGNED NULL,
  checked_by   BIGINT UNSIGNED NULL,
  checked_at   DATETIME(3)  NULL,
  PRIMARY KEY (id),
  KEY ix_lc_licence (licence_id, is_satisfied),
  CONSTRAINT fk_lc_licence FOREIGN KEY (licence_id) REFERENCES licence (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Utilisation = duty-free imports drawn against the licence.
-- Fulfilment  = exports counted towards the obligation.
-- Two ledgers, never one table with a sign flag: they age differently, they
-- are evidenced differently, and they reconcile to different authorities.
CREATE TABLE licence_utilisation (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  licence_id     BIGINT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  entry_date     DATE         NOT NULL,
  declaration_id BIGINT UNSIGNED NULL,         -- NO FK: partitioned
  declaration_line_id BIGINT UNSIGNED NULL,    -- NO FK: partitioned
  reference      VARCHAR(60)  NOT NULL,
  description    VARCHAR(300) NOT NULL,
  item_id        BIGINT UNSIGNED NULL,
  qty            DECIMAL(20,6) NULL,
  uom            VARCHAR(10)  NULL,
  value          DECIMAL(20,4) NOT NULL,
  duty_saved     DECIMAL(20,4) NOT NULL DEFAULT 0,
  running_value  DECIMAL(20,4) NOT NULL DEFAULT 0,
  is_reversal    TINYINT(1)   NOT NULL DEFAULT 0,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY ix_lu_licence (licence_id, entry_date, id),
  KEY ix_lu_dec (declaration_id),
  KEY ix_lu_entity (entity_id, entry_date),
  CONSTRAINT fk_lu_licence FOREIGN KEY (licence_id) REFERENCES licence (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE licence_fulfilment (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  licence_id     BIGINT UNSIGNED NOT NULL,
  block_id       BIGINT UNSIGNED NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  entry_date     DATE         NOT NULL,
  declaration_id BIGINT UNSIGNED NULL,         -- NO FK: partitioned
  reference      VARCHAR(60)  NOT NULL,
  description    VARCHAR(300) NOT NULL,
  item_id        BIGINT UNSIGNED NULL,
  qty            DECIMAL(20,6) NULL,
  uom            VARCHAR(10)  NULL,
  fob_value      DECIMAL(20,4) NOT NULL,
  counted_value  DECIMAL(20,4) NOT NULL,       -- after eligibility haircuts
  running_value  DECIMAL(20,4) NOT NULL DEFAULT 0,
  -- an export only counts once the realisation evidence is complete
  evidence_complete TINYINT(1) NOT NULL DEFAULT 0,
  brc_ref        VARCHAR(60)  NULL,
  realised_on    DATE         NULL,
  is_reversal    TINYINT(1)   NOT NULL DEFAULT 0,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY ix_lf_licence (licence_id, entry_date, id),
  KEY ix_lf_block (block_id),
  KEY ix_lf_evidence (entity_id, evidence_complete, entry_date),
  KEY ix_lf_dec (declaration_id),
  CONSTRAINT fk_lf_licence FOREIGN KEY (licence_id) REFERENCES licence (id) ON DELETE CASCADE,
  CONSTRAINT fk_lf_block FOREIGN KEY (block_id) REFERENCES licence_block (id)
) ENGINE=InnoDB;

-- =========================================================================
--  EXPORT ENTITLEMENTS  (drawback, RoDTEP and similar)
-- =========================================================================
CREATE TABLE entitlement_claim (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id       BIGINT UNSIGNED NOT NULL,
  scheme_id       BIGINT UNSIGNED NOT NULL,
  claim_no        VARCHAR(40)  NOT NULL,
  declaration_id  BIGINT UNSIGNED NULL,        -- NO FK: partitioned
  declaration_no  VARCHAR(40)  NULL,
  declaration_date DATE        NULL,
  fob_value       DECIMAL(20,4) NOT NULL DEFAULT 0,
  rate_pct        DECIMAL(18,8) NOT NULL DEFAULT 0,
  cap_per_unit    DECIMAL(20,6) NULL,
  cap_amount      DECIMAL(20,4) NULL,
  computed_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  claimed_amount  DECIMAL(20,4) NOT NULL DEFAULT 0,
  sanctioned_amount DECIMAL(20,4) NULL,
  received_amount DECIMAL(20,4) NULL,
  shortfall_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  shortfall_cause VARCHAR(300) NULL,
  scrip_ref       VARCHAR(60)  NULL,
  scrip_value     DECIMAL(20,4) NULL,
  scrip_utilised  DECIMAL(20,4) NOT NULL DEFAULT 0,
  scrip_sold_value DECIMAL(20,4) NULL,
  stage           ENUM('ACCRUED','FILED','SANCTIONED','SCRIP_ISSUED','RECEIVED','UTILISED','REJECTED','WRITTEN_OFF') NOT NULL DEFAULT 'ACCRUED',
  -- recognition is a policy choice per scheme, recorded per claim so the basis
  -- is auditable: reasonable certainty at export, or at sanction
  recognition_point ENUM('AT_EXPORT','AT_SANCTION','AT_RECEIPT') NOT NULL DEFAULT 'AT_EXPORT',
  is_recognised   TINYINT(1)   NOT NULL DEFAULT 0,
  recognition_voucher_id BIGINT UNSIGNED NULL, -- NO FK: partitioned
  filed_on        DATE NULL,
  sanctioned_on   DATE NULL,
  received_on     DATE NULL,
  row_version     INT UNSIGNED NOT NULL DEFAULT 1,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_ec (entity_id, claim_no),
  KEY ix_ec_scheme (entity_id, scheme_id, stage),
  KEY ix_ec_dec (declaration_id),
  KEY ix_ec_stage (entity_id, stage, declaration_date),
  KEY ix_ec_unrecognised (entity_id, is_recognised, computed_amount),
  CONSTRAINT fk_ec_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_ec_scheme FOREIGN KEY (scheme_id) REFERENCES scheme (id)
) ENGINE=InnoDB;

-- =========================================================================
--  TRADE FINANCE INSTRUMENTS
-- =========================================================================
CREATE TABLE instrument (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id         BIGINT UNSIGNED NOT NULL,
  instrument_no     VARCHAR(40)  NOT NULL,
  instrument_type   ENUM('LC_IMPORT','LC_EXPORT','SBLC','BG','DOC_COLLECTION','OPEN_ACCOUNT','ADVANCE','BUYERS_CREDIT','PACKING_CREDIT') NOT NULL,
  governing_rules   VARCHAR(40)  NULL,         -- UCP 600, URC 522, ISP98…
  issuing_bank_id   BIGINT UNSIGNED NULL,
  advising_bank_id  BIGINT UNSIGNED NULL,
  applicant_party_id BIGINT UNSIGNED NULL,
  beneficiary_party_id BIGINT UNSIGNED NULL,
  currency          CHAR(3)      NOT NULL,
  face_value        DECIMAL(20,4) NOT NULL,
  tolerance_pct     DECIMAL(9,4) NOT NULL DEFAULT 0,
  drawn_value       DECIMAL(20,4) NOT NULL DEFAULT 0,
  available_value   DECIMAL(20,4) NOT NULL DEFAULT 0,
  charges_to_date   DECIMAL(20,4) NOT NULL DEFAULT 0,
  issued_on         DATE         NULL,
  latest_shipment_date DATE      NULL,
  expiry_date       DATE         NULL,
  presentation_days SMALLINT UNSIGNED NOT NULL DEFAULT 21,
  payment_terms     VARCHAR(120) NULL,
  usance_days       SMALLINT UNSIGNED NULL,
  status            ENUM('DRAFT','APPLIED','ISSUED','AMENDED','PRESENTED','ACCEPTED','PART_DRAWN','SETTLED','EXPIRED','CANCELLED','DISHONOURED') NOT NULL DEFAULT 'DRAFT',
  margin_amount     DECIMAL(20,4) NOT NULL DEFAULT 0,
  contingent_disclosed TINYINT(1) NOT NULL DEFAULT 0,
  row_version       INT UNSIGNED NOT NULL DEFAULT 1,
  created_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_instr (entity_id, instrument_no),
  KEY ix_instr_type (entity_id, instrument_type, status),
  KEY ix_instr_expiry (entity_id, expiry_date),
  KEY ix_instr_bank (entity_id, issuing_bank_id),
  CONSTRAINT fk_ins_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id),
  CONSTRAINT fk_ins_issuing FOREIGN KEY (issuing_bank_id) REFERENCES trade_party (id),
  CONSTRAINT fk_ins_advising FOREIGN KEY (advising_bank_id) REFERENCES trade_party (id)
) ENGINE=InnoDB;

CREATE TABLE instrument_doc_requirement (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  instrument_id  BIGINT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  seq            SMALLINT UNSIGNED NOT NULL,
  doc_type       VARCHAR(60)  NOT NULL,
  originals      TINYINT UNSIGNED NOT NULL DEFAULT 1,
  copies         TINYINT UNSIGNED NOT NULL DEFAULT 0,
  issuer         VARCHAR(120) NULL,
  required_wording VARCHAR(1000) NULL,         -- exact wording the credit demands
  is_held        TINYINT(1)   NOT NULL DEFAULT 0,
  held_doc_id    BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_idr (instrument_id, seq),
  KEY ix_idr_held (instrument_id, is_held),
  CONSTRAINT fk_idr_instr FOREIGN KEY (instrument_id) REFERENCES instrument (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE instrument_presentation (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  instrument_id  BIGINT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  presentation_no SMALLINT UNSIGNED NOT NULL,
  shipment_id    BIGINT UNSIGNED NULL,
  presented_on   DATE         NULL,
  due_by         DATE         NULL,            -- shipment date + presentation_days
  amount         DECIMAL(20,4) NOT NULL DEFAULT 0,
  status         ENUM('PREPARING','PRESENTED','DISCREPANT','ACCEPTED','PAID','REFUSED') NOT NULL DEFAULT 'PREPARING',
  outcome_note   VARCHAR(500) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ip (instrument_id, presentation_no),
  KEY ix_ip_due (entity_id, due_by, status),
  KEY ix_ip_shipment (shipment_id),
  CONSTRAINT fk_ip_instr FOREIGN KEY (instrument_id) REFERENCES instrument (id) ON DELETE CASCADE,
  CONSTRAINT fk_ip_shp FOREIGN KEY (shipment_id) REFERENCES shipment (id)
) ENGINE=InnoDB;

CREATE TABLE instrument_discrepancy (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  instrument_id  BIGINT UNSIGNED NOT NULL,
  presentation_id BIGINT UNSIGNED NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  code           VARCHAR(30)  NOT NULL,
  description    VARCHAR(500) NOT NULL,
  disposition    ENUM('OPEN','CORRECTED','WAIVER_SOUGHT','WAIVED','ACCEPTED_UNDER_RESERVE','REFUSED') NOT NULL DEFAULT 'OPEN',
  outcome        VARCHAR(300) NULL,
  raised_on      DATE         NULL,
  resolved_on    DATE         NULL,
  PRIMARY KEY (id),
  KEY ix_idsc_instr (instrument_id, disposition),
  KEY ix_idsc_pres (presentation_id),
  CONSTRAINT fk_idsc_instr FOREIGN KEY (instrument_id) REFERENCES instrument (id) ON DELETE CASCADE,
  CONSTRAINT fk_idsc_pres FOREIGN KEY (presentation_id) REFERENCES instrument_presentation (id)
) ENGINE=InnoDB;

-- Realisation against an export: drives the BRC / limitation tracking and the
-- fulfilment ledger's evidence flag.
CREATE TABLE export_realisation (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  declaration_id BIGINT UNSIGNED NULL,         -- NO FK: partitioned
  instrument_id  BIGINT UNSIGNED NULL,
  invoice_ref    VARCHAR(60)  NOT NULL,
  invoice_date   DATE         NOT NULL,
  currency       CHAR(3)      NOT NULL,
  invoice_value  DECIMAL(20,4) NOT NULL,
  realised_value DECIMAL(20,4) NOT NULL DEFAULT 0,
  realised_on    DATE         NULL,
  bank_ref       VARCHAR(60)  NULL,
  brc_ref        VARCHAR(60)  NULL,
  due_by         DATE         NULL,            -- statutory realisation deadline
  write_off_amount DECIMAL(20,4) NOT NULL DEFAULT 0,
  write_off_approved_by BIGINT UNSIGNED NULL,
  status         ENUM('OPEN','PART_REALISED','REALISED','OVERDUE','WRITTEN_OFF') NOT NULL DEFAULT 'OPEN',
  fx_gain_loss   DECIMAL(20,4) NOT NULL DEFAULT 0,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_er (entity_id, invoice_ref),
  KEY ix_er_due (entity_id, status, due_by),
  KEY ix_er_dec (declaration_id),
  KEY ix_er_instr (instrument_id),
  CONSTRAINT fk_er_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- =========================================================================
--  DOCUMENTS / DMS  — the archival spine (RD section 9)
-- =========================================================================
CREATE TABLE document (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  doc_type       VARCHAR(60)  NOT NULL,
  doc_class      ENUM('COMMERCIAL','TRANSPORT','STATUTORY','FINANCIAL','CERTIFICATE','INTERNAL','CORRESPONDENCE') NOT NULL,
  title          VARCHAR(300) NOT NULL,
  doc_ref        VARCHAR(80)  NULL,
  doc_date       DATE         NULL,
  issuer         VARCHAR(200) NULL,
  -- polymorphic owner; the pair is indexed so "all docs for this shipment" is
  -- one index range
  object_type    VARCHAR(40)  NOT NULL,
  object_id      BIGINT UNSIGNED NOT NULL,
  current_version SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  is_original_held TINYINT(1) NOT NULL DEFAULT 0,
  is_mandatory   TINYINT(1)   NOT NULL DEFAULT 0,
  is_received    TINYINT(1)   NOT NULL DEFAULT 0,
  retention_years TINYINT UNSIGNED NOT NULL DEFAULT 8,
  retain_until   DATE         NULL,
  legal_hold     TINYINT(1)   NOT NULL DEFAULT 0,
  storage_uri    VARCHAR(500) NULL,
  content_sha256 CHAR(64)     NULL,
  size_bytes     BIGINT UNSIGNED NULL,
  mime_type      VARCHAR(100) NULL,
  uploaded_by    BIGINT UNSIGNED NULL,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY ix_doc_object (entity_id, object_type, object_id, doc_type),
  KEY ix_doc_type (entity_id, doc_type, doc_date),
  KEY ix_doc_ref (entity_id, doc_ref),
  KEY ix_doc_retention (entity_id, retain_until, legal_hold),
  KEY ix_doc_hash (content_sha256),
  KEY ix_doc_missing (entity_id, is_mandatory, is_received),
  CONSTRAINT fk_doc_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- Versions are additive. A superseded document is never overwritten, because
-- the assessment that relied on version 1 must remain reproducible.
CREATE TABLE document_version (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  document_id    BIGINT UNSIGNED NOT NULL,
  version_no     SMALLINT UNSIGNED NOT NULL,
  storage_uri    VARCHAR(500) NOT NULL,
  content_sha256 CHAR(64)     NOT NULL,
  size_bytes     BIGINT UNSIGNED NOT NULL,
  mime_type      VARCHAR(100) NULL,
  supersede_reason VARCHAR(300) NULL,
  uploaded_by    BIGINT UNSIGNED NULL,
  uploaded_at    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_dv (document_id, version_no),
  CONSTRAINT fk_dv_doc FOREIGN KEY (document_id) REFERENCES document (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =========================================================================
--  EXCEPTIONS AND WORK QUEUE
-- =========================================================================
CREATE TABLE exception_item (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  rule_id        VARCHAR(30)  NOT NULL,
  severity       ENUM('CRITICAL','HIGH','MEDIUM','INFO') NOT NULL,
  exception_type VARCHAR(40)  NOT NULL,
  title          VARCHAR(300) NOT NULL,
  detail         VARCHAR(1000) NOT NULL,
  object_type    VARCHAR(40)  NOT NULL,
  object_id      BIGINT UNSIGNED NOT NULL,
  object_ref     VARCHAR(60)  NULL,
  exposure       DECIMAL(20,4) NOT NULL DEFAULT 0,
  deadline_on    DATE         NULL,
  first_seen_on  DATE         NOT NULL,
  age_days       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  owner_user_id  BIGINT UNSIGNED NULL,
  owner_role_id  BIGINT UNSIGNED NULL,
  is_open        TINYINT(1)   NOT NULL DEFAULT 1,
  resolution     VARCHAR(500) NULL,
  resolved_by    BIGINT UNSIGNED NULL,
  resolved_at    DATETIME(3)  NULL,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_exc (entity_id, rule_id, object_type, object_id),
  -- the compliance monitor's default sort: open, worst first, biggest exposure
  KEY ix_exc_monitor (entity_id, is_open, severity, exposure),
  KEY ix_exc_object (entity_id, object_type, object_id),
  KEY ix_exc_owner (entity_id, owner_user_id, is_open),
  KEY ix_exc_deadline (entity_id, is_open, deadline_on),
  KEY ix_exc_type (entity_id, exception_type, is_open),
  CONSTRAINT fk_exc_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

CREATE TABLE work_task (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  task_kind      VARCHAR(40)  NOT NULL,        -- approval, deadline, exception, recon…
  title          VARCHAR(300) NOT NULL,
  detail         VARCHAR(1000) NOT NULL,
  severity       ENUM('CRITICAL','HIGH','MEDIUM','INFO') NOT NULL DEFAULT 'MEDIUM',
  object_type    VARCHAR(40)  NOT NULL,
  object_id      BIGINT UNSIGNED NOT NULL,
  route          VARCHAR(200) NOT NULL,
  due_on         DATE         NULL,
  assigned_user_id BIGINT UNSIGNED NULL,
  assigned_role_id BIGINT UNSIGNED NULL,
  status         ENUM('OPEN','IN_PROGRESS','DONE','CANCELLED') NOT NULL DEFAULT 'OPEN',
  completed_by   BIGINT UNSIGNED NULL,
  completed_at   DATETIME(3)  NULL,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY ix_wt_inbox (entity_id, assigned_user_id, status, severity, due_on),
  KEY ix_wt_role (entity_id, assigned_role_id, status),
  KEY ix_wt_object (entity_id, object_type, object_id),
  CONSTRAINT fk_wt_entity FOREIGN KEY (entity_id) REFERENCES legal_entity (id)
) ENGINE=InnoDB;

-- =========================================================================
--  INVENTORY  — stock ledger carrying landed cost, partitioned
-- =========================================================================
CREATE TABLE stock_ledger (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  period_key     INT UNSIGNED NOT NULL,
  entity_id      BIGINT UNSIGNED NOT NULL,
  site_id        BIGINT UNSIGNED NOT NULL,
  item_id        BIGINT UNSIGNED NOT NULL,
  lot_no         VARCHAR(40)  NULL,
  txn_date       DATE         NOT NULL,
  txn_type       ENUM('RECEIPT','ISSUE','TRANSFER_IN','TRANSFER_OUT','ADJUST_UP','ADJUST_DOWN','REVALUE','SCRAP','RETURN') NOT NULL,
  source_type    VARCHAR(40)  NULL,
  source_id      BIGINT UNSIGNED NULL,
  qty            DECIMAL(20,6) NOT NULL,
  uom            VARCHAR(10)  NOT NULL,
  unit_cost      DECIMAL(20,6) NOT NULL DEFAULT 0,
  value          DECIMAL(20,4) NOT NULL DEFAULT 0,
  -- landed cost broken out so a valuation can be explained line by line
  goods_component DECIMAL(20,4) NOT NULL DEFAULT 0,
  duty_component  DECIMAL(20,4) NOT NULL DEFAULT 0,
  freight_component DECIMAL(20,4) NOT NULL DEFAULT 0,
  other_component DECIMAL(20,4) NOT NULL DEFAULT 0,
  is_bonded      TINYINT(1)   NOT NULL DEFAULT 0,
  voucher_id     BIGINT UNSIGNED NULL,         -- NO FK: partitioned
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (period_key, id),
  KEY ix_stk_id (id),
  KEY ix_stk_item (entity_id, site_id, item_id, period_key, txn_date, id),
  KEY ix_stk_lot (entity_id, item_id, lot_no, txn_date),
  KEY ix_stk_source (source_type, source_id)
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

-- Rollup, same idea as account_period_balance: stock valuation reads this.
CREATE TABLE stock_balance (
  entity_id      BIGINT UNSIGNED NOT NULL,
  site_id        BIGINT UNSIGNED NOT NULL,
  item_id        BIGINT UNSIGNED NOT NULL,
  period_key     INT UNSIGNED NOT NULL,
  is_bonded      TINYINT(1)   NOT NULL DEFAULT 0,
  opening_qty    DECIMAL(24,6) NOT NULL DEFAULT 0,
  opening_value  DECIMAL(24,4) NOT NULL DEFAULT 0,
  in_qty         DECIMAL(24,6) NOT NULL DEFAULT 0,
  in_value       DECIMAL(24,4) NOT NULL DEFAULT 0,
  out_qty        DECIMAL(24,6) NOT NULL DEFAULT 0,
  out_value      DECIMAL(24,4) NOT NULL DEFAULT 0,
  closing_qty    DECIMAL(24,6) NOT NULL DEFAULT 0,
  closing_value  DECIMAL(24,4) NOT NULL DEFAULT 0,
  wavg_unit_cost DECIMAL(20,6) NOT NULL DEFAULT 0,
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (entity_id, site_id, item_id, period_key, is_bonded),
  KEY ix_sb_period (entity_id, period_key, item_id)
) ENGINE=InnoDB;

-- >>> 004_views_procs.sql ------------------------------------------------

-- ============================================================================
--  HB TRADE — 004 VIEWS, PROCEDURES AND MAINTENANCE
--
--  Views here are CONVENIENCE only. No screen depends on a view for its hot
--  path: the API reads the rollup tables (account_period_balance,
--  stock_balance) and maintained header totals. A view that aggregates a
--  partitioned fact table is fine for a nightly report and wrong for a grid.
--  Each view below says which it is.
-- ============================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
--  TRIAL BALANCE  — reads the ROLLUP. Safe for interactive use.
--  One row per account per book per period; a full trial balance for an entity
--  is a few thousand rows regardless of how many posting lines exist.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_trial_balance AS
SELECT
  b.entity_id,
  b.book_id,
  b.period_key,
  a.id                AS account_id,
  a.code              AS account_code,
  a.name              AS account_name,
  a.account_class,
  a.account_type,
  a.schedule_iii_group,
  a.subledger,
  a.is_monetary,
  b.opening_dr,
  b.opening_cr,
  b.period_dr,
  b.period_cr,
  -- closing is opening + movement; the rollup stores movement, not closing,
  -- so a re-stated opening never leaves a stale closing behind
  (b.opening_dr + b.period_dr) AS closing_dr,
  (b.opening_cr + b.period_cr) AS closing_cr,
  ((b.opening_dr + b.period_dr) - (b.opening_cr + b.period_cr)) AS net_balance
FROM account_period_balance b
JOIN gl_account a ON a.id = b.account_id;

-- ---------------------------------------------------------------------------
--  DECLARATION REGISTER — reads the declaration HEADER only, and every
--  monetary figure on it is maintained, so no aggregation. Safe interactive.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_declaration_register AS
SELECT
  d.entity_id,
  d.period_key,
  d.id                AS declaration_id,
  d.declaration_no,
  d.declaration_type,
  d.direction,
  d.declaration_date,
  d.filed_on,
  d.cleared_on,
  d.status,
  d.is_provisional,
  d.port_code,
  d.currency,
  d.statutory_fx_rate,
  d.assessable_value,
  d.duty_total,
  d.duty_recoverable,
  d.duty_inventoriable,
  d.duty_assessed,
  (d.duty_assessed - d.duty_total) AS duty_assessment_difference,
  d.duty_saved,
  d.duty_blocked,
  d.error_count,
  d.warning_count,
  p.name              AS party_name,
  p.country_code      AS party_country,
  s.shipment_no,
  s.transport_doc_no
FROM declaration d
LEFT JOIN trade_party p ON p.id = d.party_id
LEFT JOIN shipment    s ON s.id = d.shipment_id;

-- ---------------------------------------------------------------------------
--  DUTY BY LEVY — AGGREGATES a partitioned fact table. Batch/report use only.
--  Always constrain entity_id and period_key so partition pruning applies;
--  ix_dlv_register then serves it index-only.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_duty_by_levy AS
SELECT
  entity_id,
  period_key,
  levy_code,
  levy_name,
  rate_source,
  COUNT(*)                          AS line_count,
  SUM(amount)                       AS duty_amount,
  SUM(CASE WHEN is_recoverable = 1 THEN amount ELSE 0 END) AS recoverable_amount,
  SUM(CASE WHEN is_recoverable = 0 THEN amount ELSE 0 END) AS inventoriable_amount
FROM declaration_levy
GROUP BY entity_id, period_key, levy_code, levy_name, rate_source;

-- ---------------------------------------------------------------------------
--  CLEARING ACCOUNT AGEING — the completeness control from the RD: a clearing
--  account with an aged balance means a landed-cost element was accrued and
--  never actualised. AGGREGATES posting_line: batch/report use, always with
--  entity + account + date bounds. ix_pl_clearing serves it.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_clearing_ageing AS
SELECT
  pl.entity_id,
  pl.book_id,
  pl.account_id,
  a.code                            AS account_code,
  a.name                            AS account_name,
  pl.shipment_id,
  MIN(pl.voucher_date)              AS oldest_entry,
  DATEDIFF(CURDATE(), MIN(pl.voucher_date)) AS age_days,
  SUM(CASE WHEN pl.dr_cr = 'DR' THEN pl.amount_func ELSE 0 END) AS total_dr,
  SUM(CASE WHEN pl.dr_cr = 'CR' THEN pl.amount_func ELSE 0 END) AS total_cr,
  SUM(CASE WHEN pl.dr_cr = 'DR' THEN pl.amount_func ELSE -pl.amount_func END) AS net_balance,
  COUNT(*)                          AS line_count
FROM posting_line pl
JOIN gl_account a ON a.id = pl.account_id
WHERE a.account_type = 'CLEARING'
GROUP BY pl.entity_id, pl.book_id, pl.account_id, a.code, a.name, pl.shipment_id
HAVING net_balance <> 0;

-- ---------------------------------------------------------------------------
--  LICENCE OBLIGATION STATUS — header only, maintained figures. Interactive.
--  Percentage guards against the divide-by-zero that a no-obligation scheme
--  (e.g. MOOWR) would otherwise produce.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_licence_status AS
SELECT
  l.entity_id,
  l.id                              AS licence_id,
  l.licence_no,
  s.code                            AS scheme_code,
  s.name                            AS scheme_name,
  l.status,
  l.issued_on,
  l.import_valid_to,
  l.export_valid_to,
  l.cif_entitlement,
  l.cif_utilised,
  (l.cif_entitlement - l.cif_utilised) AS cif_available,
  l.duty_saved,
  l.obligation_type,
  l.obligation_amount,
  l.obligation_fulfilled,
  CASE WHEN l.obligation_amount = 0 THEN 100.0000
       ELSE ROUND(100 * l.obligation_fulfilled / l.obligation_amount, 4) END AS pct_fulfilled,
  GREATEST(l.obligation_amount - l.obligation_fulfilled, 0) AS obligation_shortfall,
  l.exposure_duty,
  l.exposure_interest,
  (l.exposure_duty + l.exposure_interest) AS total_exposure,
  DATEDIFF(l.export_valid_to, CURDATE()) AS days_to_deadline
FROM licence l
JOIN scheme s ON s.id = l.scheme_id;

-- ---------------------------------------------------------------------------
--  COST SHEET SUMMARY — header only. Interactive.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_cost_sheet_summary AS
SELECT
  cs.entity_id,
  cs.id                             AS cost_sheet_id,
  cs.cost_sheet_no,
  cs.status,
  cs.direction,
  sh.shipment_no,
  sh.transport_doc_no,
  cs.goods_value,
  cs.total_estimate,
  cs.total_accrued,
  cs.total_actual,
  cs.variance_invoiced,
  cs.uninvoiced_accrual,
  cs.capitalised_amount,
  cs.expensed_amount,
  cs.recoverable_amount,
  (cs.goods_value + cs.total_actual) AS landed_value_to_date,
  cs.tolerance_breaches,
  cs.stock_on_hand_pct,
  cs.closed_on
FROM cost_sheet cs
JOIN shipment sh ON sh.id = cs.shipment_id;

-- ---------------------------------------------------------------------------
--  OPEN EXCEPTION QUEUE — the compliance monitor's ranking, expressed once.
--  Composite score: severity weight × log-ish exposure band × age.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_open_exceptions AS
SELECT
  e.entity_id,
  e.id                              AS exception_id,
  e.rule_id,
  e.severity,
  e.exception_type,
  e.title,
  e.detail,
  e.object_type,
  e.object_id,
  e.object_ref,
  e.exposure,
  e.deadline_on,
  e.age_days,
  e.owner_user_id,
  CASE e.severity WHEN 'CRITICAL' THEN 4 WHEN 'HIGH' THEN 3
                  WHEN 'MEDIUM'  THEN 2 ELSE 1 END AS severity_weight,
  (CASE e.severity WHEN 'CRITICAL' THEN 4 WHEN 'HIGH' THEN 3
                   WHEN 'MEDIUM'  THEN 2 ELSE 1 END) * 1000000
    + LEAST(e.exposure, 999999)
    + LEAST(e.age_days, 999)        AS rank_score
FROM exception_item e
WHERE e.is_open = 1;

-- ---------------------------------------------------------------------------
--  MANDATORY DOCUMENTS NOT RECEIVED — the document completeness control.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_document_gaps AS
SELECT
  entity_id, object_type, object_id, doc_type, title, doc_ref, created_at
FROM document
WHERE is_mandatory = 1 AND is_received = 0;

-- ===========================================================================
--  PARTITION MAINTENANCE
--  Every partitioned table ends with pmax VALUES LESS THAN MAXVALUE. Adding a
--  month means REORGANIZE pmax into (new month, pmax). Run this monthly, well
--  ahead of need: a partitioned table that has fallen back on pmax still
--  works, it just stops pruning.
-- ===========================================================================
DROP PROCEDURE IF EXISTS sp_add_month_partition;
DELIMITER $$
CREATE PROCEDURE sp_add_month_partition(IN p_table VARCHAR(64), IN p_period INT)
BEGIN
  DECLARE v_next INT;
  DECLARE v_name VARCHAR(64);
  DECLARE v_exists INT DEFAULT 0;

  -- next period boundary: 202612 -> 202701
  SET v_next = IF(p_period % 100 = 12, (p_period DIV 100 + 1) * 100 + 1, p_period + 1);
  SET v_name = CONCAT('p', p_period);

  SELECT COUNT(*) INTO v_exists
  FROM information_schema.PARTITIONS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table AND PARTITION_NAME = v_name;

  IF v_exists = 0 THEN
    SET @ddl = CONCAT(
      'ALTER TABLE `', p_table, '` REORGANIZE PARTITION pmax INTO (',
      'PARTITION ', v_name, ' VALUES LESS THAN (', v_next, '), ',
      'PARTITION pmax VALUES LESS THAN MAXVALUE)');
    PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
  END IF;
END$$

-- Add the same month to every partitioned fact table in one call.
DROP PROCEDURE IF EXISTS sp_extend_partitions$$
CREATE PROCEDURE sp_extend_partitions(IN p_period INT)
BEGIN
  CALL sp_add_month_partition('voucher',          p_period);
  CALL sp_add_month_partition('posting_line',     p_period);
  CALL sp_add_month_partition('declaration',      p_period);
  CALL sp_add_month_partition('declaration_line', p_period);
  CALL sp_add_month_partition('declaration_levy', p_period);
  CALL sp_add_month_partition('stock_ledger',     p_period);
END$$

-- ---------------------------------------------------------------------------
--  ROLLUP REBUILD — the reconciliation of the rollup against the fact table.
--  account_period_balance is maintained transactionally, so this should never
--  change anything; it exists so that "does the rollup still agree with the
--  postings?" is a question with a runnable answer. Report-only: it writes to
--  a check table, it does NOT silently correct the rollup.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_check_rollup$$
CREATE PROCEDURE sp_check_rollup(IN p_entity BIGINT UNSIGNED, IN p_period INT)
BEGIN
  DELETE FROM rollup_check WHERE entity_id = p_entity AND period_key = p_period;

  INSERT INTO rollup_check
    (entity_id, book_id, account_id, period_key, rollup_dr, rollup_cr, fact_dr, fact_cr, checked_at)
  SELECT
    COALESCE(b.entity_id, f.entity_id),
    COALESCE(b.book_id,   f.book_id),
    COALESCE(b.account_id,f.account_id),
    p_period,
    COALESCE(b.period_dr, 0), COALESCE(b.period_cr, 0),
    COALESCE(f.fact_dr, 0),   COALESCE(f.fact_cr, 0),
    NOW(3)
  FROM (
    SELECT entity_id, book_id, account_id, period_dr, period_cr
    FROM account_period_balance
    WHERE entity_id = p_entity AND period_key = p_period
  ) b
  LEFT JOIN (
    SELECT entity_id, book_id, account_id,
           SUM(CASE WHEN dr_cr = 'DR' THEN amount_func ELSE 0 END) AS fact_dr,
           SUM(CASE WHEN dr_cr = 'CR' THEN amount_func ELSE 0 END) AS fact_cr
    FROM posting_line
    WHERE entity_id = p_entity AND period_key = p_period
    GROUP BY entity_id, book_id, account_id
  ) f ON f.entity_id = b.entity_id AND f.book_id = b.book_id AND f.account_id = b.account_id;
END$$
DELIMITER ;

CREATE TABLE IF NOT EXISTS rollup_check (
  entity_id   BIGINT UNSIGNED NOT NULL,
  book_id     BIGINT UNSIGNED NOT NULL,
  account_id  BIGINT UNSIGNED NOT NULL,
  period_key  INT UNSIGNED NOT NULL,
  rollup_dr   DECIMAL(24,4) NOT NULL DEFAULT 0,
  rollup_cr   DECIMAL(24,4) NOT NULL DEFAULT 0,
  fact_dr     DECIMAL(24,4) NOT NULL DEFAULT 0,
  fact_cr     DECIMAL(24,4) NOT NULL DEFAULT 0,
  diff_dr     DECIMAL(24,4) AS (rollup_dr - fact_dr) STORED,
  diff_cr     DECIMAL(24,4) AS (rollup_cr - fact_cr) STORED,
  checked_at  DATETIME(3) NOT NULL,
  PRIMARY KEY (entity_id, book_id, account_id, period_key),
  KEY ix_rc_diff (entity_id, period_key, diff_dr, diff_cr)
) ENGINE=InnoDB;

-- >>> 005_ui_fields.sql ------------------------------------------------

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

-- >>> 006_monthly_2027_partitions.sql ------------------------------------------------

-- ============================================================================
--  HB TRADE — 006 MONTHLY PARTITIONS FOR FY2027
--
--  Migrations 002/003 create a single yearly catch-all partition p2027 (VALUES
--  LESS THAN 202801). Once a full year of data lands there, period-scoped
--  queries prune to the year but not to the month. This splits p2027 into the
--  twelve monthly partitions so a one-month register or ledger enquiry prunes
--  to exactly one partition — the same shape sp_extend_partitions would produce
--  going forward. REORGANIZE redistributes existing rows in place.
-- ============================================================================

ALTER TABLE voucher REORGANIZE PARTITION p2027 INTO (
  PARTITION p202701 VALUES LESS THAN (202702), PARTITION p202702 VALUES LESS THAN (202703),
  PARTITION p202703 VALUES LESS THAN (202704), PARTITION p202704 VALUES LESS THAN (202705),
  PARTITION p202705 VALUES LESS THAN (202706), PARTITION p202706 VALUES LESS THAN (202707),
  PARTITION p202707 VALUES LESS THAN (202708), PARTITION p202708 VALUES LESS THAN (202709),
  PARTITION p202709 VALUES LESS THAN (202710), PARTITION p202710 VALUES LESS THAN (202711),
  PARTITION p202711 VALUES LESS THAN (202712), PARTITION p202712 VALUES LESS THAN (202801));

ALTER TABLE posting_line REORGANIZE PARTITION p2027 INTO (
  PARTITION p202701 VALUES LESS THAN (202702), PARTITION p202702 VALUES LESS THAN (202703),
  PARTITION p202703 VALUES LESS THAN (202704), PARTITION p202704 VALUES LESS THAN (202705),
  PARTITION p202705 VALUES LESS THAN (202706), PARTITION p202706 VALUES LESS THAN (202707),
  PARTITION p202707 VALUES LESS THAN (202708), PARTITION p202708 VALUES LESS THAN (202709),
  PARTITION p202709 VALUES LESS THAN (202710), PARTITION p202710 VALUES LESS THAN (202711),
  PARTITION p202711 VALUES LESS THAN (202712), PARTITION p202712 VALUES LESS THAN (202801));

ALTER TABLE declaration REORGANIZE PARTITION p2027 INTO (
  PARTITION p202701 VALUES LESS THAN (202702), PARTITION p202702 VALUES LESS THAN (202703),
  PARTITION p202703 VALUES LESS THAN (202704), PARTITION p202704 VALUES LESS THAN (202705),
  PARTITION p202705 VALUES LESS THAN (202706), PARTITION p202706 VALUES LESS THAN (202707),
  PARTITION p202707 VALUES LESS THAN (202708), PARTITION p202708 VALUES LESS THAN (202709),
  PARTITION p202709 VALUES LESS THAN (202710), PARTITION p202710 VALUES LESS THAN (202711),
  PARTITION p202711 VALUES LESS THAN (202712), PARTITION p202712 VALUES LESS THAN (202801));

ALTER TABLE declaration_line REORGANIZE PARTITION p2027 INTO (
  PARTITION p202701 VALUES LESS THAN (202702), PARTITION p202702 VALUES LESS THAN (202703),
  PARTITION p202703 VALUES LESS THAN (202704), PARTITION p202704 VALUES LESS THAN (202705),
  PARTITION p202705 VALUES LESS THAN (202706), PARTITION p202706 VALUES LESS THAN (202707),
  PARTITION p202707 VALUES LESS THAN (202708), PARTITION p202708 VALUES LESS THAN (202709),
  PARTITION p202709 VALUES LESS THAN (202710), PARTITION p202710 VALUES LESS THAN (202711),
  PARTITION p202711 VALUES LESS THAN (202712), PARTITION p202712 VALUES LESS THAN (202801));

ALTER TABLE declaration_levy REORGANIZE PARTITION p2027 INTO (
  PARTITION p202701 VALUES LESS THAN (202702), PARTITION p202702 VALUES LESS THAN (202703),
  PARTITION p202703 VALUES LESS THAN (202704), PARTITION p202704 VALUES LESS THAN (202705),
  PARTITION p202705 VALUES LESS THAN (202706), PARTITION p202706 VALUES LESS THAN (202707),
  PARTITION p202707 VALUES LESS THAN (202708), PARTITION p202708 VALUES LESS THAN (202709),
  PARTITION p202709 VALUES LESS THAN (202710), PARTITION p202710 VALUES LESS THAN (202711),
  PARTITION p202711 VALUES LESS THAN (202712), PARTITION p202712 VALUES LESS THAN (202801));

ALTER TABLE stock_ledger REORGANIZE PARTITION p2027 INTO (
  PARTITION p202701 VALUES LESS THAN (202702), PARTITION p202702 VALUES LESS THAN (202703),
  PARTITION p202703 VALUES LESS THAN (202704), PARTITION p202704 VALUES LESS THAN (202705),
  PARTITION p202705 VALUES LESS THAN (202706), PARTITION p202706 VALUES LESS THAN (202707),
  PARTITION p202707 VALUES LESS THAN (202708), PARTITION p202708 VALUES LESS THAN (202709),
  PARTITION p202709 VALUES LESS THAN (202710), PARTITION p202710 VALUES LESS THAN (202711),
  PARTITION p202711 VALUES LESS THAN (202712), PARTITION p202712 VALUES LESS THAN (202801));

-- >>> 007_voucher_names.sql ------------------------------------------------

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

-- >>> 008_integration.sql ------------------------------------------------

-- ============================================================================
--  HB TRADE — 008 INTEGRATION LOG
--
--  The message journal for external connectors (ICEGATE customs, EDPMS export
--  realisation, bank host). Every outbound transmission and inbound status is
--  recorded here with its lifecycle, so a transmission can be traced, retried
--  and reconciled. In this build the connectors are SIMULATED — they move a
--  message through the same states a real gateway would, without a live
--  endpoint — but the journal, states and API are production-shaped.
-- ============================================================================

SET NAMES utf8mb4;

CREATE TABLE integration_log (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id      BIGINT UNSIGNED NOT NULL,
  channel        ENUM('ICEGATE','EDPMS','BANK_HOST','DGFT','GSTN') NOT NULL,
  direction      ENUM('OUT','IN') NOT NULL,
  object_type    VARCHAR(40)  NOT NULL,
  object_id      BIGINT UNSIGNED NULL,
  object_ref     VARCHAR(60)  NULL,
  message_type   VARCHAR(40)  NOT NULL,      -- e.g. SB_TRANSMIT, BOE_STATUS, IRM_MATCH
  request_ref    VARCHAR(60)  NULL,          -- our correlation reference
  gateway_ref    VARCHAR(60)  NULL,          -- the gateway's job/message id
  status         ENUM('QUEUED','SENT','ACKED','ACCEPTED','QUERIED','REJECTED','ERROR') NOT NULL DEFAULT 'QUEUED',
  status_detail  VARCHAR(600) NULL,
  request_summary  VARCHAR(1000) NULL,
  response_summary VARCHAR(1000) NULL,
  attempts       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  simulated      TINYINT(1)   NOT NULL DEFAULT 1,
  created_by     BIGINT UNSIGNED NULL,
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY ix_intlog_channel (entity_id, channel, created_at),
  KEY ix_intlog_object (entity_id, object_type, object_id),
  KEY ix_intlog_status (entity_id, status, created_at)
) ENGINE=InnoDB;

-- >>> 009_operations.sql ------------------------------------------------

-- ============================================================================
--  HB TRADE — 009 OPERATIONS
--  Record-list tables behind the operational screens that were previously
--  sample-data only: indents, goods receipts, document sets, bookings,
--  containers, export enquiries, export invoices, provider invoices, bank
--  charges and insurance policies. Each is a straightforward entity-scoped
--  header table served through the generic CRUD layer (create/read/update/
--  delete + server-side paging + search), exactly like parties and orders.
--  Non-partitioned: these are low/medium-volume operational registers.
-- ============================================================================
SET NAMES utf8mb4;

-- Idempotent: these registers carry only operational data, so a re-run rebuilds
-- them cleanly. (`container` already exists in the base schema, so this module's
-- container register is named `freight_container` to avoid the collision.)
DROP TABLE IF EXISTS indent;
DROP TABLE IF EXISTS goods_receipt;
DROP TABLE IF EXISTS document_set;
DROP TABLE IF EXISTS booking;
DROP TABLE IF EXISTS freight_container;
DROP TABLE IF EXISTS enquiry;
DROP TABLE IF EXISTS export_invoice;
DROP TABLE IF EXISTS provider_invoice;
DROP TABLE IF EXISTS bank_charge;
DROP TABLE IF EXISTS insurance_policy;

CREATE TABLE indent (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  indent_no     VARCHAR(40)  NOT NULL,
  indent_date   DATE         NOT NULL,
  item_desc     VARCHAR(240) NOT NULL,
  qty           DECIMAL(18,3) NOT NULL DEFAULT 0,
  uom           VARCHAR(12)  NOT NULL DEFAULT 'PCS',
  required_by   DATE         NULL,
  cost_centre   VARCHAR(40)  NULL,
  precheck_status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
  status        VARCHAR(24)  NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (id), KEY ix_indent_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE goods_receipt (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  grn_no        VARCHAR(40)  NOT NULL,
  grn_date      DATE         NOT NULL,
  shipment_no   VARCHAR(40)  NULL,
  supplier      VARCHAR(160) NULL,
  warehouse     VARCHAR(80)  NULL,
  line_count    INT          NOT NULL DEFAULT 0,
  value         DECIMAL(18,2) NOT NULL DEFAULT 0,
  currency      VARCHAR(3)   NOT NULL DEFAULT 'INR',
  status        VARCHAR(24)  NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (id), KEY ix_grn_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE document_set (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  set_no        VARCHAR(40)  NOT NULL,
  shipment_no   VARCHAR(40)  NULL,
  doc_type      VARCHAR(60)  NULL,
  party         VARCHAR(160) NULL,
  received_on   DATE         NULL,
  completeness_pct DECIMAL(5,1) NOT NULL DEFAULT 0,
  status        VARCHAR(24)  NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (id), KEY ix_docset_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE booking (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  booking_no    VARCHAR(40)  NOT NULL,
  booking_date  DATE         NOT NULL,
  carrier       VARCHAR(120) NULL,
  transport_mode VARCHAR(12) NOT NULL DEFAULT 'SEA',
  origin_port   VARCHAR(60)  NULL,
  dest_port     VARCHAR(60)  NULL,
  container_type VARCHAR(24) NULL,
  containers    INT          NOT NULL DEFAULT 0,
  status        VARCHAR(24)  NOT NULL DEFAULT 'REQUESTED',
  PRIMARY KEY (id), KEY ix_booking_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE freight_container (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  container_no  VARCHAR(24)  NOT NULL,
  size_type     VARCHAR(16)  NULL,
  shipment_no   VARCHAR(40)  NULL,
  seal_no       VARCHAR(30)  NULL,
  gross_weight_kg DECIMAL(14,2) NOT NULL DEFAULT 0,
  free_time_days INT         NOT NULL DEFAULT 0,
  demurrage     DECIMAL(16,2) NOT NULL DEFAULT 0,
  status        VARCHAR(24)  NOT NULL DEFAULT 'IN_TRANSIT',
  PRIMARY KEY (id), KEY ix_fcontainer_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE enquiry (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  enquiry_no    VARCHAR(40)  NOT NULL,
  enquiry_date  DATE         NOT NULL,
  customer      VARCHAR(160) NULL,
  country_code  VARCHAR(2)   NULL,
  item_desc     VARCHAR(240) NULL,
  qty           DECIMAL(18,3) NOT NULL DEFAULT 0,
  target_price  DECIMAL(16,2) NOT NULL DEFAULT 0,
  currency      VARCHAR(3)   NOT NULL DEFAULT 'USD',
  status        VARCHAR(24)  NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (id), KEY ix_enquiry_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE export_invoice (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  invoice_no    VARCHAR(40)  NOT NULL,
  invoice_date  DATE         NOT NULL,
  customer      VARCHAR(160) NULL,
  currency      VARCHAR(3)   NOT NULL DEFAULT 'USD',
  fob_value     DECIMAL(18,2) NOT NULL DEFAULT 0,
  incoterm      VARCHAR(6)   NULL,
  shipment_no   VARCHAR(40)  NULL,
  status        VARCHAR(24)  NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (id), KEY ix_expinv_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE provider_invoice (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  invoice_no    VARCHAR(40)  NOT NULL,
  invoice_date  DATE         NOT NULL,
  provider      VARCHAR(160) NULL,
  service_type  VARCHAR(40)  NULL,
  currency      VARCHAR(3)   NOT NULL DEFAULT 'INR',
  amount        DECIMAL(18,2) NOT NULL DEFAULT 0,
  shipment_no   VARCHAR(40)  NULL,
  status        VARCHAR(24)  NOT NULL DEFAULT 'RECEIVED',
  PRIMARY KEY (id), KEY ix_provinv_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE bank_charge (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  charge_ref    VARCHAR(40)  NOT NULL,
  charge_date   DATE         NOT NULL,
  bank          VARCHAR(120) NULL,
  instrument_no VARCHAR(40)  NULL,
  charge_type   VARCHAR(60)  NULL,
  currency      VARCHAR(3)   NOT NULL DEFAULT 'INR',
  amount        DECIMAL(16,2) NOT NULL DEFAULT 0,
  status        VARCHAR(24)  NOT NULL DEFAULT 'POSTED',
  PRIMARY KEY (id), KEY ix_bankchg_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE insurance_policy (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_id     BIGINT UNSIGNED NOT NULL,
  policy_no     VARCHAR(40)  NOT NULL,
  insurer       VARCHAR(160) NULL,
  cover_type    VARCHAR(60)  NULL,
  currency      VARCHAR(3)   NOT NULL DEFAULT 'INR',
  sum_insured   DECIMAL(18,2) NOT NULL DEFAULT 0,
  premium       DECIMAL(16,2) NOT NULL DEFAULT 0,
  valid_from    DATE         NULL,
  valid_to      DATE         NULL,
  status        VARCHAR(24)  NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (id), KEY ix_inspol_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- >>> 010_operations2.sql ------------------------------------------------

-- ============================================================================
--  HB TRADE — 010 OPERATIONS (batch 2)
--  The remaining record-list registers, served through the generic CRUD layer
--  exactly like batch 1 (migration 009): sourcing comparisons, post-clearance
--  cases, export realisations, container stuffing, bank presentations,
--  collections & bills, FX exposure/hedges, bonded operations, regulatory
--  changes, credentials/registrations, the filing calendar, origin & preference
--  determinations, document checklists and compliance content packs.
--  Idempotent (DROP IF EXISTS) so the module re-applies cleanly.
-- ============================================================================
SET NAMES utf8mb4;

DROP TABLE IF EXISTS sourcing_quote;
DROP TABLE IF EXISTS post_clearance_case;
DROP TABLE IF EXISTS realisation;
DROP TABLE IF EXISTS stuffing;
DROP TABLE IF EXISTS presentation;
DROP TABLE IF EXISTS collection_bill;
DROP TABLE IF EXISTS fx_position;
DROP TABLE IF EXISTS bonded_entry;
DROP TABLE IF EXISTS regulatory_change;
DROP TABLE IF EXISTS credential;
DROP TABLE IF EXISTS filing;
DROP TABLE IF EXISTS origin_determination;
DROP TABLE IF EXISTS checklist;
DROP TABLE IF EXISTS compliance_pack;

CREATE TABLE sourcing_quote (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  rfq_no VARCHAR(40) NOT NULL, rfq_date DATE NOT NULL, item_desc VARCHAR(240) NULL,
  supplier VARCHAR(160) NULL, country_code VARCHAR(2) NULL, currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  unit_price DECIMAL(16,4) NOT NULL DEFAULT 0, lead_time_days INT NOT NULL DEFAULT 0,
  landed_estimate DECIMAL(18,2) NOT NULL DEFAULT 0, status VARCHAR(24) NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (id), KEY ix_srcq_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE post_clearance_case (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  case_no VARCHAR(40) NOT NULL, opened_on DATE NOT NULL, declaration_no VARCHAR(40) NULL,
  case_type VARCHAR(40) NULL, authority VARCHAR(80) NULL, exposure DECIMAL(18,2) NOT NULL DEFAULT 0,
  currency VARCHAR(3) NOT NULL DEFAULT 'INR', due_on DATE NULL, status VARCHAR(24) NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (id), KEY ix_pcc_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE realisation (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  realisation_no VARCHAR(40) NOT NULL, invoice_no VARCHAR(40) NULL, customer VARCHAR(160) NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD', invoice_value DECIMAL(18,2) NOT NULL DEFAULT 0,
  realised_value DECIMAL(18,2) NOT NULL DEFAULT 0, due_date DATE NULL, realised_on DATE NULL,
  edpms_status VARCHAR(24) NULL, status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (id), KEY ix_real_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stuffing (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  stuffing_no VARCHAR(40) NOT NULL, stuffing_date DATE NOT NULL, shipment_no VARCHAR(40) NULL,
  container_no VARCHAR(24) NULL, location VARCHAR(80) NULL, supervisor VARCHAR(120) NULL,
  packages INT NOT NULL DEFAULT 0, gross_weight_kg DECIMAL(14,2) NOT NULL DEFAULT 0,
  status VARCHAR(24) NOT NULL DEFAULT 'PLANNED',
  PRIMARY KEY (id), KEY ix_stuff_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE presentation (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  presentation_no VARCHAR(40) NOT NULL, presented_on DATE NULL, instrument_no VARCHAR(40) NULL,
  bank VARCHAR(120) NULL, currency VARCHAR(3) NOT NULL DEFAULT 'USD', amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  discrepancies INT NOT NULL DEFAULT 0, deadline DATE NULL, status VARCHAR(24) NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (id), KEY ix_pres_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE collection_bill (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  bill_no VARCHAR(40) NOT NULL, bill_date DATE NOT NULL, drawee VARCHAR(160) NULL,
  bank VARCHAR(120) NULL, collection_type VARCHAR(24) NULL, currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  amount DECIMAL(18,2) NOT NULL DEFAULT 0, tenor_days INT NOT NULL DEFAULT 0, maturity_on DATE NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'LODGED',
  PRIMARY KEY (id), KEY ix_coll_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE fx_position (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  ref_no VARCHAR(40) NOT NULL, as_of DATE NOT NULL, currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  exposure_type VARCHAR(24) NULL, gross_exposure DECIMAL(18,2) NOT NULL DEFAULT 0,
  hedged_amount DECIMAL(18,2) NOT NULL DEFAULT 0, forward_rate DECIMAL(16,6) NOT NULL DEFAULT 0,
  maturity_on DATE NULL, status VARCHAR(24) NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (id), KEY ix_fx_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE bonded_entry (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  entry_no VARCHAR(40) NOT NULL, entry_date DATE NOT NULL, warehouse_code VARCHAR(40) NULL,
  goods_desc VARCHAR(240) NULL, bond_type VARCHAR(24) NULL, duty_deferred DECIMAL(18,2) NOT NULL DEFAULT 0,
  currency VARCHAR(3) NOT NULL DEFAULT 'INR', rewarehouse_by DATE NULL, status VARCHAR(24) NOT NULL DEFAULT 'IN_BOND',
  PRIMARY KEY (id), KEY ix_bond_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE regulatory_change (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  ref_no VARCHAR(40) NOT NULL, published_on DATE NULL, authority VARCHAR(80) NULL,
  title VARCHAR(240) NOT NULL, category VARCHAR(40) NULL, effective_from DATE NULL,
  impact VARCHAR(16) NULL, owner_role VARCHAR(60) NULL, status VARCHAR(24) NOT NULL DEFAULT 'NEW',
  PRIMARY KEY (id), KEY ix_regchg_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE credential (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  credential_no VARCHAR(60) NOT NULL, credential_type VARCHAR(60) NULL, holder VARCHAR(160) NULL,
  authority VARCHAR(80) NULL, issued_on DATE NULL, valid_to DATE NULL, status VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (id), KEY ix_cred_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE filing (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  filing_ref VARCHAR(60) NOT NULL, filing_name VARCHAR(200) NOT NULL, authority VARCHAR(80) NULL,
  frequency VARCHAR(24) NULL, period VARCHAR(24) NULL, due_on DATE NULL, preparer VARCHAR(120) NULL,
  approver VARCHAR(120) NULL, status VARCHAR(24) NOT NULL DEFAULT 'NOT_STARTED',
  PRIMARY KEY (id), KEY ix_filing_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE origin_determination (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  ref_no VARCHAR(40) NOT NULL, item_desc VARCHAR(240) NULL, hs_code VARCHAR(16) NULL,
  agreement VARCHAR(40) NULL, origin_country VARCHAR(2) NULL, rule_applied VARCHAR(120) NULL,
  value_addition_pct DECIMAL(6,2) NOT NULL DEFAULT 0, coo_ref VARCHAR(60) NULL, status VARCHAR(24) NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (id), KEY ix_origin_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE checklist (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(40) NOT NULL, name VARCHAR(160) NOT NULL, applies_to VARCHAR(60) NULL,
  direction VARCHAR(12) NULL, item_count INT NOT NULL DEFAULT 0, mandatory_count INT NOT NULL DEFAULT 0,
  status VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (id), KEY ix_chk_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE compliance_pack (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, entity_id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(40) NOT NULL, name VARCHAR(160) NOT NULL, jurisdiction VARCHAR(40) NULL,
  version VARCHAR(24) NULL, rule_count INT NOT NULL DEFAULT 0, effective_from DATE NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (id), KEY ix_pack_entity (entity_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
