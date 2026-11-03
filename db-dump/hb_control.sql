-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: hb_control
-- ------------------------------------------------------
-- Server version	8.0.46-0ubuntu0.24.04.3

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `hb_control`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hb_control` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `hb_control`;

--
-- Table structure for table `app_user`
--

DROP TABLE IF EXISTS `app_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint unsigned NOT NULL,
  `username` varchar(120) NOT NULL,
  `email` varchar(200) NOT NULL,
  `full_name` varchar(200) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_external` tinyint(1) NOT NULL DEFAULT '0',
  `failed_logins` int unsigned NOT NULL DEFAULT '0',
  `locked_until` datetime(3) DEFAULT NULL,
  `last_login_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_username` (`tenant_id`,`username`),
  KEY `ix_user_tenant` (`tenant_id`),
  CONSTRAINT `fk_user_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_user`
--

LOCK TABLES `app_user` WRITE;
/*!40000 ALTER TABLE `app_user` DISABLE KEYS */;
INSERT INTO `app_user` VALUES (1,1,'controller','controller@hbml.example','S. Menon','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,'2026-08-05 13:03:28.205','2026-08-05 13:02:11.135','2026-08-05 13:03:28.205'),(2,1,'imports','imports@hbml.example','A. Kulkarni','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.151','2026-08-05 13:02:11.151'),(3,1,'exports','exports@hbml.example','R. Iyer','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.156','2026-08-05 13:02:11.156'),(4,1,'compliance','compliance@hbml.example','D. Rao','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.159','2026-08-05 13:02:11.159'),(5,1,'costing','costing@hbml.example','M. Shah','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.162','2026-08-05 13:02:11.162'),(6,1,'accounts','accounts@hbml.example','P. Nair','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.165','2026-08-05 13:02:11.165'),(7,1,'treasury','treasury@hbml.example','K. Bose','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.169','2026-08-05 13:02:11.169'),(8,1,'tradefinance','tradefinance@hbml.example','V. Menon','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.171','2026-08-05 13:02:11.171'),(9,1,'tax','tax@hbml.example','G. Pillai','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.175','2026-08-05 13:02:11.175'),(10,1,'audit','audit@hbml.example','N. Fernandes','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,'2026-08-05 13:03:26.956','2026-08-05 13:02:11.179','2026-08-05 13:03:26.956'),(11,1,'broker','broker@hbml.example','Bluewave Clearing','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,1,0,NULL,NULL,'2026-08-05 13:02:11.182','2026-08-05 13:02:11.182'),(12,1,'admin','admin@hbml.example','System Administrator','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,'2026-08-05 13:03:27.929','2026-08-05 13:02:11.184','2026-08-05 13:03:27.929'),(13,2,'controller','controller@acme.example','S. Menon','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,'2026-08-05 13:03:26.762','2026-08-05 13:02:11.189','2026-08-05 13:03:26.762'),(14,2,'imports','imports@acme.example','A. Kulkarni','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.191','2026-08-05 13:02:11.191'),(15,2,'exports','exports@acme.example','R. Iyer','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.194','2026-08-05 13:02:11.194'),(16,2,'compliance','compliance@acme.example','D. Rao','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.197','2026-08-05 13:02:11.197'),(17,2,'costing','costing@acme.example','M. Shah','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.201','2026-08-05 13:02:11.201'),(18,2,'accounts','accounts@acme.example','P. Nair','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.204','2026-08-05 13:02:11.204'),(19,2,'treasury','treasury@acme.example','K. Bose','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.207','2026-08-05 13:02:11.207'),(20,2,'tradefinance','tradefinance@acme.example','V. Menon','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.211','2026-08-05 13:02:11.211'),(21,2,'tax','tax@acme.example','G. Pillai','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.214','2026-08-05 13:02:11.214'),(22,2,'audit','audit@acme.example','N. Fernandes','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.217','2026-08-05 13:02:11.217'),(23,2,'broker','broker@acme.example','Bluewave Clearing','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,1,0,NULL,NULL,'2026-08-05 13:02:11.220','2026-08-05 13:02:11.220'),(24,2,'admin','admin@acme.example','System Administrator','$2b$10$PoDm3wTA8qDXlmptruX29u8BJQXgeUIh0uXczohAQ7aLqu3wN6XGu',1,0,0,NULL,NULL,'2026-08-05 13:02:11.224','2026-08-05 13:02:11.224'),(25,1,'sod5007939','sod5007939@example.com','SoD Probe','$2b$10$ppVjzSSpjKfVXCpV4RDb.OeOgJ8ayN3U82e71NzFeOzUAK9sgoisS',0,0,0,NULL,NULL,'2026-08-05 13:03:28.056','2026-08-05 13:03:28.089');
/*!40000 ALTER TABLE `app_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `permission`
--

