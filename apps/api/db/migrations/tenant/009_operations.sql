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
