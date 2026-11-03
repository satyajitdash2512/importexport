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
