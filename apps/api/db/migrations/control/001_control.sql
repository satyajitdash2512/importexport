-- ============================================================================
--  HB TRADE — CONTROL DATABASE (hb_control)
--
--  The directory + auth plane for database-per-tenant multitenancy. It holds
--  the tenant registry, the global RBAC model, and every user. It holds NO
--  business data — that lives in each tenant's own database (hb_tenant_<code>),
--  physically separate, so a query in one tenant's database cannot reach
--  another's. The API resolves the tenant from the login, then routes all
--  business queries to that tenant's database.
-- ============================================================================

SET NAMES utf8mb4;

-- Each business (customer org) is one tenant = one database.
CREATE TABLE tenant (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code        VARCHAR(30)  NOT NULL,          -- short slug, e.g. HBML
  name        VARCHAR(200) NOT NULL,
  db_name     VARCHAR(80)  NOT NULL,          -- the physical database, e.g. hb_tenant_hbml
  status      ENUM('PROVISIONING','ACTIVE','SUSPENDED','CLOSED') NOT NULL DEFAULT 'ACTIVE',
  created_at  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_tenant_code (code),
  UNIQUE KEY uq_tenant_db (db_name)
) ENGINE=InnoDB;

-- Users are global to the control plane but each belongs to exactly one tenant.
CREATE TABLE app_user (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id       BIGINT UNSIGNED NOT NULL,
  username        VARCHAR(120) NOT NULL,
  email           VARCHAR(200) NOT NULL,
  full_name       VARCHAR(200) NOT NULL,
  password_hash   VARCHAR(255) NOT NULL,
  is_active       TINYINT(1)   NOT NULL DEFAULT 1,
  is_external     TINYINT(1)   NOT NULL DEFAULT 0,
  failed_logins   INT UNSIGNED NOT NULL DEFAULT 0,
  locked_until    DATETIME(3)  NULL,
  last_login_at   DATETIME(3)  NULL,
  created_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  -- username is unique WITHIN a tenant; two businesses can both have "admin"
  UNIQUE KEY uq_user_username (tenant_id, username),
  KEY ix_user_tenant (tenant_id),
  CONSTRAINT fk_user_tenant FOREIGN KEY (tenant_id) REFERENCES tenant (id)
) ENGINE=InnoDB;

CREATE TABLE role (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code        VARCHAR(40)  NOT NULL,
  name        VARCHAR(120) NOT NULL,
  description VARCHAR(400) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_role_code (code)
) ENGINE=InnoDB;

CREATE TABLE permission (
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code     VARCHAR(80)  NOT NULL,
  resource VARCHAR(40)  NOT NULL,
  action   VARCHAR(30)  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_permission_code (code),
  KEY ix_permission_resource (resource)
) ENGINE=InnoDB;

CREATE TABLE role_permission (
  role_id       BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_perm FOREIGN KEY (permission_id) REFERENCES permission (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE user_role (
  user_id    BIGINT UNSIGNED NOT NULL,
  role_id    BIGINT UNSIGNED NOT NULL,
  granted_by BIGINT UNSIGNED NULL,
  granted_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE,
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES role (id)
) ENGINE=InnoDB;

-- Which legal entities WITHIN the user's tenant they may act on. entity_id is a
-- legal_entity id in the tenant database, so there is no cross-database FK.
CREATE TABLE user_entity_access (
  user_id   BIGINT UNSIGNED NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (user_id, entity_id),
  CONSTRAINT fk_uea_user FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE sod_conflict (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code        VARCHAR(20) NOT NULL,
  role_a_id   BIGINT UNSIGNED NOT NULL,
  role_b_id   BIGINT UNSIGNED NOT NULL,
  risk        VARCHAR(300) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sod (role_a_id, role_b_id),
  CONSTRAINT fk_sod_a FOREIGN KEY (role_a_id) REFERENCES role (id),
  CONSTRAINT fk_sod_b FOREIGN KEY (role_b_id) REFERENCES role (id)
) ENGINE=InnoDB;

CREATE TABLE refresh_token (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     BIGINT UNSIGNED NOT NULL,
  token_hash  CHAR(64)    NOT NULL,
  expires_at  DATETIME(3) NOT NULL,
  revoked_at  DATETIME(3) NULL,
  created_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_rt_hash (token_hash),
  KEY ix_rt_user (user_id, expires_at),
  CONSTRAINT fk_rt_user FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE
) ENGINE=InnoDB;
