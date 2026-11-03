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