DROP TABLE IF EXISTS `permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permission` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(80) NOT NULL,
  `resource` varchar(40) NOT NULL,
  `action` varchar(30) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_permission_code` (`code`),
  KEY `ix_permission_resource` (`resource`)
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permission`
--

LOCK TABLES `permission` WRITE;
/*!40000 ALTER TABLE `permission` DISABLE KEYS */;
INSERT INTO `permission` VALUES (1,'account:read','account','read'),(2,'account:write','account','write'),(3,'audit:read','audit','read'),(4,'bonded:read','bonded','read'),(5,'close:override','close','override'),(6,'closetask:read','closetask','read'),(7,'closetask:update','closetask','update'),(8,'cockpit:read','cockpit','read'),(9,'cockpit:write','cockpit','write'),(10,'costsheet:allocate','costsheet','allocate'),(11,'costsheet:close','costsheet','close'),(12,'costsheet:create','costsheet','create'),(13,'costsheet:read','costsheet','read'),(14,'costsheet:update','costsheet','update'),(15,'costsheet:write','costsheet','write'),(16,'declaration:create','declaration','create'),(17,'declaration:read','declaration','read'),(18,'declaration:update','declaration','update'),(19,'declaration:validate','declaration','validate'),(20,'declaration:write','declaration','write'),(21,'entitlement:create','entitlement','create'),(22,'entitlement:read','entitlement','read'),(23,'entitlement:write','entitlement','write'),(24,'exception:read','exception','read'),(25,'exception:resolve','exception','resolve'),(26,'exception:write','exception','write'),(27,'fx:revalue','fx','revalue'),(28,'instrument:create','instrument','create'),(29,'instrument:present','instrument','present'),(30,'instrument:read','instrument','read'),(31,'instrument:update','instrument','update'),(32,'instrument:write','instrument','write'),(33,'licence:create','licence','create'),(34,'licence:read','licence','read'),(35,'licence:update','licence','update'),(36,'licence:write','licence','write'),(37,'order:create','order','create'),(38,'order:read','order','read'),(39,'order:update','order','update'),(40,'order:write','order','write'),(41,'override:review','override','review'),(42,'party:read','party','read'),(43,'party:write','party','write'),(44,'reconciliation:read','reconciliation','read'),(45,'reconciliation:update','reconciliation','update'),(46,'reconciliation:write','reconciliation','write'),(47,'role:admin','role','admin'),(48,'screening:disposition','screening','disposition'),(49,'screening:read','screening','read'),(50,'shipment:create','shipment','create'),(51,'shipment:read','shipment','read'),(52,'shipment:update','shipment','update'),(53,'shipment:write','shipment','write'),(54,'tax:read','tax','read'),(55,'trialbalance:read','trialbalance','read'),(56,'user:admin','user','admin'),(57,'voucher:approve','voucher','approve'),(58,'voucher:create','voucher','create'),(59,'voucher:post','voucher','post'),(60,'voucher:read','voucher','read'),(61,'voucher:update','voucher','update'),(62,'voucher:write','voucher','write');
/*!40000 ALTER TABLE `permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refresh_token`
--

DROP TABLE IF EXISTS `refresh_token`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_token` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expires_at` datetime(3) NOT NULL,
  `revoked_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rt_hash` (`token_hash`),
  KEY `ix_rt_user` (`user_id`,`expires_at`),
  CONSTRAINT `fk_rt_user` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refresh_token`
--

LOCK TABLES `refresh_token` WRITE;
/*!40000 ALTER TABLE `refresh_token` DISABLE KEYS */;
INSERT INTO `refresh_token` VALUES (1,1,'f07f693debbc03a5d436a3393865822954ff725ba112f9109adcd1298c32d8b8','2026-08-12 13:02:42.852',NULL,'2026-08-05 13:02:42.852'),(2,1,'cd6f15c6e16209c29aa863d386b926ff4c321efed1899c3a33b7a484a5b03107','2026-08-12 13:03:02.524',NULL,'2026-08-05 13:03:02.524'),(3,1,'599833c2174c70b7ccd23b55fd9c302f80060abaf8f9f364502c53868b5c9fb0','2026-08-12 13:03:26.370',NULL,'2026-08-05 13:03:26.370'),(4,1,'1811c47b4894bebed757e3f86868ebcbd5cb419119af95c517dbb7c46c10793c','2026-08-12 13:03:26.638',NULL,'2026-08-05 13:03:26.639'),(5,13,'6460dfab789756c1fd66ede05f33505216ede5a405db1a872ddd27381b9f5bf8','2026-08-12 13:03:26.769',NULL,'2026-08-05 13:03:26.770'),(6,10,'52604420dd89455dac5a3d30a28c977586506534dd76e940edf15a28d35250f2','2026-08-12 13:03:26.962',NULL,'2026-08-05 13:03:26.963'),(7,1,'6bba692bdfc4ecb95338c35aecc414a10bae02a1e1f4e5a7da39e54984ad3dcd','2026-08-12 13:03:27.100',NULL,'2026-08-05 13:03:27.100'),(8,1,'e4f962333ca21f1a34b6e441ef7e6307b0174218c430b376e554bb3081f180a2','2026-08-12 13:03:27.267',NULL,'2026-08-05 13:03:27.268'),(9,1,'1fdced5984f3480d2d6f7aa9971143d4fdf8ff034c787c6585d08e4ea9608df9','2026-08-12 13:03:27.482',NULL,'2026-08-05 13:03:27.483'),(10,1,'e52ab9ed5887225d8f9f5714a79caf2f426027d36510e1a881db61ffcf45e71b','2026-08-12 13:03:27.634',NULL,'2026-08-05 13:03:27.635'),(11,1,'9766524f2eae5bb572083767d33824f93fc452b327defda2d8d9bee3979a55ae','2026-08-12 13:03:27.783',NULL,'2026-08-05 13:03:27.783'),(12,12,'de017df32a860e40e95bbe8f0306e2dac2690cf618e37530c673d5d3eca57170','2026-08-12 13:03:27.936',NULL,'2026-08-05 13:03:27.936'),(13,1,'8249d22834325ef88112849d0de23eeca95bf17aa59c93b6da6424cb8f27a378','2026-08-12 13:03:28.212',NULL,'2026-08-05 13:03:28.212');
/*!40000 ALTER TABLE `refresh_token` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(40) NOT NULL,
  `name` varchar(120) NOT NULL,
  `description` varchar(400) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_role_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role`
--

LOCK TABLES `role` WRITE;
/*!40000 ALTER TABLE `role` DISABLE KEYS */;
INSERT INTO `role` VALUES (1,'import_executive','Import executive','Raises and progresses import orders, shipments and declarations.'),(2,'export_executive','Export executive','Raises and progresses export orders, shipments, shipping bills and entitlement claims.'),(3,'compliance_officer','Compliance officer','Owns classification, preference eligibility, screening disposition, licences and the exception queue.'),(4,'customs_broker','Customs broker (external)','External partner: prepares declarations for the entities granted, read-only on finance.'),(5,'finance_controller','Finance controller','Approves vouchers and manual journals, owns the close, may override a period lock with a reason.'),(6,'accounts_executive','Accounts executive','Captures and parks vouchers, runs subledger and bank reconciliations.'),(7,'cost_accountant','Cost accountant','Builds and closes landed-cost sheets, raises landed-cost and goods-receipt vouchers.'),(8,'treasury_officer','Treasury officer','Runs FX revaluation and manages cash and margin positions.'),(9,'trade_finance_officer','Trade finance officer','Manages letters of credit, guarantees, presentations and export realisation.'),(10,'tax_executive','Tax executive','Reconciles import tax credit and statutory statements.'),(11,'internal_auditor','Internal auditor','Read-only across the module plus manual-journal and override review.'),(12,'system_admin','System administrator','Manages users, roles, entity access and tenants, plus master data.');
/*!40000 ALTER TABLE `role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role_permission`
--

DROP TABLE IF EXISTS `role_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permission` (
  `role_id` bigint unsigned NOT NULL,
  `permission_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`permission_id`),
  KEY `fk_rp_perm` (`permission_id`),
  CONSTRAINT `fk_rp_perm` FOREIGN KEY (`permission_id`) REFERENCES `permission` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role_permission`
--

LOCK TABLES `role_permission` WRITE;
/*!40000 ALTER TABLE `role_permission` DISABLE KEYS */;
INSERT INTO `role_permission` VALUES (5,1),(6,1),(7,1),(8,1),(10,1),(11,1),(12,1),(5,2),(12,2),(5,3),(11,3),(12,3),(3,4),(11,4),(5,5),(5,6),(6,6),(7,6),(8,6),(10,6),(11,6),(12,6),(5,7),(1,8),(2,8),(3,8),(5,8),(9,8),(11,8),(12,8),(1,9),(2,9),(3,9),(5,9),(7,10),(7,11),(7,12),(1,13),(5,13),(6,13),(7,13),(8,13),(10,13),(11,13),(7,14),(5,15),(7,15),(1,16),(2,16),(4,16),(1,17),(2,17),(3,17),(4,17),(5,17),(6,17),(7,17),(9,17),(10,17),(11,17),(12,17),(1,18),(2,18),(3,18),(4,18),(3,19),(1,20),(2,20),(3,20),(4,20),(5,20),(2,21),(2,22),(3,22),(5,22),(9,22),(11,22),(2,23),(5,23),(1,24),(2,24),(3,24),(5,24),(9,24),(11,24),(12,24),(3,25),(3,26),(5,26),(8,27),(9,28),(9,29),(1,30),(2,30),(3,30),(5,30),(8,30),(9,30),(11,30),(9,31),(5,32),(8,32),(9,32),(3,33),(1,34),(2,34),(3,34),(5,34),(11,34),(3,35),(3,36),(5,36),(1,37),(2,37),(1,38),(2,38),(3,38),(5,38),(9,38),(11,38),(1,39),(2,39),(1,40),(2,40),(5,40),(11,41),(1,42),(2,42),(3,42),(4,42),(5,42),(6,42),(9,42),(11,42),(12,42),(1,43),(2,43),(3,43),(5,43),(6,43),(12,43),(5,44),(6,44),(7,44),(8,44),(9,44),(10,44),(11,44),(5,45),(6,45),(9,45),(10,45),(5,46),(6,46),(9,46),(12,47),(3,48),(3,49),(5,49),(11,49),(1,50),(2,50),(1,51),(2,51),(3,51),(4,51),(5,51),(6,51),(7,51),(9,51),(11,51),(1,52),(2,52),(1,53),(2,53),(5,53),(10,54),(5,55),(6,55),(7,55),(8,55),(10,55),(11,55),(12,55),(12,56),(5,57),(6,58),(7,58),(8,58),(5,59),(5,60),(6,60),(7,60),(8,60),(10,60),(11,60),(12,60),(6,61),(5,62),(6,62),(7,62),(8,62);
/*!40000 ALTER TABLE `role_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schema_migration`
--

DROP TABLE IF EXISTS `schema_migration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_migration` (
  `filename` varchar(200) NOT NULL,
  `checksum` char(64) NOT NULL,
  `applied_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `ms` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schema_migration`
--

LOCK TABLES `schema_migration` WRITE;
/*!40000 ALTER TABLE `schema_migration` DISABLE KEYS */;
INSERT INTO `schema_migration` VALUES ('001_control.sql','6d2dbc16e709b0859aa6fd5f101f8df9b603bb4ec3037db44ada33f699c4e60d','2026-08-05 09:10:58.306',114);
/*!40000 ALTER TABLE `schema_migration` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sod_conflict`
--

DROP TABLE IF EXISTS `sod_conflict`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sod_conflict` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `role_a_id` bigint unsigned NOT NULL,
  `role_b_id` bigint unsigned NOT NULL,
  `risk` varchar(300) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sod` (`role_a_id`,`role_b_id`),
  KEY `fk_sod_b` (`role_b_id`),
  CONSTRAINT `fk_sod_a` FOREIGN KEY (`role_a_id`) REFERENCES `role` (`id`),
  CONSTRAINT `fk_sod_b` FOREIGN KEY (`role_b_id`) REFERENCES `role` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sod_conflict`
--

LOCK TABLES `sod_conflict` WRITE;
/*!40000 ALTER TABLE `sod_conflict` DISABLE KEYS */;
INSERT INTO `sod_conflict` VALUES (1,'SOD-01',6,5,'Voucher preparation and voucher approval by the same person defeats the four-eyes control on postings.'),(2,'SOD-02',7,5,'Preparing and approving landed-cost closures without independent review.'),(3,'SOD-03',3,4,'Internal compliance sign-off and external declaration filing concentrated in one identity.'),(4,'SOD-04',8,5,'Running FX revaluation and approving its posting is a self-review threat.'),(5,'SOD-05',11,5,'The reviewer of manual journals and overrides must not also be their approver.'),(6,'SOD-06',9,6,'Managing instruments and posting the related settlements should be separated.');
/*!40000 ALTER TABLE `sod_conflict` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tenant`
--

DROP TABLE IF EXISTS `tenant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenant` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) NOT NULL,
  `name` varchar(200) NOT NULL,
  `db_name` varchar(80) NOT NULL,
  `status` enum('PROVISIONING','ACTIVE','SUSPENDED','CLOSED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tenant_code` (`code`),
  UNIQUE KEY `uq_tenant_db` (`db_name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tenant`
--

LOCK TABLES `tenant` WRITE;
/*!40000 ALTER TABLE `tenant` DISABLE KEYS */;
INSERT INTO `tenant` VALUES (1,'HBML','HB Manufacturing Ltd','hb_tenant_hbml','ACTIVE','2026-08-05 13:02:11.129'),(2,'ACME','Acme Trading Ltd','hb_tenant_acme','ACTIVE','2026-08-05 13:02:11.188');
/*!40000 ALTER TABLE `tenant` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_entity_access`
--

DROP TABLE IF EXISTS `user_entity_access`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_entity_access` (
  `user_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`user_id`,`entity_id`),
  CONSTRAINT `fk_uea_user` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_entity_access`
--

LOCK TABLES `user_entity_access` WRITE;
/*!40000 ALTER TABLE `user_entity_access` DISABLE KEYS */;
INSERT INTO `user_entity_access` VALUES (1,1),(2,1),(3,1),(4,1),(5,1),(6,1),(7,1),(8,1),(9,1),(10,1),(11,1),(12,1),(13,1),(14,1),(15,1),(16,1),(17,1),(18,1),(19,1),(20,1),(21,1),(22,1),(23,1),(24,1),(25,1);
/*!40000 ALTER TABLE `user_entity_access` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_role`
--

DROP TABLE IF EXISTS `user_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_role` (
  `user_id` bigint unsigned NOT NULL,
  `role_id` bigint unsigned NOT NULL,
  `granted_by` bigint unsigned DEFAULT NULL,
  `granted_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`user_id`,`role_id`),
  KEY `fk_ur_role` (`role_id`),
  CONSTRAINT `fk_ur_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`),
  CONSTRAINT `fk_ur_user` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_role`
--

LOCK TABLES `user_role` WRITE;
/*!40000 ALTER TABLE `user_role` DISABLE KEYS */;
INSERT INTO `user_role` VALUES (1,5,NULL,'2026-08-05 13:02:11.143'),(2,1,NULL,'2026-08-05 13:02:11.153'),(3,2,NULL,'2026-08-05 13:02:11.157'),(4,3,NULL,'2026-08-05 13:02:11.160'),(5,7,NULL,'2026-08-05 13:02:11.164'),(6,6,NULL,'2026-08-05 13:02:11.167'),(7,8,NULL,'2026-08-05 13:02:11.170'),(8,9,NULL,'2026-08-05 13:02:11.172'),(9,10,NULL,'2026-08-05 13:02:11.176'),(10,11,NULL,'2026-08-05 13:02:11.180'),(11,4,NULL,'2026-08-05 13:02:11.183'),(12,12,NULL,'2026-08-05 13:02:11.185'),(13,5,NULL,'2026-08-05 13:02:11.189'),(14,1,NULL,'2026-08-05 13:02:11.192'),(15,2,NULL,'2026-08-05 13:02:11.195'),(16,3,NULL,'2026-08-05 13:02:11.199'),(17,7,NULL,'2026-08-05 13:02:11.202'),(18,6,NULL,'2026-08-05 13:02:11.205'),(19,8,NULL,'2026-08-05 13:02:11.209'),(20,9,NULL,'2026-08-05 13:02:11.212'),(21,10,NULL,'2026-08-05 13:02:11.215'),(22,11,NULL,'2026-08-05 13:02:11.218'),(23,4,NULL,'2026-08-05 13:02:11.221'),(24,12,NULL,'2026-08-05 13:02:11.225'),(25,6,NULL,'2026-08-05 13:03:28.059'),(25,10,NULL,'2026-08-05 13:03:28.078');
/*!40000 ALTER TABLE `user_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'hb_control'
--

--
-- Dumping routines for database 'hb_control'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-08-05 13:09:46
