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
