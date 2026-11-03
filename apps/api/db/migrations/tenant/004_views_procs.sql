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
