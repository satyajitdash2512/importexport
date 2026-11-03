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
