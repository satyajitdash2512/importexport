-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: hb_tenant_acme
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
-- Current Database: `hb_tenant_acme`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hb_tenant_acme` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `hb_tenant_acme`;

--
-- Table structure for table `account_determination`
--

DROP TABLE IF EXISTS `account_determination`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `account_determination` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `account_key` varchar(40) NOT NULL,
  `qualifier` varchar(60) NOT NULL DEFAULT '*',
  `account_id` bigint unsigned NOT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ad` (`entity_id`,`account_key`,`qualifier`,`valid_from`),
  KEY `fk_ad_account` (`account_id`),
  CONSTRAINT `fk_ad_account` FOREIGN KEY (`account_id`) REFERENCES `gl_account` (`id`),
  CONSTRAINT `fk_ad_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_determination`
--

LOCK TABLES `account_determination` WRITE;
/*!40000 ALTER TABLE `account_determination` DISABLE KEYS */;
INSERT INTO `account_determination` VALUES (1,1,'INVENTORY','*',6,'2020-04-01',NULL),(2,1,'GIT','*',7,'2020-04-01',NULL),(3,1,'AP_FOREIGN','*',9,'2020-04-01',NULL),(4,1,'AP_SERVICE','*',10,'2020-04-01',NULL),(5,1,'AR_EXPORT','*',3,'2020-04-01',NULL),(6,1,'BANK','*',1,'2020-04-01',NULL),(7,1,'BANK_FC','*',2,'2020-04-01',NULL),(8,1,'DUTY_PAYABLE','*',11,'2020-04-01',NULL),(9,1,'IGST_RECOVERABLE','*',8,'2020-04-01',NULL),(10,1,'CLEARING_FREIGHT','*',12,'2020-04-01',NULL),(11,1,'CLEARING_DUTY','*',13,'2020-04-01',NULL),(12,1,'CLEARING_PORT','*',14,'2020-04-01',NULL),(13,1,'CLEARING_GRIR','*',15,'2020-04-01',NULL),(14,1,'LANDED_VARIANCE','*',20,'2020-04-01',NULL),(15,1,'COGS','*',19,'2020-04-01',NULL),(16,1,'REVENUE_EXPORT','*',17,'2020-04-01',NULL),(17,1,'FX_REALISED','*',22,'2020-04-01',NULL),(18,1,'FX_UNREALISED','*',23,'2020-04-01',NULL),(19,1,'BANK_CHARGES','*',24,'2020-04-01',NULL),(20,1,'ENTITLEMENT_REC','*',4,'2020-04-01',NULL),(21,1,'ENTITLEMENT_INC','*',18,'2020-04-01',NULL),(22,1,'SCRIP_LEDGER','*',5,'2020-04-01',NULL),(23,1,'DEMURRAGE','*',21,'2020-04-01',NULL),(24,1,'TDS_PAYABLE','*',16,'2020-04-01',NULL),(25,1,'MEMO_DEFERRED_DUTY','*',25,'2020-04-01',NULL);
/*!40000 ALTER TABLE `account_determination` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `account_period_balance`
--

DROP TABLE IF EXISTS `account_period_balance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `account_period_balance` (
  `entity_id` bigint unsigned NOT NULL,
  `book_id` bigint unsigned NOT NULL,
  `account_id` bigint unsigned NOT NULL,
  `period_key` int unsigned NOT NULL,
  `opening_dr` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `opening_cr` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `period_dr` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `period_cr` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `line_count` bigint unsigned NOT NULL DEFAULT '0',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`entity_id`,`book_id`,`period_key`,`account_id`),
  KEY `ix_apb_account` (`entity_id`,`account_id`,`period_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_period_balance`
--

LOCK TABLES `account_period_balance` WRITE;
/*!40000 ALTER TABLE `account_period_balance` DISABLE KEYS */;
INSERT INTO `account_period_balance` VALUES (1,1,1,202607,48200000.0000,0.0000,121400000.0000,118900000.0000,0,'2026-08-05 13:02:21.130'),(1,1,2,202607,9840000.0000,0.0000,33100000.0000,29800000.0000,0,'2026-08-05 13:02:21.133'),(1,1,3,202607,62400000.0000,0.0000,34280000.0000,18900000.0000,0,'2026-08-05 13:02:21.135'),(1,1,4,202607,1840000.0000,0.0000,462643.0000,412464.0000,0,'2026-08-05 13:02:21.137'),(1,1,5,202607,980000.0000,0.0000,260064.0000,0.0000,0,'2026-08-05 13:02:21.139'),(1,1,6,202607,88200000.0000,0.0000,41200000.0000,32800000.0000,0,'2026-08-05 13:02:21.141'),(1,1,7,202607,12400000.0000,0.0000,22600000.0000,13564518.0000,0,'2026-08-05 13:02:21.143'),(1,1,8,202607,6420000.0000,0.0000,2657871.3400,6100000.0000,0,'2026-08-05 13:02:21.145'),(1,1,9,202607,0.0000,41800000.0000,28400000.0000,37600000.0000,0,'2026-08-05 13:02:21.147'),(1,1,10,202607,0.0000,8900000.0000,6200000.0000,7100000.0000,0,'2026-08-05 13:02:21.149'),(1,1,11,202607,0.0000,1240000.0000,3452336.6200,3452336.6200,0,'2026-08-05 13:02:21.152'),(1,1,12,202607,0.0000,620000.0000,344000.0000,570000.0000,0,'2026-08-05 13:02:21.154'),(1,1,13,202607,0.0000,0.0000,794465.2800,794465.2800,0,'2026-08-05 13:02:21.156'),(1,1,14,202607,0.0000,164000.0000,45000.0000,209000.0000,0,'2026-08-05 13:02:21.158'),(1,1,15,202607,0.0000,2140000.0000,1980000.0000,2410000.0000,0,'2026-08-05 13:02:21.160'),(1,1,16,202607,0.0000,412000.0000,380000.0000,468000.0000,0,'2026-08-05 13:02:21.162'),(1,1,17,202607,0.0000,0.0000,0.0000,34280000.0000,0,'2026-08-05 13:02:21.164'),(1,1,18,202607,0.0000,0.0000,14784.0000,462643.0000,0,'2026-08-05 13:02:21.166'),(1,1,19,202607,0.0000,0.0000,32800000.0000,0.0000,0,'2026-08-05 13:02:21.168'),(1,1,20,202607,0.0000,0.0000,34000.0000,0.0000,0,'2026-08-05 13:02:21.170'),(1,1,21,202607,0.0000,0.0000,36000.0000,0.0000,0,'2026-08-05 13:02:21.173'),(1,1,22,202607,0.0000,0.0000,284000.0000,96000.0000,0,'2026-08-05 13:02:21.175'),(1,1,23,202607,0.0000,0.0000,412000.0000,0.0000,0,'2026-08-05 13:02:21.179'),(1,1,24,202607,0.0000,0.0000,128400.0000,0.0000,0,'2026-08-05 13:02:21.181'),(1,1,25,202607,0.0000,9240000.0000,0.0000,0.0000,0,'2026-08-05 13:02:21.183'),(1,1,26,202607,0.0000,50000000.0000,0.0000,0.0000,0,'2026-08-05 13:02:21.185'),(1,1,27,202607,0.0000,115764000.0000,0.0000,0.0000,0,'2026-08-05 13:02:21.187'),(1,1,28,202607,0.0000,0.0000,0.0000,23346137.3400,0,'2026-08-05 13:02:21.189');
/*!40000 ALTER TABLE `account_period_balance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `accounting_period`
--

DROP TABLE IF EXISTS `accounting_period`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `accounting_period` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `book_id` bigint unsigned NOT NULL,
  `period_key` int unsigned NOT NULL,
  `fiscal_year` varchar(9) NOT NULL,
  `starts_on` date NOT NULL,
  `ends_on` date NOT NULL,
  `status` enum('OPEN','SOFT_CLOSED','HARD_CLOSED') NOT NULL DEFAULT 'OPEN',
  `locked_by` bigint unsigned DEFAULT NULL,
  `locked_at` datetime(3) DEFAULT NULL,
  `lock_override_reason` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_period` (`entity_id`,`book_id`,`period_key`),
  KEY `ix_period_status` (`entity_id`,`status`),
  KEY `fk_period_book` (`book_id`),
  CONSTRAINT `fk_period_book` FOREIGN KEY (`book_id`) REFERENCES `book` (`id`),
  CONSTRAINT `fk_period_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounting_period`
--

LOCK TABLES `accounting_period` WRITE;
/*!40000 ALTER TABLE `accounting_period` DISABLE KEYS */;
INSERT INTO `accounting_period` VALUES (1,1,1,202604,'2026-27','2026-04-01','2026-04-30','HARD_CLOSED',NULL,NULL,NULL),(2,1,1,202605,'2026-27','2026-05-01','2026-05-31','HARD_CLOSED',NULL,NULL,NULL),(3,1,1,202606,'2026-27','2026-06-01','2026-06-30','SOFT_CLOSED',NULL,NULL,NULL),(4,1,1,202607,'2026-27','2026-07-01','2026-07-31','OPEN',NULL,NULL,NULL),(5,1,1,202608,'2026-27','2026-08-01','2026-08-31','OPEN',NULL,NULL,NULL);
/*!40000 ALTER TABLE `accounting_period` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned DEFAULT NULL,
  `occurred_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `user_id` bigint unsigned DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `source_ip` varchar(45) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `object_type` varchar(40) NOT NULL,
  `object_id` bigint unsigned DEFAULT NULL,
  `object_ref` varchar(60) DEFAULT NULL,
  `field_name` varchar(60) DEFAULT NULL,
  `old_value` text,
  `new_value` text,
  `reason` varchar(500) DEFAULT NULL,
  `correlation_id` char(36) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_audit_object` (`object_type`,`object_id`,`occurred_at`),
  KEY `ix_audit_user` (`user_id`,`occurred_at`),
  KEY `ix_audit_time` (`occurred_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_log`
--

LOCK TABLES `audit_log` WRITE;
/*!40000 ALTER TABLE `audit_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bank_charge`
--

DROP TABLE IF EXISTS `bank_charge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bank_charge` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `charge_ref` varchar(40) NOT NULL,
  `charge_date` date NOT NULL,
  `bank` varchar(120) DEFAULT NULL,
  `instrument_no` varchar(40) DEFAULT NULL,
  `charge_type` varchar(60) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'INR',
  `amount` decimal(16,2) NOT NULL DEFAULT '0.00',
  `status` varchar(24) NOT NULL DEFAULT 'POSTED',
  PRIMARY KEY (`id`),
  KEY `ix_bankchg_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bank_charge`
--

LOCK TABLES `bank_charge` WRITE;
/*!40000 ALTER TABLE `bank_charge` DISABLE KEYS */;
INSERT INTO `bank_charge` VALUES (1,1,'BC-2026-0771','2026-07-15','HDFC Bank','LC-IMP-2026-011','COMMISSION','INR',27600.00,'RECOVERED'),(2,1,'BC-2026-0779','2026-07-22','ICICI Bank','LC-EXP-2026-004','NEGOTIATION','INR',18400.00,'POSTED'),(3,1,'BC-2026-0788','2026-07-29','HDFC Bank','BG-2026-002','SWIFT','INR',2200.00,'POSTED');
/*!40000 ALTER TABLE `bank_charge` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bond_register`
--

DROP TABLE IF EXISTS `bond_register`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bond_register` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `site_id` bigint unsigned DEFAULT NULL,
  `bond_no` varchar(40) NOT NULL,
  `bond_type` enum('WAREHOUSE','MOOWR','EOU','SEZ','ADVANCE','EPCG','PROVISIONAL','GENERAL') NOT NULL,
  `licence_id` bigint unsigned DEFAULT NULL,
  `executed_on` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `bond_amount` decimal(20,4) NOT NULL,
  `bg_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `bg_waived` tinyint(1) NOT NULL DEFAULT '0',
  `bg_expiry` date DEFAULT NULL,
  `utilised_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `available_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_deferred` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `interest_accrued` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `status` enum('ACTIVE','EXHAUSTED','CANCELLED','CLOSED') NOT NULL DEFAULT 'ACTIVE',
  `contingent_liability_disclosed` tinyint(1) NOT NULL DEFAULT '0',
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bond` (`entity_id`,`bond_no`),
  KEY `ix_bond_status` (`entity_id`,`status`,`valid_to`),
  KEY `ix_bond_bg` (`entity_id`,`bg_expiry`),
  CONSTRAINT `fk_bond_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bond_register`
--

LOCK TABLES `bond_register` WRITE;
/*!40000 ALTER TABLE `bond_register` DISABLE KEYS */;
/*!40000 ALTER TABLE `bond_register` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bonded_entry`
--

DROP TABLE IF EXISTS `bonded_entry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bonded_entry` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `entry_no` varchar(40) NOT NULL,
  `entry_date` date NOT NULL,
  `warehouse_code` varchar(40) DEFAULT NULL,
  `goods_desc` varchar(240) DEFAULT NULL,
  `bond_type` varchar(24) DEFAULT NULL,
  `duty_deferred` decimal(18,2) NOT NULL DEFAULT '0.00',
  `currency` varchar(3) NOT NULL DEFAULT 'INR',
  `rewarehouse_by` date DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'IN_BOND',
  PRIMARY KEY (`id`),
  KEY `ix_bond_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bonded_entry`
--

LOCK TABLES `bonded_entry` WRITE;
/*!40000 ALTER TABLE `bonded_entry` DISABLE KEYS */;
INSERT INTO `bonded_entry` VALUES (1,1,'BND-2026-0021','2026-07-05','MOOWR-PUNE-01','CNC turning centre (capital good)','MOOWR',3452336.00,'INR','2027-07-05','IN_BOND'),(2,1,'BND-2026-0024','2026-07-19','PVT-BOND-02','Servo controller cards','PRIVATE',286140.00,'INR','2027-01-19','PART_CLEARED');
/*!40000 ALTER TABLE `bonded_entry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bonded_stock_ledger`
--

DROP TABLE IF EXISTS `bonded_stock_ledger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bonded_stock_ledger` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `site_id` bigint unsigned DEFAULT NULL,
  `bond_id` bigint unsigned NOT NULL,
  `item_id` bigint unsigned NOT NULL,
  `lot_no` varchar(40) NOT NULL,
  `in_declaration_id` bigint unsigned NOT NULL,
  `out_declaration_id` bigint unsigned DEFAULT NULL,
  `movement` enum('IN','OUT','TRANSFER','SHORTAGE','DESTRUCTION','REEXPORT') NOT NULL,
  `movement_date` date NOT NULL,
  `qty` decimal(20,6) NOT NULL,
  `uom` varchar(10) NOT NULL,
  `value` decimal(20,4) NOT NULL,
  `duty_deferred` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `warehoused_on` date DEFAULT NULL,
  `free_period_to` date DEFAULT NULL,
  `interest_from` date DEFAULT NULL,
  `interest_accrued` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `balance_qty` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `voucher_id` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `ix_bsl_bond` (`entity_id`,`bond_id`,`movement_date`),
  KEY `ix_bsl_lot` (`entity_id`,`item_id`,`lot_no`,`movement_date`),
  KEY `ix_bsl_ageing` (`entity_id`,`bond_id`,`free_period_to`),
  KEY `ix_bsl_in` (`in_declaration_id`),
  KEY `fk_bsl_bond` (`bond_id`),
  KEY `fk_bsl_item` (`item_id`),
  CONSTRAINT `fk_bsl_bond` FOREIGN KEY (`bond_id`) REFERENCES `bond_register` (`id`),
  CONSTRAINT `fk_bsl_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bonded_stock_ledger`
--

LOCK TABLES `bonded_stock_ledger` WRITE;
/*!40000 ALTER TABLE `bonded_stock_ledger` DISABLE KEYS */;
/*!40000 ALTER TABLE `bonded_stock_ledger` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `book`
--

DROP TABLE IF EXISTS `book`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `book` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(80) NOT NULL,
  `basis` enum('PRIMARY','TAX','GROUP','MEMORANDUM') NOT NULL,
  `gaap` enum('IND_AS','AS','IFRS','TAX','NA') NOT NULL DEFAULT 'IND_AS',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_book` (`entity_id`,`code`),
  CONSTRAINT `fk_book_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book`
--

LOCK TABLES `book` WRITE;
/*!40000 ALTER TABLE `book` DISABLE KEYS */;
INSERT INTO `book` VALUES (1,1,'PRIMARY','Primary book (Ind AS)','PRIMARY','IND_AS',1),(2,1,'TAX','Tax book','TAX','TAX',1),(3,1,'GROUP','Group reporting (IFRS)','GROUP','IFRS',1),(4,1,'MEMO','Memorandum','MEMORANDUM','NA',1);
/*!40000 ALTER TABLE `book` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `booking`
--

DROP TABLE IF EXISTS `booking`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `booking_no` varchar(40) NOT NULL,
  `booking_date` date NOT NULL,
  `carrier` varchar(120) DEFAULT NULL,
  `transport_mode` varchar(12) NOT NULL DEFAULT 'SEA',
  `origin_port` varchar(60) DEFAULT NULL,
  `dest_port` varchar(60) DEFAULT NULL,
  `container_type` varchar(24) DEFAULT NULL,
  `containers` int NOT NULL DEFAULT '0',
  `status` varchar(24) NOT NULL DEFAULT 'REQUESTED',
  PRIMARY KEY (`id`),
  KEY `ix_booking_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking`
--

LOCK TABLES `booking` WRITE;
/*!40000 ALTER TABLE `booking` DISABLE KEYS */;
INSERT INTO `booking` VALUES (1,1,'BKG-2026-1201','2026-07-05','Maersk Line','SEA','Busan','Nhava Sheva','40HC',2,'CONFIRMED'),(2,1,'BKG-2026-1215','2026-07-19','Hapag-Lloyd','SEA','Ningbo','Nhava Sheva','20GP',1,'REQUESTED'),(3,1,'BKG-2026-1230','2026-07-28','Emirates SkyCargo','AIR','Frankfurt','Mumbai','ULD',0,'SHIPPED');
/*!40000 ALTER TABLE `booking` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `charge_type`
--

DROP TABLE IF EXISTS `charge_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `charge_type` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(160) NOT NULL,
  `category` enum('GOODS','FREIGHT','INSURANCE','DUTY','PORT','BROKERAGE','INLAND','BANK','AGENCY','INSPECTION','PENALTY','OTHER') NOT NULL,
  `treatment` enum('CAPITALISE','EXPENSE','RECOVERABLE','CONDITIONAL') NOT NULL,
  `treatment_rule` varchar(400) DEFAULT NULL,
  `allocation_basis` enum('VALUE','GROSS_WEIGHT','VOLUME','QUANTITY','CHARGEABLE_WEIGHT','CONTAINER','DIRECT','EQUAL') NOT NULL DEFAULT 'VALUE',
  `default_bearer` enum('ENTITY','COUNTERPARTY','PER_TERMS') NOT NULL DEFAULT 'ENTITY',
  `tax_rate_pct` decimal(6,2) DEFAULT NULL,
  `credit_eligible` tinyint(1) NOT NULL DEFAULT '1',
  `tolerance_pct` decimal(6,2) NOT NULL DEFAULT '5.00',
  `accrual_account_id` bigint unsigned DEFAULT NULL,
  `expense_account_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_charge` (`entity_id`,`code`),
  CONSTRAINT `fk_charge_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `charge_type`
--

LOCK TABLES `charge_type` WRITE;
/*!40000 ALTER TABLE `charge_type` DISABLE KEYS */;
INSERT INTO `charge_type` VALUES (1,1,'FRT-OCN','Ocean freight','FREIGHT','CAPITALISE',NULL,'GROSS_WEIGHT','ENTITY',NULL,0,5.00,NULL,NULL),(2,1,'FRT-INL','Inland freight to site','INLAND','CAPITALISE',NULL,'GROSS_WEIGHT','ENTITY',NULL,0,5.00,NULL,NULL),(3,1,'THC','Terminal handling and port charges','PORT','CAPITALISE',NULL,'CONTAINER','ENTITY',NULL,0,5.00,NULL,NULL),(4,1,'DUTY','Customs duty and levies','DUTY','CAPITALISE',NULL,'DIRECT','ENTITY',NULL,0,5.00,NULL,NULL),(5,1,'IGST-IMP','Integrated tax on import','DUTY','RECOVERABLE',NULL,'DIRECT','ENTITY',NULL,1,5.00,NULL,NULL),(6,1,'BRK','Customs brokerage fee','BROKERAGE','CAPITALISE',NULL,'EQUAL','ENTITY',NULL,0,5.00,NULL,NULL),(7,1,'INS','Marine insurance premium','INSURANCE','CAPITALISE',NULL,'VALUE','ENTITY',NULL,0,5.00,NULL,NULL),(8,1,'DET','Demurrage and detention','PENALTY','EXPENSE',NULL,'DIRECT','ENTITY',NULL,0,5.00,NULL,NULL);
/*!40000 ALTER TABLE `charge_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `checklist`
--

DROP TABLE IF EXISTS `checklist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `checklist` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(40) NOT NULL,
  `name` varchar(160) NOT NULL,
  `applies_to` varchar(60) DEFAULT NULL,
  `direction` varchar(12) DEFAULT NULL,
  `item_count` int NOT NULL DEFAULT '0',
  `mandatory_count` int NOT NULL DEFAULT '0',
  `status` varchar(24) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`id`),
  KEY `ix_chk_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `checklist`
--

LOCK TABLES `checklist` WRITE;
/*!40000 ALTER TABLE `checklist` DISABLE KEYS */;
INSERT INTO `checklist` VALUES (1,1,'CHK-IMP-STD','Standard import clearance set','Import declaration','IMPORT',9,6,'ACTIVE'),(2,1,'CHK-EXP-LC','Export under LC document set','Export shipment','EXPORT',11,8,'ACTIVE'),(3,1,'CHK-EPCG','EPCG capital goods checklist','Licence','IMPORT',7,5,'DRAFT');
/*!40000 ALTER TABLE `checklist` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `close_task`
--

DROP TABLE IF EXISTS `close_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `close_task` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `period_key` int unsigned NOT NULL,
  `day_offset` varchar(6) NOT NULL,
  `area` varchar(60) NOT NULL,
  `step` varchar(300) NOT NULL,
  `owner_role` varchar(60) NOT NULL,
  `is_mandatory` tinyint(1) NOT NULL DEFAULT '1',
  `status` enum('NOT_STARTED','IN_PROGRESS','BLOCKED','COMPLETE') NOT NULL DEFAULT 'NOT_STARTED',
  `derived_check` varchar(60) DEFAULT NULL,
  `blocking_count` int unsigned NOT NULL DEFAULT '0',
  `blocking_detail` varchar(600) DEFAULT NULL,
  `evidence_ref` varchar(200) DEFAULT NULL,
  `signed_off_by` bigint unsigned DEFAULT NULL,
  `signed_off_at` datetime(3) DEFAULT NULL,
  `seq_no` smallint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_close_task` (`entity_id`,`period_key`,`seq_no`),
  KEY `ix_close_status` (`entity_id`,`period_key`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `close_task`
--

LOCK TABLES `close_task` WRITE;
/*!40000 ALTER TABLE `close_task` DISABLE KEYS */;
INSERT INTO `close_task` VALUES (1,1,202607,'D-3','Pre-close','Cut-off communicated to all functions','Finance controller',1,'COMPLETE',NULL,0,NULL,NULL,NULL,NULL,1),(2,1,202607,'D-3','Pre-close','Parked and unapproved documents cleared','Accounts executive',1,'BLOCKED',NULL,2,'JVM/2026-27/00027 pending approval; LCV/2026-27/00033 parked',NULL,NULL,NULL,2),(3,1,202607,'D-3','Pre-close','Interface backlogs cleared','IT operations',1,'COMPLETE',NULL,0,NULL,NULL,NULL,NULL,3),(4,1,202607,'D+1','Subledger cut-off','Receipts, invoices and payments posted to cut-off','Accounts executive',1,'COMPLETE',NULL,0,NULL,NULL,NULL,NULL,4),(5,1,202607,'D+1','Subledger cut-off','Goods in transit determined and agreed to shipment register','Cost accountant',1,'COMPLETE',NULL,0,NULL,'GIT statement 31-Jul-2026',NULL,NULL,5),(6,1,202607,'D+1','Subledger cut-off','Cost accruals raised for received-not-invoiced services','Cost accountant',1,'COMPLETE',NULL,0,NULL,NULL,NULL,NULL,6),(7,1,202607,'D+2','Reconciliation','Bank reconciliation — all accounts','Accounts executive',1,'BLOCKED',NULL,3,'3 unmatched items on EEFC account, ₹1,84,000 value at risk',NULL,NULL,NULL,7),(8,1,202607,'D+2','Reconciliation','AP and AR subledger to control account','Accounts executive',1,'COMPLETE',NULL,0,NULL,NULL,NULL,NULL,8),(9,1,202607,'D+2','Reconciliation','Inventory and bonded stock reconciliation','Compliance officer',1,'COMPLETE',NULL,0,NULL,'Bonded reconciliation 03-Aug-2026',NULL,NULL,9),(10,1,202607,'D+2','Reconciliation','Import tax credit against statutory statement','Tax executive',1,'IN_PROGRESS',NULL,4,'4 declarations present in books but credit not reflected; ₹6,42,000',NULL,NULL,NULL,10),(11,1,202607,'D+2','Reconciliation','Exchange control entries reconciled','Trade finance officer',1,'BLOCKED',NULL,9,'9 export entries unreconciled beyond 8 months',NULL,NULL,NULL,11),(12,1,202607,'D+3','Valuation','Landed cost closure for shipments due','Cost accountant',1,'BLOCKED',NULL,1,'CS-003 open 58 days beyond the 45-day policy age',NULL,NULL,NULL,12),(13,1,202607,'D+3','Valuation','Inventory valuation and net realisable value test','Cost accountant',1,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,13),(14,1,202607,'D+3','Valuation','Foreign exchange revaluation of monetary items','Treasury officer',1,'COMPLETE',NULL,0,NULL,'FXR/2026-27/00004',NULL,NULL,14),(15,1,202607,'D+3','Valuation','Hedge measurement and designation review','Treasury officer',0,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,15),(16,1,202607,'D+3','Valuation','Provisions remeasured — duty demands and obligations','Finance controller',1,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,16),(17,1,202607,'D+4','Review','Trial balance review and variance analysis','Finance controller',1,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,17),(18,1,202607,'D+4','Review','Manual journal review','Internal audit',1,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,18),(19,1,202607,'D+4','Review','Override register review','Internal audit',1,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,19),(20,1,202607,'D+5','Report','Financial statements and schedules produced','Finance controller',1,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,20),(21,1,202607,'D+5','Report','Contingent exposure statement','Finance controller',1,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,21),(22,1,202607,'D+6','Lock','Soft close to hard close and sign-off','Finance controller',1,'NOT_STARTED',NULL,0,NULL,NULL,NULL,NULL,22);
/*!40000 ALTER TABLE `close_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `collection_bill`
--

DROP TABLE IF EXISTS `collection_bill`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `collection_bill` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `bill_no` varchar(40) NOT NULL,
  `bill_date` date NOT NULL,
  `drawee` varchar(160) DEFAULT NULL,
  `bank` varchar(120) DEFAULT NULL,
  `collection_type` varchar(24) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `tenor_days` int NOT NULL DEFAULT '0',
  `maturity_on` date DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'LODGED',
  PRIMARY KEY (`id`),
  KEY `ix_coll_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `collection_bill`
--

LOCK TABLES `collection_bill` WRITE;
/*!40000 ALTER TABLE `collection_bill` DISABLE KEYS */;
INSERT INTO `collection_bill` VALUES (1,1,'COL-2026-0132','2026-07-15','Nordic Components AB','ICICI Bank','DA','EUR',61200.00,60,'2026-09-13','ACCEPTED'),(2,1,'COL-2026-0140','2026-07-28','Gulf Machinery LLC','HDFC Bank','DP','USD',104000.00,0,NULL,'PAID');
/*!40000 ALTER TABLE `collection_bill` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `compliance_pack`
--

DROP TABLE IF EXISTS `compliance_pack`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `compliance_pack` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(40) NOT NULL,
  `name` varchar(160) NOT NULL,
  `jurisdiction` varchar(40) DEFAULT NULL,
  `version` varchar(24) DEFAULT NULL,
  `rule_count` int NOT NULL DEFAULT '0',
  `effective_from` date DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`id`),
  KEY `ix_pack_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `compliance_pack`
--

LOCK TABLES `compliance_pack` WRITE;
/*!40000 ALTER TABLE `compliance_pack` DISABLE KEYS */;
INSERT INTO `compliance_pack` VALUES (1,1,'PACK-IN-CUSTOMS','India customs tariff & rules','IN','2026.2',1840,'2026-07-01','ACTIVE'),(2,1,'PACK-IN-FTP','Foreign Trade Policy content','IN','2026.1',420,'2026-04-01','ACTIVE'),(3,1,'PACK-SANCTIONS','Consolidated restricted-party lists','GLOBAL','2026-08-03',96000,'2026-08-03','ACTIVE');
/*!40000 ALTER TABLE `compliance_pack` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `container`
--

DROP TABLE IF EXISTS `container`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `container` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shipment_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `container_no` varchar(20) NOT NULL,
  `container_type` varchar(20) NOT NULL,
  `seal_no` varchar(30) DEFAULT NULL,
  `tare_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `gross_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `free_from` date DEFAULT NULL,
  `free_days` smallint unsigned NOT NULL DEFAULT '0',
  `days_used` smallint unsigned NOT NULL DEFAULT '0',
  `projected_charge` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `returned_on` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_container` (`shipment_id`,`container_no`),
  KEY `ix_cnt_no` (`entity_id`,`container_no`),
  KEY `ix_cnt_free` (`entity_id`,`free_from`,`free_days`),
  CONSTRAINT `fk_cnt_shp` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `container`
--

LOCK TABLES `container` WRITE;
/*!40000 ALTER TABLE `container` DISABLE KEYS */;
INSERT INTO `container` VALUES (1,1,1,'OSLU4471021','40HC','SL884120',3900.000000,24800.000000,'2026-07-09',7,5,34000.0000,NULL),(2,1,1,'OSLU4471044','40HC','SL884121',3900.000000,23600.000000,'2026-07-09',7,5,34000.0000,NULL),(3,2,1,'BCLU7702118','40GP','IN9920114',3700.000000,26400.000000,'2026-07-24',10,4,0.0000,NULL),(4,5,1,'OSLU4412008','40HC','SL881002',3900.000000,21400.000000,'2026-06-02',7,9,18000.0000,NULL);
/*!40000 ALTER TABLE `container` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `content_pack`
--

DROP TABLE IF EXISTS `content_pack`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `content_pack` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `component` varchar(60) NOT NULL,
  `jurisdiction` char(2) NOT NULL,
  `version` varchar(40) NOT NULL,
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `status` enum('STAGED','ACTIVE','SUPERSEDED') NOT NULL DEFAULT 'STAGED',
  `record_count` int unsigned NOT NULL DEFAULT '0',
  `ingested_at` datetime(3) DEFAULT NULL,
  `prepared_by` bigint unsigned DEFAULT NULL,
  `approved_by` bigint unsigned DEFAULT NULL,
  `approved_at` datetime(3) DEFAULT NULL,
  `test_result` enum('PASSED','FAILED','NOT_RUN') NOT NULL DEFAULT 'NOT_RUN',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pack` (`component`,`jurisdiction`,`version`),
  KEY `ix_pack_active` (`jurisdiction`,`component`,`status`,`effective_from`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `content_pack`
--

LOCK TABLES `content_pack` WRITE;
/*!40000 ALTER TABLE `content_pack` DISABLE KEYS */;
/*!40000 ALTER TABLE `content_pack` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cost_allocation`
--

DROP TABLE IF EXISTS `cost_allocation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cost_allocation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cost_sheet_id` bigint unsigned NOT NULL,
  `cost_line_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `target_type` enum('DECLARATION_LINE','SHIPMENT_LINE','ITEM','CONTAINER') NOT NULL,
  `target_id` bigint unsigned NOT NULL,
  `basis` enum('VALUE','GROSS_WEIGHT','VOLUME','QUANTITY','CHARGEABLE_WEIGHT','CONTAINER','DIRECT','EQUAL') NOT NULL,
  `basis_value` decimal(20,6) NOT NULL,
  `share_pct` decimal(12,8) NOT NULL,
  `amount` decimal(20,4) NOT NULL,
  `is_residual_adjustment` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ca` (`cost_line_id`,`target_type`,`target_id`),
  KEY `ix_ca_sheet` (`cost_sheet_id`),
  KEY `ix_ca_target` (`entity_id`,`target_type`,`target_id`),
  CONSTRAINT `fk_ca_line` FOREIGN KEY (`cost_line_id`) REFERENCES `cost_line` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ca_sheet` FOREIGN KEY (`cost_sheet_id`) REFERENCES `cost_sheet` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cost_allocation`
--

LOCK TABLES `cost_allocation` WRITE;
/*!40000 ALTER TABLE `cost_allocation` DISABLE KEYS */;
/*!40000 ALTER TABLE `cost_allocation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cost_line`
--

DROP TABLE IF EXISTS `cost_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cost_line` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cost_sheet_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `line_no` smallint unsigned NOT NULL,
  `charge_type_id` bigint unsigned NOT NULL,
  `provider_id` bigint unsigned DEFAULT NULL,
  `basis` enum('VALUE','GROSS_WEIGHT','VOLUME','QUANTITY','CHARGEABLE_WEIGHT','CONTAINER','DIRECT','EQUAL') NOT NULL DEFAULT 'VALUE',
  `treatment` enum('CAPITALISE','EXPENSE','RECOVERABLE') NOT NULL,
  `treatment_basis` varchar(300) DEFAULT NULL,
  `currency` char(3) NOT NULL,
  `fx_rate` decimal(18,8) NOT NULL DEFAULT '1.00000000',
  `estimate_fc` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `estimate` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `accrued` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `actual_fc` decimal(20,4) DEFAULT NULL,
  `actual` decimal(20,4) DEFAULT NULL,
  `invoice_ref` varchar(60) DEFAULT NULL,
  `invoice_date` date DEFAULT NULL,
  `invoice_voucher_id` bigint unsigned DEFAULT NULL,
  `accrual_voucher_id` bigint unsigned DEFAULT NULL,
  `tolerance_pct` decimal(9,4) NOT NULL DEFAULT '10.0000',
  `tolerance_breached` tinyint(1) NOT NULL DEFAULT '0',
  `status` enum('ESTIMATED','ACCRUED','INVOICED','MATCHED','DISPUTED','CANCELLED') NOT NULL DEFAULT 'ESTIMATED',
  `gl_account_id` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `status_label` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cl` (`cost_sheet_id`,`line_no`),
  KEY `ix_cl_sheet` (`cost_sheet_id`,`status`),
  KEY `ix_cl_charge` (`entity_id`,`charge_type_id`),
  KEY `ix_cl_provider` (`entity_id`,`provider_id`,`status`),
  KEY `ix_cl_uninvoiced` (`entity_id`,`status`,`accrued`),
  KEY `fk_cl_charge` (`charge_type_id`),
  KEY `fk_cl_provider` (`provider_id`),
  CONSTRAINT `fk_cl_charge` FOREIGN KEY (`charge_type_id`) REFERENCES `charge_type` (`id`),
  CONSTRAINT `fk_cl_provider` FOREIGN KEY (`provider_id`) REFERENCES `trade_party` (`id`),
  CONSTRAINT `fk_cl_sheet` FOREIGN KEY (`cost_sheet_id`) REFERENCES `cost_sheet` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cost_line`
--

LOCK TABLES `cost_line` WRITE;
/*!40000 ALTER TABLE `cost_line` DISABLE KEYS */;
INSERT INTO `cost_line` VALUES (1,1,1,1,1,3,'GROSS_WEIGHT','CAPITALISE',NULL,'INR',1.00000000,310000.0000,310000.0000,310000.0000,344000.0000,344000.0000,'AGL/26/8841',NULL,NULL,NULL,5.0000,1,'DISPUTED',NULL,'2026-08-05 13:02:21.531','2026-08-05 13:02:21.531','Variance beyond tolerance'),(2,1,1,2,3,3,'CONTAINER','CAPITALISE',NULL,'INR',1.00000000,120000.0000,120000.0000,120000.0000,NULL,NULL,NULL,NULL,NULL,NULL,5.0000,0,'ACCRUED',NULL,'2026-08-05 13:02:21.534','2026-08-05 13:02:21.534','Awaiting invoice'),(3,1,1,3,4,NULL,'DIRECT','CAPITALISE',NULL,'INR',1.00000000,794465.2800,794465.2800,794465.2800,815865.2800,815865.2800,'CHLN/4471021',NULL,NULL,NULL,1.0000,1,'DISPUTED',NULL,'2026-08-05 13:02:21.535','2026-08-05 13:02:21.535','Variance — assessed above computed'),(4,1,1,4,5,NULL,'DIRECT','RECOVERABLE',NULL,'INR',1.00000000,2657871.3400,2657871.3400,2657871.3400,2657871.3400,2657871.3400,'CHLN/4471021',NULL,NULL,NULL,1.0000,0,'MATCHED',NULL,'2026-08-05 13:02:21.536','2026-08-05 13:02:21.536','Matched'),(5,1,1,5,6,4,'EQUAL','CAPITALISE',NULL,'INR',1.00000000,45000.0000,45000.0000,45000.0000,45000.0000,45000.0000,'BWC/26/1102',NULL,NULL,NULL,10.0000,0,'MATCHED',NULL,'2026-08-05 13:02:21.537','2026-08-05 13:02:21.537','Matched'),(6,1,1,6,7,9,'VALUE','CAPITALISE',NULL,'INR',1.00000000,38000.0000,38000.0000,38000.0000,36200.0000,36200.0000,'SMI/OP/4471',NULL,NULL,NULL,10.0000,0,'MATCHED',NULL,'2026-08-05 13:02:21.538','2026-08-05 13:02:21.538','Matched'),(7,1,1,7,2,8,'GROSS_WEIGHT','CAPITALISE',NULL,'INR',1.00000000,92000.0000,92000.0000,92000.0000,NULL,NULL,NULL,NULL,NULL,NULL,8.0000,0,'ACCRUED',NULL,'2026-08-05 13:02:21.539','2026-08-05 13:02:21.539','Awaiting invoice'),(8,1,1,8,8,3,'DIRECT','EXPENSE',NULL,'INR',1.00000000,0.0000,0.0000,0.0000,18000.0000,18000.0000,'AGL/26/8877',NULL,NULL,NULL,0.0000,0,'MATCHED',NULL,'2026-08-05 13:02:21.540','2026-08-05 13:02:21.540','Unbudgeted — root cause: duty payment delay'),(9,2,1,1,1,3,'GROSS_WEIGHT','CAPITALISE',NULL,'INR',1.00000000,168000.0000,168000.0000,168000.0000,NULL,NULL,NULL,NULL,NULL,NULL,5.0000,0,'ACCRUED',NULL,'2026-08-05 13:02:21.542','2026-08-05 13:02:21.542','Awaiting invoice 58 days'),(10,2,1,2,4,NULL,'DIRECT','CAPITALISE',NULL,'INR',1.00000000,475640.0000,475640.0000,475640.0000,475640.0000,475640.0000,'CHLN/4412884',NULL,NULL,NULL,1.0000,0,'MATCHED',NULL,'2026-08-05 13:02:21.545','2026-08-05 13:02:21.545','Matched'),(11,2,1,3,3,3,'CONTAINER','CAPITALISE',NULL,'INR',1.00000000,44000.0000,44000.0000,44000.0000,NULL,NULL,NULL,NULL,NULL,NULL,5.0000,0,'ACCRUED',NULL,'2026-08-05 13:02:21.547','2026-08-05 13:02:21.547','Awaiting invoice 58 days'),(12,2,1,4,8,3,'DIRECT','EXPENSE',NULL,'INR',1.00000000,0.0000,0.0000,0.0000,18000.0000,18000.0000,'AGL/26/8102',NULL,NULL,NULL,0.0000,0,'MATCHED',NULL,'2026-08-05 13:02:21.548','2026-08-05 13:02:21.548','Matched');
/*!40000 ALTER TABLE `cost_line` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cost_sheet`
--

DROP TABLE IF EXISTS `cost_sheet`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cost_sheet` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `cost_sheet_no` varchar(40) NOT NULL,
  `shipment_id` bigint unsigned NOT NULL,
  `declaration_id` bigint unsigned DEFAULT NULL,
  `direction` enum('IMPORT','EXPORT') NOT NULL,
  `currency` char(3) NOT NULL,
  `goods_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `total_estimate` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `total_accrued` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `total_actual` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `variance_invoiced` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `uninvoiced_accrual` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `capitalised_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `expensed_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `recoverable_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `allocation_basis` enum('VALUE','GROSS_WEIGHT','VOLUME','QUANTITY','CHARGEABLE_WEIGHT','CONTAINER','DIRECT','EQUAL') NOT NULL DEFAULT 'VALUE',
  `stock_on_hand_pct` decimal(9,4) NOT NULL DEFAULT '100.0000',
  `status` enum('OPEN','ACCRUED','PART_ACTUAL','READY_TO_CLOSE','CLOSED','REOPENED') NOT NULL DEFAULT 'OPEN',
  `closed_on` date DEFAULT NULL,
  `closed_by` bigint unsigned DEFAULT NULL,
  `closure_voucher_id` bigint unsigned DEFAULT NULL,
  `tolerance_breaches` smallint unsigned NOT NULL DEFAULT '0',
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cs` (`entity_id`,`cost_sheet_no`),
  UNIQUE KEY `uq_cs_shipment` (`shipment_id`),
  KEY `ix_cs_status` (`entity_id`,`status`,`created_at`),
  KEY `ix_cs_breach` (`entity_id`,`tolerance_breaches`),
  CONSTRAINT `fk_cs_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`),
  CONSTRAINT `fk_cs_shp` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cost_sheet`
--

LOCK TABLES `cost_sheet` WRITE;
/*!40000 ALTER TABLE `cost_sheet` DISABLE KEYS */;
INSERT INTO `cost_sheet` VALUES (1,1,'CS-001',1,NULL,'IMPORT','INR',13564518.0000,4057336.6200,4057336.6200,3916936.6200,71600.0000,212000.0000,1453065.2800,18000.0000,2657871.3400,'VALUE',62.0000,'PART_ACTUAL',NULL,NULL,NULL,2,1,'2026-08-05 13:02:21.527','2026-08-05 13:02:21.527'),(2,1,'CS-003',5,NULL,'IMPORT','INR',7994000.0000,687640.0000,687640.0000,493640.0000,18000.0000,212000.0000,687640.0000,18000.0000,0.0000,'VALUE',18.0000,'PART_ACTUAL',NULL,NULL,NULL,0,1,'2026-08-05 13:02:21.541','2026-08-05 13:02:21.541');
/*!40000 ALTER TABLE `cost_sheet` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `country`
--

DROP TABLE IF EXISTS `country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `country` (
  `code` char(2) NOT NULL,
  `name` varchar(100) NOT NULL,
  `default_ccy` char(3) DEFAULT NULL,
  `is_embargoed` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `country`
--

LOCK TABLES `country` WRITE;
/*!40000 ALTER TABLE `country` DISABLE KEYS */;
INSERT INTO `country` VALUES ('AE','United Arab Emirates','AED',0),('AU','Australia','AUD',0),('CN','China','CNY',0),('DE','Germany','EUR',0),('FR','France','EUR',0),('GB','United Kingdom','GBP',0),('IN','India','INR',0),('IT','Italy','EUR',0),('JP','Japan','JPY',0),('KR','Korea, Republic of','KRW',0),('NL','Netherlands','EUR',0),('SE','Sweden','SEK',0),('SG','Singapore','SGD',0),('US','United States','USD',0);
/*!40000 ALTER TABLE `country` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `credential`
--

DROP TABLE IF EXISTS `credential`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `credential` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `credential_no` varchar(60) NOT NULL,
  `credential_type` varchar(60) DEFAULT NULL,
  `holder` varchar(160) DEFAULT NULL,
  `authority` varchar(80) DEFAULT NULL,
  `issued_on` date DEFAULT NULL,
  `valid_to` date DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`id`),
  KEY `ix_cred_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credential`
--

LOCK TABLES `credential` WRITE;
/*!40000 ALTER TABLE `credential` DISABLE KEYS */;
INSERT INTO `credential` VALUES (1,1,'0507012345','IEC','HB Manufacturing Ltd','DGFT','2019-04-01','2027-03-31','ACTIVE'),(2,1,'27AABCH1234K1Z5','GSTIN','HB Manufacturing Ltd','GSTN','2017-07-01',NULL,'ACTIVE'),(3,1,'AEO-T2-2024-8891','AEO','HB Manufacturing Ltd','CBIC','2024-02-15','2027-02-14','EXPIRING');
/*!40000 ALTER TABLE `credential` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `currency`
--

DROP TABLE IF EXISTS `currency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `currency` (
  `code` char(3) NOT NULL,
  `name` varchar(60) NOT NULL,
  `precision_dp` tinyint unsigned NOT NULL DEFAULT '2',
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `currency`
--

LOCK TABLES `currency` WRITE;
/*!40000 ALTER TABLE `currency` DISABLE KEYS */;
INSERT INTO `currency` VALUES ('AED','UAE Dirham',2),('AUD','Australian Dollar',2),('CNY','Chinese Yuan',2),('EUR','Euro',2),('GBP','Pound Sterling',2),('INR','Indian Rupee',2),('JPY','Japanese Yen',0),('KRW','Korean Won',0),('SEK','Swedish Krona',2),('SGD','Singapore Dollar',2),('USD','US Dollar',2);
/*!40000 ALTER TABLE `currency` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `declaration`
--

DROP TABLE IF EXISTS `declaration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `declaration` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `period_key` int unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `site_id` bigint unsigned DEFAULT NULL,
  `declaration_no` varchar(40) NOT NULL,
  `declaration_type` varchar(40) NOT NULL,
  `type_label` varchar(160) DEFAULT NULL,
  `direction` enum('IMPORT','EXPORT') NOT NULL,
  `jurisdiction` char(2) NOT NULL DEFAULT 'IN',
  `shipment_id` bigint unsigned DEFAULT NULL,
  `party_id` bigint unsigned NOT NULL,
  `broker_id` bigint unsigned DEFAULT NULL,
  `port_code` varchar(10) NOT NULL,
  `filing_channel` enum('ICEGATE','PORTAL','MANUAL','EDI','API') NOT NULL DEFAULT 'ICEGATE',
  `authority_ref` varchar(60) DEFAULT NULL,
  `declaration_date` date NOT NULL,
  `filed_on` date DEFAULT NULL,
  `assessed_on` date DEFAULT NULL,
  `paid_on` date DEFAULT NULL,
  `cleared_on` date DEFAULT NULL,
  `leo_ref` varchar(60) DEFAULT NULL,
  `egm_matched` tinyint(1) NOT NULL DEFAULT '0',
  `status` enum('DRAFT','VALIDATED','TRANSMITTED','QUERIED','ASSESSED','PAID','CLEARED','CANCELLED','AMENDED') NOT NULL DEFAULT 'DRAFT',
  `status_label` varchar(80) DEFAULT NULL,
  `is_provisional` tinyint(1) NOT NULL DEFAULT '0',
  `provisional_reason` varchar(300) DEFAULT NULL,
  `bond_id` bigint unsigned DEFAULT NULL,
  `amends_id` bigint unsigned DEFAULT NULL,
  `currency` char(3) NOT NULL,
  `statutory_fx_rate` decimal(18,8) NOT NULL DEFAULT '1.00000000',
  `accounting_fx_rate` decimal(18,8) NOT NULL DEFAULT '1.00000000',
  `invoice_value_fc` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `freight_fc` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `insurance_fc` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `assessable_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_total` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_recoverable` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_inventoriable` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_assessed` decimal(20,4) DEFAULT NULL,
  `duty_paid` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_saved` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_blocked` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `fob_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `error_count` smallint unsigned NOT NULL DEFAULT '0',
  `warning_count` smallint unsigned NOT NULL DEFAULT '0',
  `rule_pack_id` bigint unsigned DEFAULT NULL,
  `computed_at` datetime(3) DEFAULT NULL,
  `prepared_by` bigint unsigned DEFAULT NULL,
  `approved_by` bigint unsigned DEFAULT NULL,
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`period_key`,`id`),
  UNIQUE KEY `uq_dec_no` (`entity_id`,`jurisdiction`,`declaration_no`,`period_key`),
  KEY `ix_dec_id` (`id`),
  KEY `ix_dec_list` (`entity_id`,`direction`,`status`,`declaration_date`,`id`),
  KEY `ix_dec_shipment` (`entity_id`,`shipment_id`),
  KEY `ix_dec_party` (`entity_id`,`party_id`,`declaration_date`),
  KEY `ix_dec_port` (`entity_id`,`port_code`,`declaration_date`),
  KEY `ix_dec_prov` (`entity_id`,`is_provisional`,`status`),
  KEY `ix_dec_authority` (`entity_id`,`authority_ref`),
  KEY `ix_dec_register` (`entity_id`,`period_key`,`direction`,`declaration_type`),
  KEY `ix_dec_bond` (`entity_id`,`bond_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50100 PARTITION BY RANGE (`period_key`)
(PARTITION p2025 VALUES LESS THAN (202601) ENGINE = InnoDB,
 PARTITION p202601 VALUES LESS THAN (202602) ENGINE = InnoDB,
 PARTITION p202602 VALUES LESS THAN (202603) ENGINE = InnoDB,
 PARTITION p202603 VALUES LESS THAN (202604) ENGINE = InnoDB,
 PARTITION p202604 VALUES LESS THAN (202605) ENGINE = InnoDB,
 PARTITION p202605 VALUES LESS THAN (202606) ENGINE = InnoDB,
 PARTITION p202606 VALUES LESS THAN (202607) ENGINE = InnoDB,
 PARTITION p202607 VALUES LESS THAN (202608) ENGINE = InnoDB,
 PARTITION p202608 VALUES LESS THAN (202609) ENGINE = InnoDB,
 PARTITION p202609 VALUES LESS THAN (202610) ENGINE = InnoDB,
 PARTITION p202610 VALUES LESS THAN (202611) ENGINE = InnoDB,
 PARTITION p202611 VALUES LESS THAN (202612) ENGINE = InnoDB,
 PARTITION p202612 VALUES LESS THAN (202701) ENGINE = InnoDB,
 PARTITION p202701 VALUES LESS THAN (202702) ENGINE = InnoDB,
 PARTITION p202702 VALUES LESS THAN (202703) ENGINE = InnoDB,
 PARTITION p202703 VALUES LESS THAN (202704) ENGINE = InnoDB,
 PARTITION p202704 VALUES LESS THAN (202705) ENGINE = InnoDB,
 PARTITION p202705 VALUES LESS THAN (202706) ENGINE = InnoDB,
 PARTITION p202706 VALUES LESS THAN (202707) ENGINE = InnoDB,
 PARTITION p202707 VALUES LESS THAN (202708) ENGINE = InnoDB,
 PARTITION p202708 VALUES LESS THAN (202709) ENGINE = InnoDB,
 PARTITION p202709 VALUES LESS THAN (202710) ENGINE = InnoDB,
 PARTITION p202710 VALUES LESS THAN (202711) ENGINE = InnoDB,
 PARTITION p202711 VALUES LESS THAN (202712) ENGINE = InnoDB,
 PARTITION p202712 VALUES LESS THAN (202801) ENGINE = InnoDB,
 PARTITION pmax VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `declaration`
--

LOCK TABLES `declaration` WRITE;
/*!40000 ALTER TABLE `declaration` DISABLE KEYS */;
INSERT INTO `declaration` VALUES (3,202606,1,1,'BOE-4412','Home consumption','Home consumption','IMPORT','IN',5,2,NULL,'INNSA1','ICEGATE','4412884','2026-06-03','2026-06-03',NULL,'2026-06-05','2026-06-06',NULL,0,'CLEARED','Cleared',0,NULL,NULL,NULL,'USD',83.10000000,83.10000000,0.0000,0.0000,0.0000,8112400.0000,1621240.0000,1145600.0000,475640.0000,1621240.0000,0.0000,0.0000,0.0000,0.0000,0,0,NULL,'2026-07-07 10:00:00.000',NULL,NULL,1,'2026-08-05 13:02:21.482','2026-08-05 13:02:21.482'),(1,202607,1,1,'BOE-4471','Home consumption','Home consumption','IMPORT','IN',1,2,NULL,'INNSA1','ICEGATE','4471021','2026-07-07','2026-07-07',NULL,NULL,NULL,NULL,0,'ASSESSED','Under assessment',0,NULL,NULL,NULL,'USD',82.65000000,82.65000000,0.0000,0.0000,0.0000,13971486.6000,3452336.6200,2657871.3400,794465.2800,3473736.6200,0.0000,358182.3700,320257.1800,0.0000,0,0,NULL,'2026-07-07 10:00:00.000',NULL,NULL,1,'2026-08-05 13:02:21.429','2026-08-05 13:02:21.429'),(2,202607,1,1,'SB-0119','Export under LUT with RoDTEP and drawbac','Export under LUT with RoDTEP and drawback','EXPORT','IN',2,5,NULL,'INNSA1','ICEGATE','0119284','2026-07-26','2026-07-26',NULL,NULL,NULL,'LEO/0119284',1,'CLEARED','Permitted to export',0,NULL,NULL,NULL,'EUR',96.40000000,96.40000000,0.0000,0.0000,0.0000,33045920.0000,0.0000,0.0000,0.0000,NULL,0.0000,0.0000,0.0000,33045920.0000,0,0,NULL,'2026-07-07 10:00:00.000',NULL,NULL,1,'2026-08-05 13:02:21.473','2026-08-05 13:02:21.473');
/*!40000 ALTER TABLE `declaration` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `declaration_levy`
--

DROP TABLE IF EXISTS `declaration_levy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `declaration_levy` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `period_key` int unsigned NOT NULL,
  `declaration_line_id` bigint unsigned NOT NULL,
  `declaration_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `seq` smallint unsigned NOT NULL,
  `levy_code` varchar(20) NOT NULL,
  `levy_name` varchar(120) NOT NULL,
  `base_expression` varchar(300) NOT NULL,
  `base_amount` decimal(20,4) NOT NULL,
  `rate_type` enum('AD_VALOREM','SPECIFIC','COMPOUND','NIL') NOT NULL DEFAULT 'AD_VALOREM',
  `rate_pct` decimal(18,8) NOT NULL DEFAULT '0.00000000',
  `rate_per_unit` decimal(20,6) DEFAULT NULL,
  `amount` decimal(20,4) NOT NULL,
  `rate_source` enum('SCHEDULE','PREFERENCE','EXEMPTION','NOTIFICATION','OVERRIDE') NOT NULL DEFAULT 'SCHEDULE',
  `rate_source_ref` varchar(80) DEFAULT NULL,
  `levy_rate_id` bigint unsigned DEFAULT NULL,
  `is_recoverable` tinyint(1) NOT NULL DEFAULT '0',
  `gl_account_id` bigint unsigned DEFAULT NULL,
  `overridden_by` bigint unsigned DEFAULT NULL,
  `override_reason` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`period_key`,`id`),
  UNIQUE KEY `uq_dlv` (`declaration_line_id`,`levy_code`,`period_key`),
  KEY `ix_dlv_id` (`id`),
  KEY `ix_dlv_line` (`declaration_line_id`,`seq`),
  KEY `ix_dlv_dec` (`declaration_id`),
  KEY `ix_dlv_register` (`entity_id`,`period_key`,`levy_code`,`amount`),
  KEY `ix_dlv_source` (`entity_id`,`rate_source`,`period_key`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50100 PARTITION BY RANGE (`period_key`)
(PARTITION p2025 VALUES LESS THAN (202601) ENGINE = InnoDB,
 PARTITION p202601 VALUES LESS THAN (202602) ENGINE = InnoDB,
 PARTITION p202602 VALUES LESS THAN (202603) ENGINE = InnoDB,
 PARTITION p202603 VALUES LESS THAN (202604) ENGINE = InnoDB,
 PARTITION p202604 VALUES LESS THAN (202605) ENGINE = InnoDB,
 PARTITION p202605 VALUES LESS THAN (202606) ENGINE = InnoDB,
 PARTITION p202606 VALUES LESS THAN (202607) ENGINE = InnoDB,
 PARTITION p202607 VALUES LESS THAN (202608) ENGINE = InnoDB,
 PARTITION p202608 VALUES LESS THAN (202609) ENGINE = InnoDB,
 PARTITION p202609 VALUES LESS THAN (202610) ENGINE = InnoDB,
 PARTITION p202610 VALUES LESS THAN (202611) ENGINE = InnoDB,
 PARTITION p202611 VALUES LESS THAN (202612) ENGINE = InnoDB,
 PARTITION p202612 VALUES LESS THAN (202701) ENGINE = InnoDB,
 PARTITION p202701 VALUES LESS THAN (202702) ENGINE = InnoDB,
 PARTITION p202702 VALUES LESS THAN (202703) ENGINE = InnoDB,
 PARTITION p202703 VALUES LESS THAN (202704) ENGINE = InnoDB,
 PARTITION p202704 VALUES LESS THAN (202705) ENGINE = InnoDB,
 PARTITION p202705 VALUES LESS THAN (202706) ENGINE = InnoDB,
 PARTITION p202706 VALUES LESS THAN (202707) ENGINE = InnoDB,
 PARTITION p202707 VALUES LESS THAN (202708) ENGINE = InnoDB,
 PARTITION p202708 VALUES LESS THAN (202709) ENGINE = InnoDB,
 PARTITION p202709 VALUES LESS THAN (202710) ENGINE = InnoDB,
 PARTITION p202710 VALUES LESS THAN (202711) ENGINE = InnoDB,
 PARTITION p202711 VALUES LESS THAN (202712) ENGINE = InnoDB,
 PARTITION p202712 VALUES LESS THAN (202801) ENGINE = InnoDB,
 PARTITION pmax VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `declaration_levy`
--

LOCK TABLES `declaration_levy` WRITE;
/*!40000 ALTER TABLE `declaration_levy` DISABLE KEYS */;
INSERT INTO `declaration_levy` VALUES (1,202607,1,1,1,1,'BCD','Basic customs duty','AV',4341604.5000,'AD_VALOREM',0.00000000,NULL,0.0000,'PREFERENCE',NULL,NULL,0,NULL,NULL,NULL),(2,202607,1,1,1,2,'SWS','Social welfare surcharge','BCD',0.0000,'AD_VALOREM',10.00000000,NULL,0.0000,'SCHEDULE',NULL,NULL,0,NULL,NULL,NULL),(3,202607,1,1,1,3,'IGST','Integrated tax on import','AV+BCD+SWS+AIDC+ADD',4341604.5000,'AD_VALOREM',18.00000000,NULL,781488.8100,'SCHEDULE',NULL,NULL,1,NULL,NULL,NULL),(4,202607,2,1,1,1,'BCD','Basic customs duty','AV',3881905.2000,'AD_VALOREM',7.50000000,NULL,291142.8900,'PREFERENCE',NULL,NULL,0,NULL,NULL,NULL),(5,202607,2,1,1,2,'SWS','Social welfare surcharge','BCD',291142.8900,'AD_VALOREM',10.00000000,NULL,29114.2900,'SCHEDULE',NULL,NULL,0,NULL,NULL,NULL),(6,202607,2,1,1,3,'IGST','Integrated tax on import','AV+BCD+SWS+AIDC+ADD',4202162.3800,'AD_VALOREM',18.00000000,NULL,756389.2300,'SCHEDULE',NULL,NULL,1,NULL,NULL,NULL),(7,202607,3,1,1,1,'BCD','Basic customs duty','AV',2111211.6000,'AD_VALOREM',7.50000000,NULL,158340.8700,'SCHEDULE',NULL,NULL,0,NULL,NULL,NULL),(8,202607,3,1,1,2,'SWS','Social welfare surcharge','BCD',158340.8700,'AD_VALOREM',10.00000000,NULL,15834.0900,'SCHEDULE',NULL,NULL,0,NULL,NULL,NULL),(9,202607,3,1,1,3,'IGST','Integrated tax on import','AV+BCD+SWS+AIDC+ADD',2285386.5600,'AD_VALOREM',18.00000000,NULL,411369.5800,'SCHEDULE',NULL,NULL,1,NULL,NULL,NULL),(10,202607,4,1,1,1,'BCD','Basic customs duty','AV',3636765.3000,'AD_VALOREM',7.50000000,NULL,272757.4000,'SCHEDULE',NULL,NULL,0,NULL,NULL,NULL),(11,202607,4,1,1,2,'SWS','Social welfare surcharge','BCD',272757.4000,'AD_VALOREM',10.00000000,NULL,27275.7400,'SCHEDULE',NULL,NULL,0,NULL,NULL,NULL),(12,202607,4,1,1,3,'IGST','Integrated tax on import','AV+BCD+SWS+AIDC+ADD',3936798.4400,'AD_VALOREM',18.00000000,NULL,708623.7200,'SCHEDULE',NULL,NULL,1,NULL,NULL,NULL);
/*!40000 ALTER TABLE `declaration_levy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `declaration_line`
--

DROP TABLE IF EXISTS `declaration_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `declaration_line` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `period_key` int unsigned NOT NULL,
  `declaration_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `line_no` smallint unsigned NOT NULL,
  `shipment_line_id` bigint unsigned DEFAULT NULL,
  `order_line_id` bigint unsigned DEFAULT NULL,
  `item_id` bigint unsigned DEFAULT NULL,
  `item_code` varchar(40) NOT NULL,
  `description` varchar(300) NOT NULL,
  `statutory_description` varchar(500) DEFAULT NULL,
  `hs_code` varchar(12) NOT NULL,
  `qty_statutory` decimal(20,6) NOT NULL,
  `statutory_uom` varchar(10) NOT NULL,
  `qty_stock` decimal(20,6) NOT NULL,
  `stock_uom` varchar(10) NOT NULL,
  `uom_conversion` decimal(20,8) NOT NULL DEFAULT '1.00000000',
  `unit_price_fc` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `invoice_value_fc` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `freight_fc` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `insurance_fc` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `other_addition_fc` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `currency` char(3) NOT NULL,
  `assessable_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `valuation_method` enum('TRANSACTION','IDENTICAL','SIMILAR','DEDUCTIVE','COMPUTED','RESIDUAL') NOT NULL DEFAULT 'TRANSACTION',
  `origin_country` char(2) DEFAULT NULL,
  `consignment_country` char(2) DEFAULT NULL,
  `preference_agreement` varchar(20) DEFAULT NULL,
  `preference_claimed` tinyint(1) NOT NULL DEFAULT '0',
  `preference_proof_ref` varchar(80) DEFAULT NULL,
  `preference_proof_doc_id` bigint unsigned DEFAULT NULL,
  `exemption_ref` varchar(60) DEFAULT NULL,
  `licence_id` bigint unsigned DEFAULT NULL,
  `scheme_id` bigint unsigned DEFAULT NULL,
  `duty_total` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_recoverable` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_inventoriable` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_saved` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_blocked` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `net_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `gross_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `landed_unit_cost` decimal(20,6) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`period_key`,`id`),
  UNIQUE KEY `uq_dl` (`declaration_id`,`line_no`,`period_key`),
  KEY `ix_dl_id` (`id`),
  KEY `ix_dl_declaration` (`declaration_id`,`line_no`),
  KEY `ix_dl_item` (`entity_id`,`item_id`,`period_key`),
  KEY `ix_dl_hs` (`entity_id`,`hs_code`,`period_key`),
  KEY `ix_dl_licence` (`entity_id`,`licence_id`),
  KEY `ix_dl_scheme` (`entity_id`,`scheme_id`,`period_key`),
  KEY `ix_dl_blocked` (`entity_id`,`period_key`,`duty_blocked`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50100 PARTITION BY RANGE (`period_key`)
(PARTITION p2025 VALUES LESS THAN (202601) ENGINE = InnoDB,
 PARTITION p202601 VALUES LESS THAN (202602) ENGINE = InnoDB,
 PARTITION p202602 VALUES LESS THAN (202603) ENGINE = InnoDB,
 PARTITION p202603 VALUES LESS THAN (202604) ENGINE = InnoDB,
 PARTITION p202604 VALUES LESS THAN (202605) ENGINE = InnoDB,
 PARTITION p202605 VALUES LESS THAN (202606) ENGINE = InnoDB,
 PARTITION p202606 VALUES LESS THAN (202607) ENGINE = InnoDB,
 PARTITION p202607 VALUES LESS THAN (202608) ENGINE = InnoDB,
 PARTITION p202608 VALUES LESS THAN (202609) ENGINE = InnoDB,
 PARTITION p202609 VALUES LESS THAN (202610) ENGINE = InnoDB,
 PARTITION p202610 VALUES LESS THAN (202611) ENGINE = InnoDB,
 PARTITION p202611 VALUES LESS THAN (202612) ENGINE = InnoDB,
 PARTITION p202612 VALUES LESS THAN (202701) ENGINE = InnoDB,
 PARTITION p202701 VALUES LESS THAN (202702) ENGINE = InnoDB,
 PARTITION p202702 VALUES LESS THAN (202703) ENGINE = InnoDB,
 PARTITION p202703 VALUES LESS THAN (202704) ENGINE = InnoDB,
 PARTITION p202704 VALUES LESS THAN (202705) ENGINE = InnoDB,
 PARTITION p202705 VALUES LESS THAN (202706) ENGINE = InnoDB,
 PARTITION p202706 VALUES LESS THAN (202707) ENGINE = InnoDB,
 PARTITION p202707 VALUES LESS THAN (202708) ENGINE = InnoDB,
 PARTITION p202708 VALUES LESS THAN (202709) ENGINE = InnoDB,
 PARTITION p202709 VALUES LESS THAN (202710) ENGINE = InnoDB,
 PARTITION p202710 VALUES LESS THAN (202711) ENGINE = InnoDB,
 PARTITION p202711 VALUES LESS THAN (202712) ENGINE = InnoDB,
 PARTITION p202712 VALUES LESS THAN (202801) ENGINE = InnoDB,
 PARTITION pmax VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `declaration_line`
--

LOCK TABLES `declaration_line` WRITE;
/*!40000 ALTER TABLE `declaration_line` DISABLE KEYS */;
INSERT INTO `declaration_line` VALUES (1,202607,1,1,1,NULL,NULL,1,'HPB-4400','Bearing housing, cast steel',NULL,'84821020',1200.000000,'PCS',1200.000000,'EA',1.00000000,42.500000,51000.0000,1275.0000,255.0000,0.0000,'USD',4341604.5000,'TRANSACTION','KR',NULL,'AIFTA',1,'COO/KR/2026/88412',NULL,NULL,NULL,NULL,781488.8100,781488.8100,0.0000,358182.3700,0.0000,2480.000000,0.000000,NULL,'2026-08-05 13:02:21.441','2026-08-05 13:02:21.441'),(2,202607,1,1,2,NULL,NULL,2,'HPB-4410','Precision bearing, sealed',NULL,'84821010',4000.000000,'PCS',4000.000000,'EA',1.00000000,11.400000,45600.0000,1140.0000,228.0000,0.0000,'USD',3881905.2000,'TRANSACTION','KR',NULL,'AIFTA',1,NULL,NULL,NULL,NULL,NULL,1076646.4100,756389.2300,320257.1800,0.0000,320257.1800,1240.000000,0.000000,NULL,'2026-08-05 13:02:21.458','2026-08-05 13:02:21.458'),(3,202607,1,1,3,NULL,NULL,3,'HPB-4420','Seal kit, nitrile',NULL,'40169390',8000.000000,'PCS',8000.000000,'EA',1.00000000,3.100000,24800.0000,620.0000,124.0000,0.0000,'USD',2111211.6000,'TRANSACTION','KR',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,585544.5400,411369.5800,174174.9600,0.0000,0.0000,1020.000000,0.000000,NULL,'2026-08-05 13:02:21.462','2026-08-05 13:02:21.462'),(4,202607,1,1,4,NULL,NULL,4,'HPB-4430','Spindle assembly',NULL,'84831099',600.000000,'PCS',600.000000,'EA',1.00000000,71.200000,42720.0000,1068.0000,214.0000,0.0000,'USD',3636765.3000,'TRANSACTION','KR',NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,1008656.8600,708623.7200,300033.1400,0.0000,0.0000,1210.000000,0.000000,NULL,'2026-08-05 13:02:21.469','2026-08-05 13:02:21.469');
/*!40000 ALTER TABLE `declaration_line` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `declaration_validation`
--

DROP TABLE IF EXISTS `declaration_validation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `declaration_validation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `declaration_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `rule_id` varchar(30) NOT NULL,
  `severity` enum('ERROR','WARNING','INFO') NOT NULL,
  `field_ref` varchar(80) DEFAULT NULL,
  `line_no` smallint unsigned DEFAULT NULL,
  `message` varchar(500) NOT NULL,
  `remedy` varchar(500) NOT NULL,
  `is_open` tinyint(1) NOT NULL DEFAULT '1',
  `waived_by` bigint unsigned DEFAULT NULL,
  `waiver_reason` varchar(300) DEFAULT NULL,
  `detected_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `ix_dv_dec` (`declaration_id`,`is_open`),
  KEY `ix_dv_rule` (`entity_id`,`rule_id`,`is_open`),
  KEY `ix_dv_open` (`entity_id`,`severity`,`is_open`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `declaration_validation`
--

LOCK TABLES `declaration_validation` WRITE;
/*!40000 ALTER TABLE `declaration_validation` DISABLE KEYS */;
/*!40000 ALTER TABLE `declaration_validation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document`
--

DROP TABLE IF EXISTS `document`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `doc_type` varchar(60) NOT NULL,
  `doc_class` enum('COMMERCIAL','TRANSPORT','STATUTORY','FINANCIAL','CERTIFICATE','INTERNAL','CORRESPONDENCE') NOT NULL,
  `title` varchar(300) NOT NULL,
  `doc_ref` varchar(80) DEFAULT NULL,
  `doc_date` date DEFAULT NULL,
  `issuer` varchar(200) DEFAULT NULL,
  `object_type` varchar(40) NOT NULL,
  `object_id` bigint unsigned NOT NULL,
  `current_version` smallint unsigned NOT NULL DEFAULT '1',
  `is_original_held` tinyint(1) NOT NULL DEFAULT '0',
  `is_mandatory` tinyint(1) NOT NULL DEFAULT '0',
  `is_received` tinyint(1) NOT NULL DEFAULT '0',
  `retention_years` tinyint unsigned NOT NULL DEFAULT '8',
  `retain_until` date DEFAULT NULL,
  `legal_hold` tinyint(1) NOT NULL DEFAULT '0',
  `storage_uri` varchar(500) DEFAULT NULL,
  `content_sha256` char(64) DEFAULT NULL,
  `size_bytes` bigint unsigned DEFAULT NULL,
  `mime_type` varchar(100) DEFAULT NULL,
  `uploaded_by` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `ix_doc_object` (`entity_id`,`object_type`,`object_id`,`doc_type`),
  KEY `ix_doc_type` (`entity_id`,`doc_type`,`doc_date`),
  KEY `ix_doc_ref` (`entity_id`,`doc_ref`),
  KEY `ix_doc_retention` (`entity_id`,`retain_until`,`legal_hold`),
  KEY `ix_doc_hash` (`content_sha256`),
  KEY `ix_doc_missing` (`entity_id`,`is_mandatory`,`is_received`),
  CONSTRAINT `fk_doc_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document`
--

LOCK TABLES `document` WRITE;
/*!40000 ALTER TABLE `document` DISABLE KEYS */;
/*!40000 ALTER TABLE `document` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document_set`
--

DROP TABLE IF EXISTS `document_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_set` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `set_no` varchar(40) NOT NULL,
  `shipment_no` varchar(40) DEFAULT NULL,
  `doc_type` varchar(60) DEFAULT NULL,
  `party` varchar(160) DEFAULT NULL,
  `received_on` date DEFAULT NULL,
  `completeness_pct` decimal(5,1) NOT NULL DEFAULT '0.0',
  `status` varchar(24) NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (`id`),
  KEY `ix_docset_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_set`
--

LOCK TABLES `document_set` WRITE;
/*!40000 ALTER TABLE `document_set` DISABLE KEYS */;
INSERT INTO `document_set` VALUES (1,1,'DS-2026-0771','SHP-2026-04471','Import clearance set','Hanwha Precision Co','2026-07-12',100.0,'CLEARED'),(2,1,'DS-2026-0782','SHP-2026-04488','Import clearance set','Zhejiang Fastener Works','2026-07-22',80.0,'PARTIAL'),(3,1,'DS-2026-0790','SHP-2026-04502','Import clearance set','Bosch Rexroth AG',NULL,40.0,'OPEN');
/*!40000 ALTER TABLE `document_set` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document_version`
--

DROP TABLE IF EXISTS `document_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_version` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `document_id` bigint unsigned NOT NULL,
  `version_no` smallint unsigned NOT NULL,
  `storage_uri` varchar(500) NOT NULL,
  `content_sha256` char(64) NOT NULL,
  `size_bytes` bigint unsigned NOT NULL,
  `mime_type` varchar(100) DEFAULT NULL,
  `supersede_reason` varchar(300) DEFAULT NULL,
  `uploaded_by` bigint unsigned DEFAULT NULL,
  `uploaded_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dv` (`document_id`,`version_no`),
  CONSTRAINT `fk_dv_doc` FOREIGN KEY (`document_id`) REFERENCES `document` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_version`
--

LOCK TABLES `document_version` WRITE;
/*!40000 ALTER TABLE `document_version` DISABLE KEYS */;
/*!40000 ALTER TABLE `document_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `enquiry`
--

DROP TABLE IF EXISTS `enquiry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enquiry` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `enquiry_no` varchar(40) NOT NULL,
  `enquiry_date` date NOT NULL,
  `customer` varchar(160) DEFAULT NULL,
  `country_code` varchar(2) DEFAULT NULL,
  `item_desc` varchar(240) DEFAULT NULL,
  `qty` decimal(18,3) NOT NULL DEFAULT '0.000',
  `target_price` decimal(16,2) NOT NULL DEFAULT '0.00',
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `status` varchar(24) NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (`id`),
  KEY `ix_enquiry_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `enquiry`
--

LOCK TABLES `enquiry` WRITE;
/*!40000 ALTER TABLE `enquiry` DISABLE KEYS */;
INSERT INTO `enquiry` VALUES (1,1,'ENQ-2026-0501','2026-07-02','Meridian Industries','US','Machined spindle housings',5000.000,42.50,'USD','QUOTED'),(2,1,'ENQ-2026-0512','2026-07-16','Nordic Components AB','SE','Precision bearings, sealed',12000.000,8.90,'EUR','OPEN'),(3,1,'ENQ-2026-0525','2026-07-29','Gulf Machinery LLC','AE','Hydraulic valve blocks',800.000,130.00,'USD','WON');
/*!40000 ALTER TABLE `enquiry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `entitlement_claim`
--

DROP TABLE IF EXISTS `entitlement_claim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `entitlement_claim` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `scheme_id` bigint unsigned NOT NULL,
  `claim_no` varchar(40) NOT NULL,
  `declaration_id` bigint unsigned DEFAULT NULL,
  `declaration_no` varchar(40) DEFAULT NULL,
  `declaration_date` date DEFAULT NULL,
  `fob_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `rate_pct` decimal(18,8) NOT NULL DEFAULT '0.00000000',
  `cap_per_unit` decimal(20,6) DEFAULT NULL,
  `cap_amount` decimal(20,4) DEFAULT NULL,
  `computed_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `claimed_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `sanctioned_amount` decimal(20,4) DEFAULT NULL,
  `received_amount` decimal(20,4) DEFAULT NULL,
  `shortfall_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `shortfall_cause` varchar(300) DEFAULT NULL,
  `scrip_ref` varchar(60) DEFAULT NULL,
  `scrip_value` decimal(20,4) DEFAULT NULL,
  `scrip_utilised` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `scrip_sold_value` decimal(20,4) DEFAULT NULL,
  `stage` enum('ACCRUED','FILED','SANCTIONED','SCRIP_ISSUED','RECEIVED','UTILISED','REJECTED','WRITTEN_OFF') NOT NULL DEFAULT 'ACCRUED',
  `recognition_point` enum('AT_EXPORT','AT_SANCTION','AT_RECEIPT') NOT NULL DEFAULT 'AT_EXPORT',
  `is_recognised` tinyint(1) NOT NULL DEFAULT '0',
  `recognition_voucher_id` bigint unsigned DEFAULT NULL,
  `filed_on` date DEFAULT NULL,
  `sanctioned_on` date DEFAULT NULL,
  `received_on` date DEFAULT NULL,
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ec` (`entity_id`,`claim_no`),
  KEY `ix_ec_scheme` (`entity_id`,`scheme_id`,`stage`),
  KEY `ix_ec_dec` (`declaration_id`),
  KEY `ix_ec_stage` (`entity_id`,`stage`,`declaration_date`),
  KEY `ix_ec_unrecognised` (`entity_id`,`is_recognised`,`computed_amount`),
  KEY `fk_ec_scheme` (`scheme_id`),
  CONSTRAINT `fk_ec_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`),
  CONSTRAINT `fk_ec_scheme` FOREIGN KEY (`scheme_id`) REFERENCES `scheme` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `entitlement_claim`
--

LOCK TABLES `entitlement_claim` WRITE;
/*!40000 ALTER TABLE `entitlement_claim` DISABLE KEYS */;
INSERT INTO `entitlement_claim` VALUES (1,1,4,'EC-001',2,'SB-0119','2026-07-26',18576000.0000,1.40000000,NULL,320000.0000,260064.0000,260064.0000,260064.0000,260064.0000,0.0000,NULL,'SCRIP/2026/1188',NULL,0.0000,NULL,'RECEIVED','AT_SANCTION',1,NULL,'2026-07-26',NULL,NULL,1,'2026-08-05 13:02:21.475','2026-08-05 13:02:21.475'),(2,1,5,'EC-002',2,'SB-0119','2026-07-26',18576000.0000,0.90000000,NULL,NULL,167184.0000,167184.0000,152400.0000,152400.0000,14784.0000,'Cap applied on two line items at brand rate',NULL,NULL,0.0000,NULL,'RECEIVED','AT_SANCTION',1,NULL,'2026-07-26',NULL,NULL,1,'2026-08-05 13:02:21.479','2026-08-05 13:02:21.479'),(3,1,4,'EC-003',2,'SB-0119','2026-07-26',14469920.0000,1.40000000,NULL,NULL,202579.0000,202579.0000,NULL,NULL,0.0000,NULL,NULL,NULL,0.0000,NULL,'FILED','AT_SANCTION',0,NULL,'2026-07-26',NULL,NULL,1,'2026-08-05 13:02:21.480','2026-08-05 13:02:21.480');
/*!40000 ALTER TABLE `entitlement_claim` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `exception_item`
--

DROP TABLE IF EXISTS `exception_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `exception_item` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `rule_id` varchar(30) NOT NULL,
  `severity` enum('CRITICAL','HIGH','MEDIUM','INFO') NOT NULL,
  `exception_type` varchar(40) NOT NULL,
  `title` varchar(300) NOT NULL,
  `detail` varchar(1000) NOT NULL,
  `object_type` varchar(40) NOT NULL,
  `object_id` bigint unsigned NOT NULL,
  `object_ref` varchar(60) DEFAULT NULL,
  `exposure` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `deadline_on` date DEFAULT NULL,
  `first_seen_on` date NOT NULL,
  `age_days` smallint unsigned NOT NULL DEFAULT '0',
  `owner_user_id` bigint unsigned DEFAULT NULL,
  `owner_role_id` bigint unsigned DEFAULT NULL,
  `is_open` tinyint(1) NOT NULL DEFAULT '1',
  `resolution` varchar(500) DEFAULT NULL,
  `resolved_by` bigint unsigned DEFAULT NULL,
  `resolved_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exc` (`entity_id`,`rule_id`,`object_type`,`object_id`),
  KEY `ix_exc_monitor` (`entity_id`,`is_open`,`severity`,`exposure`),
  KEY `ix_exc_object` (`entity_id`,`object_type`,`object_id`),
  KEY `ix_exc_owner` (`entity_id`,`owner_user_id`,`is_open`),
  KEY `ix_exc_deadline` (`entity_id`,`is_open`,`deadline_on`),
  KEY `ix_exc_type` (`entity_id`,`exception_type`,`is_open`),
  CONSTRAINT `fk_exc_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `exception_item`
--

LOCK TABLES `exception_item` WRITE;
/*!40000 ALTER TABLE `exception_item` DISABLE KEYS */;
INSERT INTO `exception_item` VALUES (1,1,'VR-009','CRITICAL','Origin proof','Origin proof not on file — preference at risk','Line 2 claims AIFTA preferential rate. Certificate of origin has not been received. The duty saving on that line is blocked and the claim cannot be made without the proof and the underlying origin information (VR-009).','declaration',1,'D-001',290257.0000,'2026-07-10','2026-08-01',3,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.606','2026-08-05 13:02:21.606'),(2,1,'VR-014','HIGH','Document version','Insurance certificate version superseded','Certificate v1 attached to the declaration has been superseded by v2 issued on 24-Jun-2026 with a corrected assured value.','shipment',1,'S-001',0.0000,NULL,'2026-08-02',2,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.609','2026-08-05 13:02:21.609'),(3,1,'DR-009','HIGH','Free time','Free time expires in 2 days on 2 containers','Blocking item: duty payment pending. Projected detention ₹68,000 if release slips 3 days.','shipment',1,'S-001',68000.0000,'2026-07-16','2026-08-03',1,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.612','2026-08-05 13:02:21.612'),(4,1,'VR-011','CRITICAL','Presentation deadline','Bank presentation deadline tomorrow','LC/2026/0918 presentation period is 21 days from shipment date 30-Jul-2026. Deadline 05-Aug-2026. One beneficiary certificate is unsigned.','instrument',2,'I-002',342800.0000,'2026-08-05','2026-07-31',4,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.614','2026-08-05 13:02:21.614'),(5,1,'HBIE-MDM-025','HIGH','Related party','Related-party import — valuation basis required','Supplier Nordic Components AB is a related party. The declaration must record the valuation basis and any special valuation branch reference before filing.','shipment',3,'S-003',0.0000,NULL,'2026-08-03',1,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.615','2026-08-05 13:02:21.615'),(6,1,'HBIE-MDM-052','MEDIUM','Documents','3 of 10 required documents pending','Pending: certificate of origin, insurance certificate, supplier declaration of origin.','shipment',3,'S-003',0.0000,NULL,'2026-08-03',1,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.616','2026-08-05 13:02:21.616'),(7,1,'VR-020','CRITICAL','Screening','Buyer screening under review — order release blocked','Orient Traders FZE returned a potential match on the restricted-party list refresh of 03-Aug-2026 with a score of 87. Order release and payment are blocked pending disposition (VR-020).','party',6,'P-006',128600.0000,NULL,'2026-08-03',1,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.618','2026-08-05 13:02:21.618'),(8,1,'VR-029','MEDIUM','Bank details','Beneficiary bank details unverified','Bank details changed on 01-Aug-2026 and have not been independently verified. Outbound payment is suspended (VR-029).','party',6,'P-006',0.0000,NULL,'2026-08-01',3,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.619','2026-08-05 13:02:21.619'),(9,1,'VR-026','HIGH','Cost sheet','Cost sheet open 58 days — 2 provider invoices awaited','Uninvoiced accrual ₹2,12,000 in landed cost clearing. Policy age is 45 days. This is a period close blocker (C-25).','costSheet',2,'CS-003',212000.0000,NULL,'2026-06-07',58,NULL,NULL,1,NULL,NULL,NULL,'2026-08-05 13:02:21.620','2026-08-05 13:02:21.620');
/*!40000 ALTER TABLE `exception_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `export_invoice`
--

DROP TABLE IF EXISTS `export_invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `export_invoice` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `invoice_no` varchar(40) NOT NULL,
  `invoice_date` date NOT NULL,
  `customer` varchar(160) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `fob_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `incoterm` varchar(6) DEFAULT NULL,
  `shipment_no` varchar(40) DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (`id`),
  KEY `ix_expinv_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `export_invoice`
--

LOCK TABLES `export_invoice` WRITE;
/*!40000 ALTER TABLE `export_invoice` DISABLE KEYS */;
INSERT INTO `export_invoice` VALUES (1,1,'EXP/2026/0441','2026-07-24','Meridian Industries','USD',395000.00,'FOB','SHP-2026-04512','SHIPPED'),(2,1,'EXP/2026/0448','2026-07-30','Gulf Machinery LLC','USD',104000.00,'CIF','SHP-2026-04520','ISSUED'),(3,1,'EXP/2026/0455','2026-08-02','Nordic Components AB','EUR',61200.00,'FCA',NULL,'DRAFT');
/*!40000 ALTER TABLE `export_invoice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `export_realisation`
--

DROP TABLE IF EXISTS `export_realisation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `export_realisation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `declaration_id` bigint unsigned DEFAULT NULL,
  `instrument_id` bigint unsigned DEFAULT NULL,
  `invoice_ref` varchar(60) NOT NULL,
  `invoice_date` date NOT NULL,
  `currency` char(3) NOT NULL,
  `invoice_value` decimal(20,4) NOT NULL,
  `realised_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `realised_on` date DEFAULT NULL,
  `bank_ref` varchar(60) DEFAULT NULL,
  `brc_ref` varchar(60) DEFAULT NULL,
  `due_by` date DEFAULT NULL,
  `write_off_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `write_off_approved_by` bigint unsigned DEFAULT NULL,
  `status` enum('OPEN','PART_REALISED','REALISED','OVERDUE','WRITTEN_OFF') NOT NULL DEFAULT 'OPEN',
  `fx_gain_loss` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_er` (`entity_id`,`invoice_ref`),
  KEY `ix_er_due` (`entity_id`,`status`,`due_by`),
  KEY `ix_er_dec` (`declaration_id`),
  KEY `ix_er_instr` (`instrument_id`),
  CONSTRAINT `fk_er_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `export_realisation`
--

LOCK TABLES `export_realisation` WRITE;
/*!40000 ALTER TABLE `export_realisation` DISABLE KEYS */;
/*!40000 ALTER TABLE `export_realisation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `filing`
--

DROP TABLE IF EXISTS `filing`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `filing` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `filing_ref` varchar(60) NOT NULL,
  `filing_name` varchar(200) NOT NULL,
  `authority` varchar(80) DEFAULT NULL,
  `frequency` varchar(24) DEFAULT NULL,
  `period` varchar(24) DEFAULT NULL,
  `due_on` date DEFAULT NULL,
  `preparer` varchar(120) DEFAULT NULL,
  `approver` varchar(120) DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'NOT_STARTED',
  PRIMARY KEY (`id`),
  KEY `ix_filing_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `filing`
--

LOCK TABLES `filing` WRITE;
/*!40000 ALTER TABLE `filing` DISABLE KEYS */;
INSERT INTO `filing` VALUES (1,1,'GSTR-1','GSTR-1 — outward supplies incl. exports','GST','MONTHLY','Jul 2026','2026-08-11','Tax executive','Finance controller','IN_PROGRESS'),(2,1,'SOFTEX','Softex / services realisation statement','RBI via AD bank','MONTHLY','Jul 2026','2026-08-15','Trade finance officer','Finance controller','NOT_STARTED'),(3,1,'IEC-CONF','IEC annual confirmation','DGFT','ANNUAL','FY27','2026-06-30','Compliance officer','Compliance officer','FILED');
/*!40000 ALTER TABLE `filing` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `freight_container`
--

DROP TABLE IF EXISTS `freight_container`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `freight_container` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `container_no` varchar(24) NOT NULL,
  `size_type` varchar(16) DEFAULT NULL,
  `shipment_no` varchar(40) DEFAULT NULL,
  `seal_no` varchar(30) DEFAULT NULL,
  `gross_weight_kg` decimal(14,2) NOT NULL DEFAULT '0.00',
  `free_time_days` int NOT NULL DEFAULT '0',
  `demurrage` decimal(16,2) NOT NULL DEFAULT '0.00',
  `status` varchar(24) NOT NULL DEFAULT 'IN_TRANSIT',
  PRIMARY KEY (`id`),
  KEY `ix_fcontainer_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `freight_container`
--

LOCK TABLES `freight_container` WRITE;
/*!40000 ALTER TABLE `freight_container` DISABLE KEYS */;
INSERT INTO `freight_container` VALUES (1,1,'MSKU7788112','40HC','SHP-2026-04471','SL-449120',21450.00,7,0.00,'GATED_OUT'),(2,1,'HLXU5540221','20GP','SHP-2026-04488','SL-551903',9800.00,5,18500.00,'AT_PORT'),(3,1,'TCLU9903471','40GP','SHP-2026-04502','SL-660145',18320.00,10,0.00,'IN_TRANSIT');
/*!40000 ALTER TABLE `freight_container` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fx_position`
--

DROP TABLE IF EXISTS `fx_position`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fx_position` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `ref_no` varchar(40) NOT NULL,
  `as_of` date NOT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `exposure_type` varchar(24) DEFAULT NULL,
  `gross_exposure` decimal(18,2) NOT NULL DEFAULT '0.00',
  `hedged_amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `forward_rate` decimal(16,6) NOT NULL DEFAULT '0.000000',
  `maturity_on` date DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (`id`),
  KEY `ix_fx_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fx_position`
--

LOCK TABLES `fx_position` WRITE;
/*!40000 ALTER TABLE `fx_position` DISABLE KEYS */;
INSERT INTO `fx_position` VALUES (1,1,'FX-2026-0071','2026-07-31','USD','RECEIVABLE',499000.00,300000.00,84.150000,'2026-10-31','PART_HEDGED'),(2,1,'FX-2026-0072','2026-07-31','EUR','RECEIVABLE',61200.00,61200.00,92.400000,'2026-09-13','HEDGED'),(3,1,'FX-2026-0073','2026-07-31','USD','PAYABLE',220000.00,0.00,0.000000,'2026-09-05','OPEN');
/*!40000 ALTER TABLE `fx_position` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fx_rate`
--

DROP TABLE IF EXISTS `fx_rate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fx_rate` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `rate_type` enum('ACCOUNTING','CUSTOMS','CLOSING','SETTLEMENT','FORWARD') NOT NULL,
  `from_ccy` char(3) NOT NULL,
  `to_ccy` char(3) NOT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `rate` decimal(18,8) NOT NULL,
  `source` varchar(60) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fx` (`rate_type`,`from_ccy`,`to_ccy`,`valid_from`),
  KEY `ix_fx_lookup` (`from_ccy`,`to_ccy`,`rate_type`,`valid_from` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fx_rate`
--

LOCK TABLES `fx_rate` WRITE;
/*!40000 ALTER TABLE `fx_rate` DISABLE KEYS */;
/*!40000 ALTER TABLE `fx_rate` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gl_account`
--

DROP TABLE IF EXISTS `gl_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gl_account` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(200) NOT NULL,
  `account_class` enum('ASSET','LIABILITY','EQUITY','INCOME','EXPENSE') NOT NULL,
  `account_type` enum('ORDINARY','CONTROL','CLEARING','MEMORANDUM','STATISTICAL') NOT NULL DEFAULT 'ORDINARY',
  `account_group` varchar(80) NOT NULL,
  `schedule_iii_group` varchar(160) DEFAULT NULL,
  `cash_flow_class` enum('OPERATING','INVESTING','FINANCING','NONE') NOT NULL DEFAULT 'NONE',
  `subledger` enum('NONE','AP','AR','BANK','INVENTORY','TAX','ASSET','INSTRUMENT','ENTITLEMENT','BONDED','OBLIGATION') NOT NULL DEFAULT 'NONE',
  `is_monetary` tinyint(1) NOT NULL DEFAULT '0',
  `manual_posting_allowed` tinyint(1) NOT NULL DEFAULT '0',
  `mandatory_dimensions` varchar(200) NOT NULL DEFAULT '',
  `recon_frequency` enum('NONE','DAILY','WEEKLY','MONTHLY','QUARTERLY') NOT NULL DEFAULT 'NONE',
  `currency` char(3) DEFAULT NULL,
  `is_blocked` tinyint(1) NOT NULL DEFAULT '0',
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_account` (`entity_id`,`code`),
  KEY `ix_account_group` (`entity_id`,`account_group`),
  KEY `ix_account_type` (`entity_id`,`account_type`),
  KEY `ix_account_subledger` (`entity_id`,`subledger`),
  CONSTRAINT `fk_acct_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gl_account`
--

LOCK TABLES `gl_account` WRITE;
/*!40000 ALTER TABLE `gl_account` DISABLE KEYS */;
INSERT INTO `gl_account` VALUES (1,1,'1201001','Bank — current account','ASSET','CONTROL','Cash and cash equivalents','Current assets › Cash and cash equivalents','NONE','BANK',1,0,'entity','DAILY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.127','2026-08-05 13:02:21.127'),(2,1,'1201004','Bank — EEFC foreign currency account','ASSET','CONTROL','Cash and cash equivalents','Current assets › Cash and cash equivalents','NONE','BANK',1,0,'entity,currency','DAILY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.132','2026-08-05 13:02:21.132'),(3,1,'1301001','Trade receivables — export debtors','ASSET','CONTROL','Trade receivables','Current assets › Trade receivables','OPERATING','AR',1,0,'entity,party,currency','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.134','2026-08-05 13:02:21.134'),(4,1,'1307001','Entitlement receivable — RoDTEP','ASSET','CONTROL','Other current assets','Current assets › Other current assets','OPERATING','ENTITLEMENT',1,0,'entity,scheme,declaration','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.136','2026-08-05 13:02:21.136'),(5,1,'1308001','Duty credit scrip ledger','ASSET','CONTROL','Other current assets','Current assets › Other current assets','OPERATING','ENTITLEMENT',0,0,'entity,scheme','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.138','2026-08-05 13:02:21.138'),(6,1,'1401001','Inventory — raw material (imported)','ASSET','CONTROL','Inventories','Current assets › Inventories','OPERATING','INVENTORY',0,0,'entity,site,item,lot','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.140','2026-08-05 13:02:21.140'),(7,1,'1403001','Goods in transit — imports','ASSET','ORDINARY','Inventories','Current assets › Inventories','OPERATING','NONE',0,0,'entity,shipment','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.142','2026-08-05 13:02:21.142'),(8,1,'1405002','IGST on imports — credit receivable','ASSET','CONTROL','Duties and taxes','Current assets › Other current assets','OPERATING','TAX',1,0,'entity,declaration,taxCode','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.144','2026-08-05 13:02:21.144'),(9,1,'2101001','Trade payables — foreign suppliers','LIABILITY','CONTROL','Trade payables','Current liabilities › Trade payables','OPERATING','AP',1,0,'entity,party,currency','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.146','2026-08-05 13:02:21.146'),(10,1,'2101003','Trade payables — service providers','LIABILITY','CONTROL','Trade payables','Current liabilities › Trade payables','OPERATING','AP',0,0,'entity,party','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.148','2026-08-05 13:02:21.148'),(11,1,'2103001','Customs duty and levies payable','LIABILITY','ORDINARY','Duties and taxes','Current liabilities › Other current liabilities','OPERATING','NONE',0,0,'entity,declaration','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.151','2026-08-05 13:02:21.151'),(12,1,'2109001','Landed cost clearing — freight','LIABILITY','CLEARING','Clearing and suspense','Current liabilities › Other current liabilities','OPERATING','NONE',0,0,'entity,shipment,chargeType','WEEKLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.153','2026-08-05 13:02:21.153'),(13,1,'2109002','Landed cost clearing — duty','LIABILITY','CLEARING','Clearing and suspense','Current liabilities › Other current liabilities','OPERATING','NONE',0,0,'entity,shipment','WEEKLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.155','2026-08-05 13:02:21.155'),(14,1,'2109003','Landed cost clearing — port and brokerage','LIABILITY','CLEARING','Clearing and suspense','Current liabilities › Other current liabilities','OPERATING','NONE',0,0,'entity,shipment','WEEKLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.157','2026-08-05 13:02:21.157'),(15,1,'2109009','Goods received / invoice received clearing','LIABILITY','CLEARING','Clearing and suspense','Current liabilities › Other current liabilities','OPERATING','NONE',0,0,'entity,shipment','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.159','2026-08-05 13:02:21.159'),(16,1,'2105001','Tax deducted at source payable','LIABILITY','CONTROL','Duties and taxes','Current liabilities › Other current liabilities','OPERATING','TAX',0,0,'entity,party,section','MONTHLY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.161','2026-08-05 13:02:21.161'),(17,1,'4101002','Revenue from exports','INCOME','ORDINARY','Revenue from operations','Revenue from operations','OPERATING','NONE',0,0,'entity,segment,customer','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.163','2026-08-05 13:02:21.163'),(18,1,'4301001','Other operating income — export entitlements','INCOME','ORDINARY','Other income','Other income','OPERATING','NONE',0,1,'entity,scheme','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.165','2026-08-05 13:02:21.165'),(19,1,'5101001','Cost of materials consumed','EXPENSE','ORDINARY','Cost of materials','Cost of materials consumed','OPERATING','NONE',0,0,'entity,site,item','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.167','2026-08-05 13:02:21.167'),(20,1,'5109001','Landed cost variance','EXPENSE','ORDINARY','Cost of materials','Cost of materials consumed','OPERATING','NONE',0,1,'entity,shipment','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.169','2026-08-05 13:02:21.169'),(21,1,'5203001','Demurrage and detention','EXPENSE','ORDINARY','Other expenses','Other expenses','OPERATING','NONE',0,0,'entity,shipment,rootCause','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.171','2026-08-05 13:02:21.171'),(22,1,'5301001','Exchange difference — realised','EXPENSE','ORDINARY','Finance and other','Other expenses','OPERATING','NONE',0,1,'entity,currency','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.174','2026-08-05 13:02:21.174'),(23,1,'5301002','Exchange difference — unrealised','EXPENSE','ORDINARY','Finance and other','Other expenses','OPERATING','NONE',0,0,'entity,currency','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.178','2026-08-05 13:02:21.178'),(24,1,'5302001','Bank charges — trade','EXPENSE','ORDINARY','Finance and other','Finance costs','FINANCING','NONE',0,0,'entity,instrument','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.180','2026-08-05 13:02:21.180'),(25,1,'9101001','Memorandum — deferred duty on bonded stock','LIABILITY','MEMORANDUM','Memorandum','Contingent liabilities (note)','NONE','NONE',0,0,'entity,declaration,lot','DAILY',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.182','2026-08-05 13:02:21.182'),(26,1,'3101001','Equity share capital','EQUITY','ORDINARY','Equity','Equity › Equity share capital','FINANCING','NONE',0,0,'entity','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.184','2026-08-05 13:02:21.184'),(27,1,'3201001','Other equity — retained earnings','EQUITY','ORDINARY','Equity','Equity › Other equity','NONE','NONE',0,0,'entity','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.186','2026-08-05 13:02:21.186'),(28,1,'3201009','Other equity — profit and loss for the period','EQUITY','ORDINARY','Equity','Equity › Other equity','NONE','NONE',0,0,'entity','NONE',NULL,0,'2020-04-01',NULL,1,'2026-08-05 13:02:21.188','2026-08-05 13:02:21.188');
/*!40000 ALTER TABLE `gl_account` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `goods_receipt`
--

DROP TABLE IF EXISTS `goods_receipt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `goods_receipt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `grn_no` varchar(40) NOT NULL,
  `grn_date` date NOT NULL,
  `shipment_no` varchar(40) DEFAULT NULL,
  `supplier` varchar(160) DEFAULT NULL,
  `warehouse` varchar(80) DEFAULT NULL,
  `line_count` int NOT NULL DEFAULT '0',
  `value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `currency` varchar(3) NOT NULL DEFAULT 'INR',
  `status` varchar(24) NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (`id`),
  KEY `ix_grn_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `goods_receipt`
--

LOCK TABLES `goods_receipt` WRITE;
/*!40000 ALTER TABLE `goods_receipt` DISABLE KEYS */;
INSERT INTO `goods_receipt` VALUES (1,1,'GRN-2026-0331','2026-07-18','SHP-2026-04471','Hanwha Precision Co','Pune Unit I',5,1846500.00,'INR','POSTED'),(2,1,'GRN-2026-0342','2026-07-26','SHP-2026-04488','Zhejiang Fastener Works','Pune Unit I',2,512000.00,'INR','DISCREPANCY'),(3,1,'GRN-2026-0350','2026-08-01','SHP-2026-04502','Bosch Rexroth AG','Chakan Store',3,2210400.00,'INR','DRAFT');
/*!40000 ALTER TABLE `goods_receipt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hs_code`
--

DROP TABLE IF EXISTS `hs_code`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hs_code` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `jurisdiction` char(2) NOT NULL,
  `code` varchar(12) NOT NULL,
  `description` varchar(500) NOT NULL,
  `statutory_uom` varchar(10) NOT NULL,
  `chapter` char(2) NOT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `pack_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hs` (`jurisdiction`,`code`,`valid_from`),
  KEY `ix_hs_code` (`code`),
  KEY `ix_hs_chapter` (`jurisdiction`,`chapter`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hs_code`
--

LOCK TABLES `hs_code` WRITE;
/*!40000 ALTER TABLE `hs_code` DISABLE KEYS */;
/*!40000 ALTER TABLE `hs_code` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `incoterm`
--

DROP TABLE IF EXISTS `incoterm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incoterm` (
  `code` char(3) NOT NULL,
  `name` varchar(80) NOT NULL,
  `modes` varchar(30) NOT NULL,
  `risk_transfer` varchar(120) NOT NULL,
  `freight_in_value` tinyint(1) NOT NULL,
  `insurance_by_seller` tinyint(1) NOT NULL,
  `import_cleared_by` enum('BUYER','SELLER') NOT NULL,
  `ownership_event` varchar(40) NOT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incoterm`
--

LOCK TABLES `incoterm` WRITE;
/*!40000 ALTER TABLE `incoterm` DISABLE KEYS */;
INSERT INTO `incoterm` VALUES ('CFR','Cost and Freight','SEA','On board at port of loading',1,0,'BUYER','onBoard'),('CIF','Cost, Insurance and Freight','SEA','On board at port of loading',1,1,'BUYER','onBoard'),('CIP','Carriage and Insurance Paid To','ANY','On handover to first carrier',1,1,'BUYER','onHandover'),('CPT','Carriage Paid To','ANY','On handover to first carrier',1,0,'BUYER','onHandover'),('DAP','Delivered At Place','ANY','At named place, not unloaded',1,0,'BUYER','atDelivery'),('DDP','Delivered Duty Paid','ANY','At named place, cleared',1,0,'SELLER','atDelivery'),('DPU','Delivered At Place Unloaded','ANY','At named place, unloaded',1,0,'BUYER','atDelivery'),('EXW','Ex Works','ANY','At seller premises',0,0,'BUYER','atCollection'),('FCA','Free Carrier','ANY','On handover to carrier',0,0,'BUYER','onHandover'),('FOB','Free On Board','SEA','On board at port of loading',0,0,'BUYER','onBoard');
/*!40000 ALTER TABLE `incoterm` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `indent`
--

DROP TABLE IF EXISTS `indent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `indent` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `indent_no` varchar(40) NOT NULL,
  `indent_date` date NOT NULL,
  `item_desc` varchar(240) NOT NULL,
  `qty` decimal(18,3) NOT NULL DEFAULT '0.000',
  `uom` varchar(12) NOT NULL DEFAULT 'PCS',
  `required_by` date DEFAULT NULL,
  `cost_centre` varchar(40) DEFAULT NULL,
  `precheck_status` varchar(24) NOT NULL DEFAULT 'PENDING',
  `status` varchar(24) NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (`id`),
  KEY `ix_indent_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `indent`
--

LOCK TABLES `indent` WRITE;
/*!40000 ALTER TABLE `indent` DISABLE KEYS */;
INSERT INTO `indent` VALUES (1,1,'IND-2026-0412','2026-05-20','HPB-4410 Precision bearing, sealed',4000.000,'PCS','2026-07-15','CC-PROD-01','ALLOWED','CONVERTED'),(2,1,'IND-2026-0455','2026-06-28','NC-2208 Servo controller card',120.000,'PCS','2026-08-10','CC-MAINT-02','WARNING','CONVERTED'),(3,1,'IND-2026-0478','2026-07-14','ZF-1100 Hex bolt, grade 8.8',240000.000,'PCS','2026-08-30','CC-PROD-02','BLOCKED','SUBMITTED'),(4,1,'IND-2026-0490','2026-07-30','HPB-4430 Spindle assembly',600.000,'PCS','2026-09-15','CC-PROD-01','ALLOWED','APPROVED');
/*!40000 ALTER TABLE `indent` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `instrument`
--

DROP TABLE IF EXISTS `instrument`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `instrument` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `instrument_no` varchar(40) NOT NULL,
  `instrument_type` enum('LC_IMPORT','LC_EXPORT','SBLC','BG','DOC_COLLECTION','OPEN_ACCOUNT','ADVANCE','BUYERS_CREDIT','PACKING_CREDIT') NOT NULL,
  `governing_rules` varchar(40) DEFAULT NULL,
  `issuing_bank_id` bigint unsigned DEFAULT NULL,
  `issuing_bank_name` varchar(160) DEFAULT NULL,
  `advising_bank_id` bigint unsigned DEFAULT NULL,
  `advising_bank_name` varchar(160) DEFAULT NULL,
  `applicant_party_id` bigint unsigned DEFAULT NULL,
  `applicant_name` varchar(200) DEFAULT NULL,
  `beneficiary_party_id` bigint unsigned DEFAULT NULL,
  `beneficiary_name` varchar(200) DEFAULT NULL,
  `currency` char(3) NOT NULL,
  `face_value` decimal(20,4) NOT NULL,
  `tolerance_pct` decimal(9,4) NOT NULL DEFAULT '0.0000',
  `drawn_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `available_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `charges_to_date` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `issued_on` date DEFAULT NULL,
  `latest_shipment_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `presentation_days` smallint unsigned NOT NULL DEFAULT '21',
  `payment_terms` varchar(120) DEFAULT NULL,
  `usance_days` smallint unsigned DEFAULT NULL,
  `status` enum('DRAFT','APPLIED','ISSUED','AMENDED','PRESENTED','ACCEPTED','PART_DRAWN','SETTLED','EXPIRED','CANCELLED','DISHONOURED') NOT NULL DEFAULT 'DRAFT',
  `margin_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `contingent_disclosed` tinyint(1) NOT NULL DEFAULT '0',
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `type_label` varchar(120) DEFAULT NULL,
  `status_label` varchar(80) DEFAULT NULL,
  `payment_note` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_instr` (`entity_id`,`instrument_no`),
  KEY `ix_instr_type` (`entity_id`,`instrument_type`,`status`),
  KEY `ix_instr_expiry` (`entity_id`,`expiry_date`),
  KEY `ix_instr_bank` (`entity_id`,`issuing_bank_id`),
  KEY `fk_ins_issuing` (`issuing_bank_id`),
  KEY `fk_ins_advising` (`advising_bank_id`),
  CONSTRAINT `fk_ins_advising` FOREIGN KEY (`advising_bank_id`) REFERENCES `trade_party` (`id`),
  CONSTRAINT `fk_ins_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`),
  CONSTRAINT `fk_ins_issuing` FOREIGN KEY (`issuing_bank_id`) REFERENCES `trade_party` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instrument`
--

LOCK TABLES `instrument` WRITE;
/*!40000 ALTER TABLE `instrument` DISABLE KEYS */;
INSERT INTO `instrument` VALUES (1,1,'LC/2026/0731','LC_IMPORT','UCP 600',11,'State Bank of India, Mumbai',12,'Woori Bank, Seoul',NULL,'HostBooks Manufacturing Ltd',NULL,'Hanyang Precision Co Ltd','USD',200000.0000,5.0000,184500.0000,25500.0000,42800.0000,NULL,'2026-06-30','2026-07-21',21,'60 days from bill of lading date',NULL,'ISSUED',0.0000,0,1,'2026-08-05 13:02:21.328','2026-08-05 13:02:21.328','Import documentary credit — usance 60 days','Drawn — accepted','60 days from bill of lading date'),(2,1,'LC/2026/0918','LC_EXPORT','UCP 600',13,'Commerzbank AG, Hamburg',14,'HDFC Bank, Mumbai',5,'Meridian Industries GmbH',NULL,'HostBooks Manufacturing Ltd','EUR',350000.0000,5.0000,0.0000,350000.0000,0.0000,NULL,'2026-08-10','2026-08-31',21,'At sight',NULL,'ISSUED',0.0000,0,1,'2026-08-05 13:02:21.336','2026-08-05 13:02:21.336','Export documentary credit — at sight','Documents prepared — not presented','At sight');
/*!40000 ALTER TABLE `instrument` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `instrument_discrepancy`
--

DROP TABLE IF EXISTS `instrument_discrepancy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `instrument_discrepancy` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `instrument_id` bigint unsigned NOT NULL,
  `presentation_id` bigint unsigned DEFAULT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(30) NOT NULL,
  `description` varchar(500) NOT NULL,
  `disposition` enum('OPEN','CORRECTED','WAIVER_SOUGHT','WAIVED','ACCEPTED_UNDER_RESERVE','REFUSED') NOT NULL DEFAULT 'OPEN',
  `outcome` varchar(300) DEFAULT NULL,
  `raised_on` date DEFAULT NULL,
  `resolved_on` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_idsc_instr` (`instrument_id`,`disposition`),
  KEY `ix_idsc_pres` (`presentation_id`),
  CONSTRAINT `fk_idsc_instr` FOREIGN KEY (`instrument_id`) REFERENCES `instrument` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_idsc_pres` FOREIGN KEY (`presentation_id`) REFERENCES `instrument_presentation` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instrument_discrepancy`
--

LOCK TABLES `instrument_discrepancy` WRITE;
/*!40000 ALTER TABLE `instrument_discrepancy` DISABLE KEYS */;
INSERT INTO `instrument_discrepancy` VALUES (1,2,NULL,1,'CERT-UNSIGNED','Beneficiary certificate not signed as the credit requires','OPEN','Correct and re-present',NULL,NULL);
/*!40000 ALTER TABLE `instrument_discrepancy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `instrument_doc_requirement`
--

DROP TABLE IF EXISTS `instrument_doc_requirement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `instrument_doc_requirement` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `instrument_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `seq` smallint unsigned NOT NULL,
  `doc_type` varchar(60) NOT NULL,
  `originals` tinyint unsigned NOT NULL DEFAULT '1',
  `copies` tinyint unsigned NOT NULL DEFAULT '0',
  `issuer` varchar(120) DEFAULT NULL,
  `required_wording` varchar(1000) DEFAULT NULL,
  `is_held` tinyint(1) NOT NULL DEFAULT '0',
  `held_doc_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_idr` (`instrument_id`,`seq`),
  KEY `ix_idr_held` (`instrument_id`,`is_held`),
  CONSTRAINT `fk_idr_instr` FOREIGN KEY (`instrument_id`) REFERENCES `instrument` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instrument_doc_requirement`
--

LOCK TABLES `instrument_doc_requirement` WRITE;
/*!40000 ALTER TABLE `instrument_doc_requirement` DISABLE KEYS */;
INSERT INTO `instrument_doc_requirement` VALUES (1,1,1,1,'Commercial invoice',3,3,'Beneficiary',NULL,1,NULL),(2,1,1,2,'Packing list',3,3,'Beneficiary',NULL,1,NULL),(3,1,1,3,'Full set bill of lading marked freight prepaid',3,3,'Carrier',NULL,1,NULL),(4,1,1,4,'Certificate of origin',1,2,'Chamber of commerce',NULL,1,NULL),(5,1,1,5,'Insurance certificate for 110% of CIF value',2,1,'Insurer',NULL,1,NULL),(6,2,1,1,'Signed commercial invoice',3,3,'Beneficiary',NULL,1,NULL),(7,2,1,2,'Packing list',3,3,'Beneficiary',NULL,1,NULL),(8,2,1,3,'Full set clean on-board bill of lading',3,3,'Carrier',NULL,1,NULL),(9,2,1,4,'Certificate of origin — non-preferential',1,2,'Chamber of commerce',NULL,1,NULL),(10,2,1,5,'Beneficiary certificate confirming courier of documents',1,1,'Beneficiary','We certify that one set of non-negotiable documents has been couriered to the applicant within 3 days of shipment',0,NULL),(11,2,1,6,'Inspection certificate',1,1,'SGS',NULL,1,NULL);
/*!40000 ALTER TABLE `instrument_doc_requirement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `instrument_presentation`
--

DROP TABLE IF EXISTS `instrument_presentation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `instrument_presentation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `instrument_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `presentation_no` smallint unsigned NOT NULL,
  `shipment_id` bigint unsigned DEFAULT NULL,
  `presented_on` date DEFAULT NULL,
  `due_by` date DEFAULT NULL,
  `amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `status` enum('PREPARING','PRESENTED','DISCREPANT','ACCEPTED','PAID','REFUSED') NOT NULL DEFAULT 'PREPARING',
  `outcome_note` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ip` (`instrument_id`,`presentation_no`),
  KEY `ix_ip_due` (`entity_id`,`due_by`,`status`),
  KEY `ix_ip_shipment` (`shipment_id`),
  CONSTRAINT `fk_ip_instr` FOREIGN KEY (`instrument_id`) REFERENCES `instrument` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ip_shp` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instrument_presentation`
--

LOCK TABLES `instrument_presentation` WRITE;
/*!40000 ALTER TABLE `instrument_presentation` DISABLE KEYS */;
/*!40000 ALTER TABLE `instrument_presentation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `insurance_policy`
--

DROP TABLE IF EXISTS `insurance_policy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `insurance_policy` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `policy_no` varchar(40) NOT NULL,
  `insurer` varchar(160) DEFAULT NULL,
  `cover_type` varchar(60) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'INR',
  `sum_insured` decimal(18,2) NOT NULL DEFAULT '0.00',
  `premium` decimal(16,2) NOT NULL DEFAULT '0.00',
  `valid_from` date DEFAULT NULL,
  `valid_to` date DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`id`),
  KEY `ix_inspol_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `insurance_policy`
--

LOCK TABLES `insurance_policy` WRITE;
/*!40000 ALTER TABLE `insurance_policy` DISABLE KEYS */;
INSERT INTO `insurance_policy` VALUES (1,1,'MOP-2026-0031','New India Assurance','MARINE_OPEN','INR',50000000.00,185000.00,'2026-04-01','2027-03-31','ACTIVE'),(2,1,'MSP-2026-0442','ICICI Lombard','MARINE_SPECIFIC','INR',2100000.00,8400.00,'2026-07-05','2026-09-05','ACTIVE'),(3,1,'AIR-2026-0119','Tata AIG','AIR','INR',950000.00,5200.00,'2026-07-20','2026-08-20','CLAIMED');
/*!40000 ALTER TABLE `insurance_policy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `integration_log`
--

DROP TABLE IF EXISTS `integration_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `integration_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `channel` enum('ICEGATE','EDPMS','BANK_HOST','DGFT','GSTN') NOT NULL,
  `direction` enum('OUT','IN') NOT NULL,
  `object_type` varchar(40) NOT NULL,
  `object_id` bigint unsigned DEFAULT NULL,
  `object_ref` varchar(60) DEFAULT NULL,
  `message_type` varchar(40) NOT NULL,
  `request_ref` varchar(60) DEFAULT NULL,
  `gateway_ref` varchar(60) DEFAULT NULL,
  `status` enum('QUEUED','SENT','ACKED','ACCEPTED','QUERIED','REJECTED','ERROR') NOT NULL DEFAULT 'QUEUED',
  `status_detail` varchar(600) DEFAULT NULL,
  `request_summary` varchar(1000) DEFAULT NULL,
  `response_summary` varchar(1000) DEFAULT NULL,
  `attempts` smallint unsigned NOT NULL DEFAULT '1',
  `simulated` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `ix_intlog_channel` (`entity_id`,`channel`,`created_at`),
  KEY `ix_intlog_object` (`entity_id`,`object_type`,`object_id`),
  KEY `ix_intlog_status` (`entity_id`,`status`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `integration_log`
--

LOCK TABLES `integration_log` WRITE;
/*!40000 ALTER TABLE `integration_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `integration_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item`
--

DROP TABLE IF EXISTS `item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `item` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `item_code` varchar(40) NOT NULL,
  `description` varchar(300) NOT NULL,
  `statutory_description` varchar(500) DEFAULT NULL,
  `stock_uom` varchar(10) NOT NULL,
  `valuation_method` enum('WAVG','FIFO','STANDARD') NOT NULL DEFAULT 'WAVG',
  `item_group` varchar(60) DEFAULT NULL,
  `net_weight_kg` decimal(20,6) DEFAULT NULL,
  `gross_weight_kg` decimal(20,6) DEFAULT NULL,
  `volume_cbm` decimal(20,6) DEFAULT NULL,
  `is_capital_good` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_item` (`entity_id`,`item_code`),
  KEY `ix_item_desc` (`entity_id`,`description`(80)),
  KEY `ix_item_group` (`entity_id`,`item_group`),
  CONSTRAINT `fk_item_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item`
--

LOCK TABLES `item` WRITE;
/*!40000 ALTER TABLE `item` DISABLE KEYS */;
INSERT INTO `item` VALUES (1,1,'HPB-4400','Bearing housing, cast steel',NULL,'EA','WAVG',NULL,2480.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.284','2026-08-05 13:02:21.284'),(2,1,'HPB-4410','Precision bearing, sealed',NULL,'EA','WAVG',NULL,1240.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.287','2026-08-05 13:02:21.287'),(3,1,'HPB-4420','Seal kit, nitrile',NULL,'EA','WAVG',NULL,1020.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.287','2026-08-05 13:02:21.287'),(4,1,'HPB-4430','Spindle assembly',NULL,'EA','WAVG',NULL,1210.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.288','2026-08-05 13:02:21.288'),(5,1,'FIN-8801','Machined gearbox housing',NULL,'EA','WAVG',NULL,5400.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.289','2026-08-05 13:02:21.289'),(6,1,'FIN-8815','Drive shaft, hardened',NULL,'EA','WAVG',NULL,3920.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.290','2026-08-05 13:02:21.290'),(7,1,'NC-2201','Hydraulic valve block',NULL,'EA','WAVG',NULL,890.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.291','2026-08-05 13:02:21.291'),(8,1,'NC-2208','Servo controller card',NULL,'EA','WAVG',NULL,96.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.291','2026-08-05 13:02:21.291'),(9,1,'FIN-9002','Pump assembly, industrial',NULL,'EA','WAVG',NULL,2880.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.292','2026-08-05 13:02:21.292'),(10,1,'ZF-1100','Hex bolt, grade 8.8',NULL,'EA','WAVG',NULL,4100.000000,NULL,NULL,0,1,1,'2026-08-05 13:02:21.293','2026-08-05 13:02:21.293');
/*!40000 ALTER TABLE `item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_permit_requirement`
--

DROP TABLE IF EXISTS `item_permit_requirement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `item_permit_requirement` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `item_id` bigint unsigned NOT NULL,
  `agency` varchar(60) NOT NULL,
  `permit_type` varchar(80) NOT NULL,
  `lead_time_days` smallint unsigned NOT NULL DEFAULT '7',
  PRIMARY KEY (`id`),
  KEY `ix_ipr_item` (`item_id`),
  CONSTRAINT `fk_ipr_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_permit_requirement`
--

LOCK TABLES `item_permit_requirement` WRITE;
/*!40000 ALTER TABLE `item_permit_requirement` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_permit_requirement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_trade_attr`
--

DROP TABLE IF EXISTS `item_trade_attr`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `item_trade_attr` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `item_id` bigint unsigned NOT NULL,
  `jurisdiction` char(2) NOT NULL,
  `direction` enum('IMPORT','EXPORT') NOT NULL,
  `hs_code` varchar(12) NOT NULL,
  `statutory_uom` varchar(10) NOT NULL,
  `uom_conversion` decimal(20,8) NOT NULL DEFAULT '1.00000000',
  `default_origin` char(2) DEFAULT NULL,
  `restriction` enum('FREE','RESTRICTED','PROHIBITED','STATE_TRADING','CONDITIONAL') NOT NULL DEFAULT 'FREE',
  `classification_basis` varchar(600) DEFAULT NULL,
  `approved_by` bigint unsigned DEFAULT NULL,
  `approved_at` datetime(3) DEFAULT NULL,
  `status` enum('DRAFT','APPROVED','RECLASSIFY') NOT NULL DEFAULT 'DRAFT',
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ita` (`item_id`,`jurisdiction`,`direction`,`valid_from`),
  KEY `ix_ita_hs` (`jurisdiction`,`hs_code`),
  KEY `ix_ita_status` (`status`),
  CONSTRAINT `fk_ita_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_trade_attr`
--

LOCK TABLES `item_trade_attr` WRITE;
/*!40000 ALTER TABLE `item_trade_attr` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_trade_attr` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `legal_entity`
--

DROP TABLE IF EXISTS `legal_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `legal_entity` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `name` varchar(200) NOT NULL,
  `country_code` char(2) NOT NULL,
  `functional_ccy` char(3) NOT NULL,
  `group_ccy` char(3) NOT NULL DEFAULT 'INR',
  `gaap_framework` enum('IND_AS','AS','IFRS') NOT NULL DEFAULT 'IND_AS',
  `iec` varchar(20) DEFAULT NULL,
  `pan` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_legal_entity_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `legal_entity`
--

LOCK TABLES `legal_entity` WRITE;
/*!40000 ALTER TABLE `legal_entity` DISABLE KEYS */;
INSERT INTO `legal_entity` VALUES (1,'ACME','Acme Trading Ltd','IN','INR','INR','IND_AS','0611022233','AACCA5678M',1,'2026-08-05 13:02:21.108','2026-08-05 13:02:21.108');
/*!40000 ALTER TABLE `legal_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `levy_definition`
--

DROP TABLE IF EXISTS `levy_definition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `levy_definition` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `jurisdiction` char(2) NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(120) NOT NULL,
  `calc_type` enum('ADVALOREM','SPECIFIC','COMPOUND','HIGHER_OF') NOT NULL,
  `base_expr` varchar(200) NOT NULL,
  `seq_no` smallint unsigned NOT NULL,
  `default_rate` decimal(10,4) NOT NULL DEFAULT '0.0000',
  `rate_per_unit` decimal(18,6) DEFAULT NULL,
  `recoverable` tinyint(1) NOT NULL DEFAULT '0',
  `round_dp` tinyint unsigned NOT NULL DEFAULT '2',
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_levy` (`jurisdiction`,`code`,`valid_from`),
  KEY `ix_levy_active` (`jurisdiction`,`valid_from`,`seq_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `levy_definition`
--

LOCK TABLES `levy_definition` WRITE;
/*!40000 ALTER TABLE `levy_definition` DISABLE KEYS */;
/*!40000 ALTER TABLE `levy_definition` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `levy_rate`
--

DROP TABLE IF EXISTS `levy_rate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `levy_rate` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `jurisdiction` char(2) NOT NULL,
  `levy_code` varchar(20) NOT NULL,
  `hs_code` varchar(12) NOT NULL,
  `origin_code` char(2) DEFAULT NULL,
  `rate_pct` decimal(10,4) NOT NULL,
  `rate_per_unit` decimal(18,6) DEFAULT NULL,
  `notification_ref` varchar(60) DEFAULT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_levy_rate_lookup` (`jurisdiction`,`hs_code`,`levy_code`,`valid_from` DESC),
  KEY `ix_levy_rate_origin` (`jurisdiction`,`hs_code`,`origin_code`,`valid_from` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `levy_rate`
--

LOCK TABLES `levy_rate` WRITE;
/*!40000 ALTER TABLE `levy_rate` DISABLE KEYS */;
/*!40000 ALTER TABLE `levy_rate` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `licence`
--

DROP TABLE IF EXISTS `licence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licence` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `scheme_id` bigint unsigned NOT NULL,
  `licence_no` varchar(40) NOT NULL,
  `issued_on` date NOT NULL,
  `issuing_authority` varchar(120) DEFAULT NULL,
  `import_valid_to` date DEFAULT NULL,
  `export_valid_to` date DEFAULT NULL,
  `status` enum('APPLIED','ISSUED','ACTIVE','SUSPENDED','OBLIGATION_MET','REDEEMED','DEFAULTED','CANCELLED') NOT NULL DEFAULT 'ISSUED',
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `cif_entitlement` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `cif_utilised` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_saved` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `obligation_type` enum('VALUE','QUANTITY','VALUE_ADDITION','NONE') NOT NULL DEFAULT 'VALUE',
  `obligation_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `obligation_fulfilled` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `average_obligation` decimal(20,4) DEFAULT NULL,
  `average_maintained` tinyint(1) DEFAULT NULL,
  `min_value_addition_pct` decimal(9,4) DEFAULT NULL,
  `achieved_value_addition_pct` decimal(9,4) DEFAULT NULL,
  `bond_id` bigint unsigned DEFAULT NULL,
  `bg_waived` tinyint(1) NOT NULL DEFAULT '0',
  `exposure_duty` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `exposure_interest` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `contingent_disclosed` tinyint(1) NOT NULL DEFAULT '0',
  `redeemed_on` date DEFAULT NULL,
  `redemption_ref` varchar(60) DEFAULT NULL,
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `scheme_label` varchar(120) DEFAULT NULL,
  `obligation_label` varchar(160) DEFAULT NULL,
  `status_label` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_licence` (`entity_id`,`licence_no`),
  KEY `ix_lic_scheme` (`entity_id`,`scheme_id`,`status`),
  KEY `ix_lic_status` (`entity_id`,`status`,`export_valid_to`),
  KEY `ix_lic_exposure` (`entity_id`,`status`,`exposure_duty`),
  KEY `fk_lic_scheme` (`scheme_id`),
  KEY `fk_lic_bond` (`bond_id`),
  CONSTRAINT `fk_lic_bond` FOREIGN KEY (`bond_id`) REFERENCES `bond_register` (`id`),
  CONSTRAINT `fk_lic_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`),
  CONSTRAINT `fk_lic_scheme` FOREIGN KEY (`scheme_id`) REFERENCES `scheme` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `licence`
--

LOCK TABLES `licence` WRITE;
/*!40000 ALTER TABLE `licence` DISABLE KEYS */;
INSERT INTO `licence` VALUES (1,1,1,'EPCG/2024/0117','2024-03-14',NULL,'2026-09-13','2030-03-13','ACTIVE','INR',18460000.0000,18460000.0000,18460000.0000,'VALUE',110760000.0000,50950000.0000,21000000.0000,1,NULL,NULL,NULL,1,2769000.0000,0.0000,1,NULL,NULL,1,'2026-08-05 13:02:21.484','2026-08-05 13:02:21.484','EPCG','6 × duty saved','Open — at risk'),(2,1,2,'AA/2026/0044','2026-02-10',NULL,'2027-02-09','2027-08-09','ACTIVE','INR',2420000.0000,2420000.0000,4820000.0000,'VALUE_ADDITION',28920000.0000,8960000.0000,NULL,NULL,15.0000,NULL,NULL,0,0.0000,0.0000,1,NULL,NULL,1,'2026-08-05 13:02:21.513','2026-08-05 13:02:21.513','Advance Authorisation','Value with 15% minimum value addition','Open'),(3,1,3,'MOOWR/2025/0009','2025-08-01',NULL,'2030-07-31','2030-07-31','ACTIVE','INR',9240000.0000,9240000.0000,9240000.0000,'NONE',0.0000,0.0000,NULL,NULL,NULL,NULL,NULL,0,0.0000,0.0000,0,NULL,NULL,1,'2026-08-05 13:02:21.522','2026-08-05 13:02:21.522','MOOWR bonded manufacturing','None — duty deferred until removal','Open');
/*!40000 ALTER TABLE `licence` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `licence_block`
--

DROP TABLE IF EXISTS `licence_block`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licence_block` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `licence_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `block_no` smallint unsigned NOT NULL,
  `label` varchar(60) NOT NULL,
  `share_pct` decimal(9,4) NOT NULL,
  `due_on` date NOT NULL,
  `obligation_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `fulfilled_amount` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `extended_to` date DEFAULT NULL,
  `extension_ref` varchar(60) DEFAULT NULL,
  `status` enum('OPEN','MET','SHORT','EXTENDED','DEFAULTED') NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lb` (`licence_id`,`block_no`),
  KEY `ix_lb_due` (`entity_id`,`due_on`,`status`),
  CONSTRAINT `fk_lb_licence` FOREIGN KEY (`licence_id`) REFERENCES `licence` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `licence_block`
--

LOCK TABLES `licence_block` WRITE;
/*!40000 ALTER TABLE `licence_block` DISABLE KEYS */;
INSERT INTO `licence_block` VALUES (1,1,1,1,'Block 1 (years 1–4, 50%)',50.0000,'2028-03-13',0.0000,46.0000,NULL,NULL,'OPEN'),(2,1,1,2,'Block 2 (years 5–6, 50%)',50.0000,'2030-03-13',0.0000,0.0000,NULL,NULL,'OPEN'),(3,2,1,1,'Single block (18 months)',100.0000,'2027-08-09',0.0000,31.0000,NULL,NULL,'OPEN'),(4,3,1,1,'No obligation period',100.0000,'2030-07-31',0.0000,100.0000,NULL,NULL,'MET');
/*!40000 ALTER TABLE `licence_block` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `licence_condition`
--

DROP TABLE IF EXISTS `licence_condition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licence_condition` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `licence_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `name` varchar(160) NOT NULL,
  `detail` varchar(600) NOT NULL,
  `is_satisfied` tinyint(1) NOT NULL DEFAULT '0',
  `evidence_doc_id` bigint unsigned DEFAULT NULL,
  `checked_by` bigint unsigned DEFAULT NULL,
  `checked_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_lc_licence` (`licence_id`,`is_satisfied`),
  CONSTRAINT `fk_lc_licence` FOREIGN KEY (`licence_id`) REFERENCES `licence` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `licence_condition`
--

LOCK TABLES `licence_condition` WRITE;
/*!40000 ALTER TABLE `licence_condition` DISABLE KEYS */;
INSERT INTO `licence_condition` VALUES (1,1,1,'Actual user condition','Capital goods installed at the declared premises',1,NULL,NULL,NULL),(2,1,1,'Installation certificate','Certified by chartered engineer on 22-Jun-2024',1,NULL,NULL,NULL),(3,1,1,'Non-transferable','No transfer recorded',1,NULL,NULL,NULL),(4,1,1,'Average export obligation','FY26 exports ₹2,84,00,000 against average ₹2,10,00,000',1,NULL,NULL,NULL),(5,2,1,'Actual user condition','Inputs consumed in own manufacture',1,NULL,NULL,NULL),(6,2,1,'Pre-import condition','Imports precede the corresponding exports',1,NULL,NULL,NULL),(7,2,1,'Minimum value addition 15%','Achieved 12.4% to date — shortfall of 2.6 percentage points',0,NULL,NULL,NULL),(8,3,1,'Licensed premises','Section 65 permission for Unit II',1,NULL,NULL,NULL),(9,3,1,'Bonded stock ledger reconciled','Last reconciled 03-Aug-2026, no difference',1,NULL,NULL,NULL);
/*!40000 ALTER TABLE `licence_condition` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `licence_fulfilment`
--

DROP TABLE IF EXISTS `licence_fulfilment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licence_fulfilment` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `licence_id` bigint unsigned NOT NULL,
  `block_id` bigint unsigned DEFAULT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `entry_date` date NOT NULL,
  `declaration_id` bigint unsigned DEFAULT NULL,
  `reference` varchar(60) NOT NULL,
  `description` varchar(300) NOT NULL,
  `item_id` bigint unsigned DEFAULT NULL,
  `qty` decimal(20,6) DEFAULT NULL,
  `uom` varchar(10) DEFAULT NULL,
  `fob_value` decimal(20,4) NOT NULL,
  `counted_value` decimal(20,4) NOT NULL,
  `running_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `evidence_complete` tinyint(1) NOT NULL DEFAULT '0',
  `brc_ref` varchar(60) DEFAULT NULL,
  `realised_on` date DEFAULT NULL,
  `is_reversal` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `ix_lf_licence` (`licence_id`,`entry_date`,`id`),
  KEY `ix_lf_block` (`block_id`),
  KEY `ix_lf_evidence` (`entity_id`,`evidence_complete`,`entry_date`),
  KEY `ix_lf_dec` (`declaration_id`),
  CONSTRAINT `fk_lf_block` FOREIGN KEY (`block_id`) REFERENCES `licence_block` (`id`),
  CONSTRAINT `fk_lf_licence` FOREIGN KEY (`licence_id`) REFERENCES `licence` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `licence_fulfilment`
--

LOCK TABLES `licence_fulfilment` WRITE;
/*!40000 ALTER TABLE `licence_fulfilment` DISABLE KEYS */;
INSERT INTO `licence_fulfilment` VALUES (1,1,NULL,1,'2025-06-04',NULL,'SB-8841','Gearbox housings to Germany',NULL,NULL,NULL,8420000.0000,8420000.0000,8420000.0000,1,NULL,NULL,0,'2026-08-05 13:02:21.501'),(2,1,NULL,1,'2025-09-19',NULL,'SB-9120','Drive shafts to Netherlands',NULL,NULL,NULL,10260000.0000,10260000.0000,10260000.0000,1,NULL,NULL,0,'2026-08-05 13:02:21.504'),(3,1,NULL,1,'2026-02-28',NULL,'SB-9744','Gearbox assemblies to Germany',NULL,NULL,NULL,14480000.0000,14480000.0000,14480000.0000,1,NULL,NULL,0,'2026-08-05 13:02:21.505'),(4,1,NULL,1,'2026-05-11',2,'SB-0119','Machined housings to Germany',NULL,NULL,NULL,17790000.0000,17790000.0000,17790000.0000,0,NULL,NULL,0,'2026-08-05 13:02:21.506'),(5,2,NULL,1,'2026-05-22',NULL,'SB-0088','Assembled units to Italy',NULL,NULL,NULL,8960000.0000,8960000.0000,8960000.0000,1,NULL,NULL,0,'2026-08-05 13:02:21.518');
/*!40000 ALTER TABLE `licence_fulfilment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `licence_item`
--

DROP TABLE IF EXISTS `licence_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licence_item` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `licence_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `side` enum('IMPORT','EXPORT') NOT NULL,
  `line_no` smallint unsigned NOT NULL,
  `item_id` bigint unsigned DEFAULT NULL,
  `description` varchar(300) NOT NULL,
  `hs_code` varchar(12) DEFAULT NULL,
  `qty_allowed` decimal(20,6) DEFAULT NULL,
  `qty_used` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `uom` varchar(10) DEFAULT NULL,
  `value_allowed` decimal(20,4) DEFAULT NULL,
  `value_used` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `norm_ref` varchar(60) DEFAULT NULL,
  `wastage_pct` decimal(9,4) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_li` (`licence_id`,`side`,`line_no`),
  KEY `ix_li_item` (`entity_id`,`item_id`),
  KEY `fk_li_item` (`item_id`),
  CONSTRAINT `fk_li_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`),
  CONSTRAINT `fk_li_licence` FOREIGN KEY (`licence_id`) REFERENCES `licence` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `licence_item`
--

LOCK TABLES `licence_item` WRITE;
/*!40000 ALTER TABLE `licence_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `licence_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `licence_utilisation`
--

DROP TABLE IF EXISTS `licence_utilisation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `licence_utilisation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `licence_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `entry_date` date NOT NULL,
  `declaration_id` bigint unsigned DEFAULT NULL,
  `declaration_line_id` bigint unsigned DEFAULT NULL,
  `reference` varchar(60) NOT NULL,
  `description` varchar(300) NOT NULL,
  `item_id` bigint unsigned DEFAULT NULL,
  `qty` decimal(20,6) DEFAULT NULL,
  `uom` varchar(10) DEFAULT NULL,
  `value` decimal(20,4) NOT NULL,
  `duty_saved` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `running_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `is_reversal` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `ix_lu_licence` (`licence_id`,`entry_date`,`id`),
  KEY `ix_lu_dec` (`declaration_id`),
  KEY `ix_lu_entity` (`entity_id`,`entry_date`),
  CONSTRAINT `fk_lu_licence` FOREIGN KEY (`licence_id`) REFERENCES `licence` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `licence_utilisation`
--

LOCK TABLES `licence_utilisation` WRITE;
/*!40000 ALTER TABLE `licence_utilisation` DISABLE KEYS */;
INSERT INTO `licence_utilisation` VALUES (1,1,1,'2024-04-12',NULL,NULL,'BOE-3011','CNC machining centre',NULL,NULL,NULL,11240000.0000,0.0000,11240000.0000,0,'2026-08-05 13:02:21.496'),(2,1,1,'2024-07-26',NULL,NULL,'BOE-3288','Coordinate measuring machine',NULL,NULL,NULL,4810000.0000,0.0000,4810000.0000,0,'2026-08-05 13:02:21.499'),(3,1,1,'2024-11-03',NULL,NULL,'BOE-3502','Tool presetter and accessories',NULL,NULL,NULL,2410000.0000,0.0000,2410000.0000,0,'2026-08-05 13:02:21.500'),(4,2,1,'2026-03-18',NULL,NULL,'BOE-4180','Bearing steel, alloy grade',NULL,42000.000000,NULL,2210000.0000,0.0000,2210000.0000,0,'2026-08-05 13:02:21.516'),(5,2,1,'2026-07-07',1,NULL,'BOE-4471','Precision bearings (pending confirmation)',NULL,4000.000000,NULL,210000.0000,0.0000,210000.0000,0,'2026-08-05 13:02:21.518'),(6,3,1,'2026-06-14',NULL,NULL,'BOE-4402','Bonded deposit — alloy steel bar',NULL,NULL,NULL,9240000.0000,0.0000,9240000.0000,0,'2026-08-05 13:02:21.524');
/*!40000 ALTER TABLE `licence_utilisation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `number_series`
--

DROP TABLE IF EXISTS `number_series`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `number_series` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `voucher_type_id` bigint unsigned NOT NULL,
  `site_id` bigint unsigned DEFAULT NULL,
  `gstin` varchar(15) DEFAULT NULL,
  `book_id` bigint unsigned DEFAULT NULL,
  `fiscal_year` varchar(9) NOT NULL,
  `prefix` varchar(30) NOT NULL,
  `suffix` varchar(20) NOT NULL DEFAULT '',
  `width` tinyint unsigned NOT NULL DEFAULT '5',
  `next_no` bigint unsigned NOT NULL DEFAULT '1',
  `is_gapless` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `site_key` bigint unsigned GENERATED ALWAYS AS (ifnull(`site_id`,0)) STORED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_series` (`entity_id`,`voucher_type_id`,`fiscal_year`,`site_key`),
  KEY `fk_ns_vt` (`voucher_type_id`),
  CONSTRAINT `fk_ns_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`),
  CONSTRAINT `fk_ns_vt` FOREIGN KEY (`voucher_type_id`) REFERENCES `voucher_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `number_series`
--

LOCK TABLES `number_series` WRITE;
/*!40000 ALTER TABLE `number_series` DISABLE KEYS */;
INSERT INTO `number_series` (`id`, `entity_id`, `voucher_type_id`, `site_id`, `gstin`, `book_id`, `fiscal_year`, `prefix`, `suffix`, `width`, `next_no`, `is_gapless`, `is_active`) VALUES (1,1,1,NULL,NULL,NULL,'2026-27','PJV/2026-27/','',5,419,1,1),(2,1,2,NULL,NULL,NULL,'2026-27','PIV/2026-27/','',5,1,1,1),(3,1,3,NULL,NULL,NULL,'2026-27','SVI/2026-27/','',5,1,1,1),(4,1,4,NULL,NULL,NULL,'2026-27','DTY/2026-27/','',5,213,1,1),(5,1,5,NULL,NULL,NULL,'2026-27','SIV/2026-27/','',5,95,1,1),(6,1,6,NULL,NULL,NULL,'2026-27','CNV/2026-27/','',5,1,1,1),(7,1,7,NULL,NULL,NULL,'2026-27','PMT/2026-27/','',5,1,1,1),(8,1,8,NULL,NULL,NULL,'2026-27','RCP/2026-27/','',5,1,1,1),(9,1,9,NULL,NULL,NULL,'2026-27','JVM/2026-27/','',5,28,1,1),(10,1,10,NULL,NULL,NULL,'2026-27','LCV/2026-27/','',5,34,1,1),(11,1,11,NULL,NULL,NULL,'2026-27','ENT/2026-27/','',5,62,1,1),(12,1,12,NULL,NULL,NULL,'2026-27','FXR/2026-27/','',5,5,1,1),(13,1,13,NULL,NULL,NULL,'2026-27','BND/2026-27/','',5,1,1,1);
/*!40000 ALTER TABLE `number_series` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `origin_determination`
--

DROP TABLE IF EXISTS `origin_determination`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `origin_determination` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `ref_no` varchar(40) NOT NULL,
  `item_desc` varchar(240) DEFAULT NULL,
  `hs_code` varchar(16) DEFAULT NULL,
  `agreement` varchar(40) DEFAULT NULL,
  `origin_country` varchar(2) DEFAULT NULL,
  `rule_applied` varchar(120) DEFAULT NULL,
  `value_addition_pct` decimal(6,2) NOT NULL DEFAULT '0.00',
  `coo_ref` varchar(60) DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (`id`),
  KEY `ix_origin_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `origin_determination`
--

LOCK TABLES `origin_determination` WRITE;
/*!40000 ALTER TABLE `origin_determination` DISABLE KEYS */;
INSERT INTO `origin_determination` VALUES (1,1,'ORG-2026-0051','Precision bearings, sealed','84821011','CEPA','KR','CTH + 35% value addition',41.20,'KCCI/2026/88120','CERTIFIED'),(2,1,'ORG-2026-0058','Hydraulic valve blocks','84129090','AIFTA','IN','RVC 40%',46.00,NULL,'DETERMINED');
/*!40000 ALTER TABLE `origin_determination` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `override_register`
--

DROP TABLE IF EXISTS `override_register`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `override_register` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `control_code` varchar(20) NOT NULL,
  `rule_code` varchar(20) DEFAULT NULL,
  `object_type` varchar(40) NOT NULL,
  `object_id` bigint unsigned NOT NULL,
  `object_ref` varchar(60) DEFAULT NULL,
  `reason` varchar(1000) NOT NULL,
  `requested_by` bigint unsigned NOT NULL,
  `approved_by` bigint unsigned NOT NULL,
  `exposure_amount` decimal(20,4) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `reviewed_at` datetime(3) DEFAULT NULL,
  `reviewed_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_override_entity` (`entity_id`,`created_at` DESC),
  KEY `ix_override_review` (`entity_id`,`reviewed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `override_register`
--

LOCK TABLES `override_register` WRITE;
/*!40000 ALTER TABLE `override_register` DISABLE KEYS */;
/*!40000 ALTER TABLE `override_register` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `port`
--

DROP TABLE IF EXISTS `port`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `port` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(10) NOT NULL,
  `name` varchar(120) NOT NULL,
  `country_code` char(2) NOT NULL,
  `mode` enum('SEA','AIR','ROAD','RAIL','ICD','CFS','LCS') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_port_code` (`code`),
  KEY `ix_port_country` (`country_code`),
  CONSTRAINT `fk_port_country` FOREIGN KEY (`country_code`) REFERENCES `country` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `port`
--

LOCK TABLES `port` WRITE;
/*!40000 ALTER TABLE `port` DISABLE KEYS */;
INSERT INTO `port` VALUES (1,'KRPUS','Busan','KR','SEA'),(2,'INNSA','Nhava Sheva (JNPT)','IN','SEA'),(3,'INBOM','Mumbai (Air)','IN','AIR'),(4,'DEHAM','Hamburg','DE','SEA'),(5,'SEGOT','Gothenburg','SE','SEA'),(6,'AEJEA','Jebel Ali','AE','SEA'),(7,'CNNGB','Ningbo','CN','SEA');
/*!40000 ALTER TABLE `port` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_clearance_case`
--

DROP TABLE IF EXISTS `post_clearance_case`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_clearance_case` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `case_no` varchar(40) NOT NULL,
  `opened_on` date NOT NULL,
  `declaration_no` varchar(40) DEFAULT NULL,
  `case_type` varchar(40) DEFAULT NULL,
  `authority` varchar(80) DEFAULT NULL,
  `exposure` decimal(18,2) NOT NULL DEFAULT '0.00',
  `currency` varchar(3) NOT NULL DEFAULT 'INR',
  `due_on` date DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (`id`),
  KEY `ix_pcc_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_clearance_case`
--

LOCK TABLES `post_clearance_case` WRITE;
/*!40000 ALTER TABLE `post_clearance_case` DISABLE KEYS */;
INSERT INTO `post_clearance_case` VALUES (1,1,'PCC-2026-011','2026-07-08','BOE-4471','SVB','Customs SVB Cell',340000.00,'INR','2026-08-20','OPEN'),(2,1,'PCC-2026-014','2026-07-21','BOE-4488','AMENDMENT','Customs Appraising',0.00,'INR','2026-08-10','REPLIED');
/*!40000 ALTER TABLE `post_clearance_case` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `posting_line`
--

DROP TABLE IF EXISTS `posting_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `posting_line` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `period_key` int unsigned NOT NULL,
  `voucher_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `book_id` bigint unsigned NOT NULL,
  `line_no` smallint unsigned NOT NULL,
  `account_id` bigint unsigned NOT NULL,
  `dr_cr` enum('DR','CR') NOT NULL,
  `amount_txn` decimal(20,4) NOT NULL,
  `amount_func` decimal(20,4) NOT NULL,
  `amount_group` decimal(20,4) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `fx_rate` decimal(18,8) NOT NULL DEFAULT '1.00000000',
  `fx_rate_type` enum('ACCOUNTING','CUSTOMS','CLOSING','SETTLEMENT','FORWARD') NOT NULL DEFAULT 'ACCOUNTING',
  `voucher_date` date NOT NULL,
  `site_id` bigint unsigned DEFAULT NULL,
  `cost_centre` varchar(20) DEFAULT NULL,
  `profit_centre` varchar(20) DEFAULT NULL,
  `project_code` varchar(30) DEFAULT NULL,
  `party_id` bigint unsigned DEFAULT NULL,
  `item_id` bigint unsigned DEFAULT NULL,
  `lot_no` varchar(40) DEFAULT NULL,
  `shipment_id` bigint unsigned DEFAULT NULL,
  `declaration_id` bigint unsigned DEFAULT NULL,
  `declaration_line_id` bigint unsigned DEFAULT NULL,
  `instrument_id` bigint unsigned DEFAULT NULL,
  `licence_id` bigint unsigned DEFAULT NULL,
  `scheme_id` bigint unsigned DEFAULT NULL,
  `charge_type_id` bigint unsigned DEFAULT NULL,
  `tax_code` varchar(30) DEFAULT NULL,
  `subledger_key` varchar(60) DEFAULT NULL,
  `rule_branch` varchar(200) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`period_key`,`id`),
  KEY `ix_pl_id` (`id`),
  KEY `ix_pl_ledger` (`entity_id`,`book_id`,`account_id`,`period_key`,`voucher_date`,`id`),
  KEY `ix_pl_voucher` (`voucher_id`),
  KEY `ix_pl_shipment` (`entity_id`,`shipment_id`),
  KEY `ix_pl_declaration` (`entity_id`,`declaration_id`),
  KEY `ix_pl_party` (`entity_id`,`party_id`,`period_key`),
  KEY `ix_pl_item` (`entity_id`,`item_id`,`period_key`),
  KEY `ix_pl_scheme` (`entity_id`,`scheme_id`,`period_key`),
  KEY `ix_pl_charge` (`entity_id`,`charge_type_id`,`period_key`),
  KEY `ix_pl_clearing` (`entity_id`,`account_id`,`shipment_id`,`voucher_date`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50100 PARTITION BY RANGE (`period_key`)
(PARTITION p2025 VALUES LESS THAN (202601) ENGINE = InnoDB,
 PARTITION p202601 VALUES LESS THAN (202602) ENGINE = InnoDB,
 PARTITION p202602 VALUES LESS THAN (202603) ENGINE = InnoDB,
 PARTITION p202603 VALUES LESS THAN (202604) ENGINE = InnoDB,
 PARTITION p202604 VALUES LESS THAN (202605) ENGINE = InnoDB,
 PARTITION p202605 VALUES LESS THAN (202606) ENGINE = InnoDB,
 PARTITION p202606 VALUES LESS THAN (202607) ENGINE = InnoDB,
 PARTITION p202607 VALUES LESS THAN (202608) ENGINE = InnoDB,
 PARTITION p202608 VALUES LESS THAN (202609) ENGINE = InnoDB,
 PARTITION p202609 VALUES LESS THAN (202610) ENGINE = InnoDB,
 PARTITION p202610 VALUES LESS THAN (202611) ENGINE = InnoDB,
 PARTITION p202611 VALUES LESS THAN (202612) ENGINE = InnoDB,
 PARTITION p202612 VALUES LESS THAN (202701) ENGINE = InnoDB,
 PARTITION p202701 VALUES LESS THAN (202702) ENGINE = InnoDB,
 PARTITION p202702 VALUES LESS THAN (202703) ENGINE = InnoDB,
 PARTITION p202703 VALUES LESS THAN (202704) ENGINE = InnoDB,
 PARTITION p202704 VALUES LESS THAN (202705) ENGINE = InnoDB,
 PARTITION p202705 VALUES LESS THAN (202706) ENGINE = InnoDB,
 PARTITION p202706 VALUES LESS THAN (202707) ENGINE = InnoDB,
 PARTITION p202707 VALUES LESS THAN (202708) ENGINE = InnoDB,
 PARTITION p202708 VALUES LESS THAN (202709) ENGINE = InnoDB,
 PARTITION p202709 VALUES LESS THAN (202710) ENGINE = InnoDB,
 PARTITION p202710 VALUES LESS THAN (202711) ENGINE = InnoDB,
 PARTITION p202711 VALUES LESS THAN (202712) ENGINE = InnoDB,
 PARTITION p202712 VALUES LESS THAN (202801) ENGINE = InnoDB,
 PARTITION pmax VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posting_line`
--

LOCK TABLES `posting_line` WRITE;
/*!40000 ALTER TABLE `posting_line` DISABLE KEYS */;
INSERT INTO `posting_line` VALUES (17,202606,7,1,1,1,6,'DR',3816.0000,3816.0000,3816.0000,'INR',1.00000000,'ACCOUNTING','2026-06-30',NULL,NULL,NULL,NULL,NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Inventory',NULL,'2026-08-05 13:02:21.601'),(18,202606,7,1,1,2,19,'DR',17384.0000,17384.0000,17384.0000,'INR',1.00000000,'ACCOUNTING','2026-06-30',NULL,NULL,NULL,NULL,NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.602'),(19,202606,7,1,1,3,12,'CR',21200.0000,21200.0000,21200.0000,'INR',1.00000000,'ACCOUNTING','2026-06-30',NULL,NULL,NULL,NULL,NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.604'),(1,202607,1,1,1,1,6,'DR',14833983.2800,14833983.2800,14833983.2800,'INR',1.00000000,'ACCOUNTING','2026-07-12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL,'Inventory',NULL,'2026-08-05 13:02:21.557'),(2,202607,1,1,1,2,7,'CR',13564518.0000,13564518.0000,13564518.0000,'INR',1.00000000,'ACCOUNTING','2026-07-12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL,'Inventory',NULL,'2026-08-05 13:02:21.566'),(3,202607,1,1,1,3,13,'CR',794465.2800,794465.2800,794465.2800,'INR',1.00000000,'ACCOUNTING','2026-07-12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.568'),(4,202607,1,1,1,4,12,'CR',310000.0000,310000.0000,310000.0000,'INR',1.00000000,'ACCOUNTING','2026-07-12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.569'),(5,202607,1,1,1,5,14,'CR',165000.0000,165000.0000,165000.0000,'INR',1.00000000,'ACCOUNTING','2026-07-12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.569'),(6,202607,2,1,1,1,13,'DR',794465.2800,794465.2800,794465.2800,'INR',1.00000000,'ACCOUNTING','2026-07-10',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'non-recoverable to inventory via clearing','2026-08-05 13:02:21.578'),(7,202607,2,1,1,2,8,'DR',2657871.3400,2657871.3400,2657871.3400,'INR',1.00000000,'ACCOUNTING','2026-07-10',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,'IGST-IMP-18','Tax','credit available','2026-08-05 13:02:21.579'),(8,202607,2,1,1,3,11,'CR',3452336.6200,3452336.6200,3452336.6200,'INR',1.00000000,'ACCOUNTING','2026-07-10',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.580'),(9,202607,3,1,1,1,3,'DR',342800.0000,33045920.0000,33045920.0000,'EUR',96.40000000,'ACCOUNTING','2026-07-30',NULL,NULL,NULL,NULL,NULL,NULL,NULL,2,2,NULL,NULL,NULL,NULL,NULL,NULL,'AR',NULL,'2026-08-05 13:02:21.583'),(10,202607,3,1,1,2,17,'CR',342800.0000,33045920.0000,33045920.0000,'EUR',96.40000000,'ACCOUNTING','2026-07-30',NULL,NULL,NULL,NULL,NULL,NULL,NULL,2,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.584'),(11,202607,4,1,1,1,4,'DR',260064.0000,260064.0000,260064.0000,'INR',1.00000000,'ACCOUNTING','2026-07-31',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,2,NULL,NULL,NULL,NULL,NULL,NULL,'Entitlement',NULL,'2026-08-05 13:02:21.589'),(12,202607,4,1,1,2,18,'CR',260064.0000,260064.0000,260064.0000,'INR',1.00000000,'ACCOUNTING','2026-07-31',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.590'),(13,202607,5,1,1,1,21,'DR',18000.0000,18000.0000,18000.0000,'INR',1.00000000,'ACCOUNTING','2026-07-31',NULL,NULL,NULL,NULL,NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.593'),(14,202607,5,1,1,2,6,'CR',18000.0000,18000.0000,18000.0000,'INR',1.00000000,'ACCOUNTING','2026-07-31',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.594'),(15,202607,6,1,1,1,23,'DR',412000.0000,412000.0000,412000.0000,'INR',1.00000000,'ACCOUNTING','2026-07-31',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-08-05 13:02:21.598'),(16,202607,6,1,1,2,9,'CR',412000.0000,412000.0000,412000.0000,'INR',1.00000000,'ACCOUNTING','2026-07-31',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'AP',NULL,'2026-08-05 13:02:21.599');
/*!40000 ALTER TABLE `posting_line` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `posting_rule`
--

DROP TABLE IF EXISTS `posting_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `posting_rule` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(30) NOT NULL,
  `version` varchar(10) NOT NULL,
  `business_event` varchar(60) NOT NULL,
  `voucher_type_code` varchar(10) NOT NULL,
  `book_code` varchar(20) NOT NULL DEFAULT 'PRIMARY',
  `description` varchar(400) NOT NULL,
  `standard_ref` varchar(120) DEFAULT NULL,
  `gaap_dependent` tinyint(1) NOT NULL DEFAULT '0',
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `prepared_by` bigint unsigned DEFAULT NULL,
  `approved_by` bigint unsigned DEFAULT NULL,
  `approved_at` datetime(3) DEFAULT NULL,
  `test_result` enum('PASSED','FAILED','NOT_RUN') NOT NULL DEFAULT 'NOT_RUN',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rule` (`entity_id`,`code`,`version`),
  KEY `ix_rule_event` (`entity_id`,`business_event`,`book_code`,`effective_from` DESC),
  CONSTRAINT `fk_pr_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posting_rule`
--

LOCK TABLES `posting_rule` WRITE;
/*!40000 ALTER TABLE `posting_rule` DISABLE KEYS */;
INSERT INTO `posting_rule` VALUES (1,1,'PR-IMP-03','v2','ownershipTransferInTransit','PJV','PRIMARY','Ownership transfer at origin per Incoterm — goods in transit recognised','Ind AS 2 / Incoterms 2020',1,'2026-04-01',NULL,NULL,NULL,NULL,'PASSED',1),(2,1,'PR-IMP-05','v3','dutyAssessed','DTY','PRIMARY','Customs duty assessed — split recoverable and inventoriable','Ind AS 2.11 / CGST s.16',1,'2026-04-01',NULL,NULL,NULL,NULL,'PASSED',1),(3,1,'PR-IMP-08','v3','goodsReceipt','PJV','PRIMARY','Goods receipt at estimated landed cost with per-element accrual','Ind AS 2',1,'2026-04-01',NULL,NULL,NULL,NULL,'PASSED',1),(4,1,'PR-IMP-11','v2','landedCostClosure','LCV','PRIMARY','Landed cost closure — differential split by stock position','Ind AS 2',1,'2026-04-01',NULL,NULL,NULL,NULL,'PASSED',1),(5,1,'PR-EXP-02','v2','exportDispatch','SIV','PRIMARY','Export dispatch — revenue recognised on transfer of control','Ind AS 115 / Ind AS 21',1,'2026-04-01',NULL,NULL,NULL,NULL,'PASSED',1),(6,1,'PR-EXP-08','v2','exportRealisation','RCP','PRIMARY','Export realisation with charges and realised exchange difference','Ind AS 21.28',1,'2026-04-01',NULL,NULL,NULL,NULL,'PASSED',1),(7,1,'PR-EXP-10','v4','entitlementAccrual','ENT','PRIMARY','Entitlement accrued where reasonable assurance exists','Ind AS 20.7',1,'2026-04-01',NULL,NULL,NULL,NULL,'PASSED',1),(8,1,'PR-PER-02','v2','fxRevaluation','FXR','PRIMARY','Period-end revaluation of monetary items only, auto-reversing','Ind AS 21.23',1,'2026-04-01',NULL,NULL,NULL,NULL,'PASSED',1);
/*!40000 ALTER TABLE `posting_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `posting_rule_line`
--

DROP TABLE IF EXISTS `posting_rule_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `posting_rule_line` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `rule_id` bigint unsigned NOT NULL,
  `seq_no` smallint unsigned NOT NULL,
  `dr_cr` enum('DR','CR') NOT NULL,
  `account_key` varchar(40) NOT NULL,
  `amount_key` varchar(40) NOT NULL,
  `tax_code` varchar(30) DEFAULT NULL,
  `condition_expr` varchar(300) DEFAULT NULL,
  `branch_note` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_prl` (`rule_id`,`seq_no`),
  CONSTRAINT `fk_prl_rule` FOREIGN KEY (`rule_id`) REFERENCES `posting_rule` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posting_rule_line`
--

LOCK TABLES `posting_rule_line` WRITE;
/*!40000 ALTER TABLE `posting_rule_line` DISABLE KEYS */;
INSERT INTO `posting_rule_line` VALUES (1,1,1,'DR','GIT','goodsValueFunc',NULL,NULL,NULL),(2,1,2,'CR','AP_FOREIGN','goodsValueFunc',NULL,NULL,NULL),(3,2,1,'DR','CLEARING_DUTY','dutyInventoriable',NULL,NULL,'non-recoverable to inventory via clearing'),(4,2,2,'DR','IGST_RECOVERABLE','dutyRecoverable','IGST-IMP-18',NULL,'credit available'),(5,2,3,'CR','DUTY_PAYABLE','dutyTotal',NULL,NULL,NULL),(6,3,1,'DR','INVENTORY','estimatedLandedCost',NULL,NULL,NULL),(7,3,2,'CR','GIT','goodsValueFunc',NULL,NULL,NULL),(8,3,3,'CR','CLEARING_DUTY','dutyInventoriable',NULL,NULL,NULL),(9,3,4,'CR','CLEARING_FREIGHT','freightEstimate',NULL,NULL,NULL),(10,3,5,'CR','CLEARING_PORT','portEstimate',NULL,NULL,NULL),(11,4,1,'DR','INVENTORY','toInventory',NULL,NULL,NULL),(12,4,2,'DR','COGS','toCogs',NULL,NULL,NULL),(13,4,3,'CR','CLEARING_FREIGHT','differential',NULL,NULL,NULL),(14,5,1,'DR','AR_EXPORT','invoiceValueFunc',NULL,NULL,NULL),(15,5,2,'CR','REVENUE_EXPORT','invoiceValueFunc',NULL,NULL,NULL),(16,6,1,'DR','BANK_FC','netCredited',NULL,NULL,NULL),(17,6,2,'DR','BANK_CHARGES','bankCharges',NULL,NULL,NULL),(18,6,3,'DR','FX_REALISED','fxLoss',NULL,NULL,NULL),(19,6,4,'CR','AR_EXPORT','carryingAmount',NULL,NULL,NULL),(20,7,1,'DR','ENTITLEMENT_REC','entitlementValue',NULL,NULL,NULL),(21,7,2,'CR','ENTITLEMENT_INC','entitlementValue',NULL,NULL,NULL),(22,8,1,'DR','FX_UNREALISED','revalLoss',NULL,NULL,NULL),(23,8,2,'CR','AP_FOREIGN','revalLoss',NULL,NULL,NULL);
/*!40000 ALTER TABLE `posting_rule_line` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `preference_rate`
--

DROP TABLE IF EXISTS `preference_rate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `preference_rate` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `agreement_id` bigint unsigned NOT NULL,
  `hs_code` varchar(12) NOT NULL,
  `partner_code` char(2) NOT NULL,
  `rate_pct` decimal(10,4) NOT NULL,
  `origin_rule` varchar(300) NOT NULL,
  `rule_type` enum('WO','CTC','CTSH','VALUE_CONTENT','PROCESS','COMBINATION') NOT NULL,
  `threshold_pct` decimal(6,2) DEFAULT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_pref_lookup` (`agreement_id`,`hs_code`,`partner_code`,`valid_from` DESC),
  CONSTRAINT `fk_pref_agreement` FOREIGN KEY (`agreement_id`) REFERENCES `trade_agreement` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `preference_rate`
--

LOCK TABLES `preference_rate` WRITE;
/*!40000 ALTER TABLE `preference_rate` DISABLE KEYS */;
/*!40000 ALTER TABLE `preference_rate` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `presentation`
--

DROP TABLE IF EXISTS `presentation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `presentation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `presentation_no` varchar(40) NOT NULL,
  `presented_on` date DEFAULT NULL,
  `instrument_no` varchar(40) DEFAULT NULL,
  `bank` varchar(120) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `discrepancies` int NOT NULL DEFAULT '0',
  `deadline` date DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'DRAFT',
  PRIMARY KEY (`id`),
  KEY `ix_pres_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `presentation`
--

LOCK TABLES `presentation` WRITE;
/*!40000 ALTER TABLE `presentation` DISABLE KEYS */;
INSERT INTO `presentation` VALUES (1,1,'PRS-2026-0044','2026-07-25','LC-EXP-2026-004','ICICI Bank','USD',104000.00,0,'2026-08-05','ACCEPTED'),(2,1,'PRS-2026-0048',NULL,'LC-EXP-2026-006','HDFC Bank','USD',395000.00,2,'2026-08-18','DRAFT');
/*!40000 ALTER TABLE `presentation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `provider_invoice`
--

DROP TABLE IF EXISTS `provider_invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `provider_invoice` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `invoice_no` varchar(40) NOT NULL,
  `invoice_date` date NOT NULL,
  `provider` varchar(160) DEFAULT NULL,
  `service_type` varchar(40) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'INR',
  `amount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `shipment_no` varchar(40) DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'RECEIVED',
  PRIMARY KEY (`id`),
  KEY `ix_provinv_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `provider_invoice`
--

LOCK TABLES `provider_invoice` WRITE;
/*!40000 ALTER TABLE `provider_invoice` DISABLE KEYS */;
INSERT INTO `provider_invoice` VALUES (1,1,'FF-INV-88213','2026-07-20','BlueDart Aviation','FREIGHT','INR',214000.00,'SHP-2026-04471','APPROVED'),(2,1,'CHA-2026-0912','2026-07-25','Seahorse Clearing','CHA','INR',46800.00,'SHP-2026-04488','VERIFIED'),(3,1,'TR-55120','2026-07-31','GATI Logistics','TRANSPORT','INR',31500.00,'SHP-2026-04502','RECEIVED');
/*!40000 ALTER TABLE `provider_invoice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `realisation`
--

DROP TABLE IF EXISTS `realisation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `realisation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `realisation_no` varchar(40) NOT NULL,
  `invoice_no` varchar(40) DEFAULT NULL,
  `customer` varchar(160) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `invoice_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `realised_value` decimal(18,2) NOT NULL DEFAULT '0.00',
  `due_date` date DEFAULT NULL,
  `realised_on` date DEFAULT NULL,
  `edpms_status` varchar(24) DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (`id`),
  KEY `ix_real_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `realisation`
--

LOCK TABLES `realisation` WRITE;
/*!40000 ALTER TABLE `realisation` DISABLE KEYS */;
INSERT INTO `realisation` VALUES (1,1,'RLS-2026-0221','EXP/2026/0441','Meridian Industries','USD',395000.00,0.00,'2026-10-22',NULL,'OUTSTANDING','PENDING'),(2,1,'RLS-2026-0225','EXP/2026/0448','Gulf Machinery LLC','USD',104000.00,104000.00,'2026-09-30','2026-08-01','REALISED','REALISED');
/*!40000 ALTER TABLE `realisation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reconciliation`
--

DROP TABLE IF EXISTS `reconciliation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reconciliation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(200) NOT NULL,
  `source_a` varchar(120) NOT NULL,
  `source_b` varchar(120) NOT NULL,
  `frequency` enum('DAILY','WEEKLY','MONTHLY','QUARTERLY') NOT NULL,
  `owner_role` varchar(60) NOT NULL,
  `control_account_id` bigint unsigned DEFAULT NULL,
  `as_of` date DEFAULT NULL,
  `matched_count` int unsigned NOT NULL DEFAULT '0',
  `unmatched_a` int unsigned NOT NULL DEFAULT '0',
  `unmatched_b` int unsigned NOT NULL DEFAULT '0',
  `value_at_risk` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `oldest_days` int unsigned NOT NULL DEFAULT '0',
  `status` enum('CLEAN','EXCEPTIONS','CRITICAL') NOT NULL DEFAULT 'CLEAN',
  `signed_off_by` bigint unsigned DEFAULT NULL,
  `signed_off_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_recon` (`entity_id`,`code`),
  KEY `ix_recon_status` (`entity_id`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reconciliation`
--

LOCK TABLES `reconciliation` WRITE;
/*!40000 ALTER TABLE `reconciliation` DISABLE KEYS */;
INSERT INTO `reconciliation` VALUES (1,1,'R-01','Bank — EEFC foreign currency account','Bank subledger','Bank statement','DAILY','Accounts executive',NULL,'2026-07-31',148,2,1,184000.0000,11,'EXCEPTIONS',NULL,NULL),(2,1,'R-02','Import tax credit against statutory statement','Import declarations','GSTR-2B credit statement','MONTHLY','Tax executive',NULL,'2026-07-31',62,4,0,642000.0000,46,'CRITICAL',NULL,NULL),(3,1,'R-03','Landed cost clearing — freight','Cost sheets','Clearing account 2109001','WEEKLY','Cost accountant',NULL,'2026-07-31',34,3,0,394000.0000,58,'EXCEPTIONS',NULL,NULL),(4,1,'R-04','Exchange control — export realisation (EDPMS)','Declarations and invoices','EDPMS status','WEEKLY','Trade finance officer',NULL,'2026-07-31',71,9,0,8940000.0000,268,'CRITICAL',NULL,NULL),(5,1,'R-05','AP subledger to control account','AP subledger','Accounts 2101001 / 2101003','MONTHLY','Accounts executive',NULL,'2026-07-31',214,0,0,0.0000,0,'CLEAN',NULL,NULL),(6,1,'R-06','Bonded stock — duty liability ledger','Bonded duty ledger','Physical stock and authority records','DAILY','Compliance officer',NULL,'2026-08-03',46,0,0,0.0000,0,'CLEAN',NULL,NULL);
/*!40000 ALTER TABLE `reconciliation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reconciliation_item`
--

DROP TABLE IF EXISTS `reconciliation_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reconciliation_item` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `reconciliation_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `item_ref` varchar(120) NOT NULL,
  `item_date` date NOT NULL,
  `description` varchar(400) NOT NULL,
  `amount_a` decimal(20,4) DEFAULT NULL,
  `amount_b` decimal(20,4) DEFAULT NULL,
  `difference` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `cause` varchar(200) DEFAULT NULL,
  `age_days` int unsigned NOT NULL DEFAULT '0',
  `limitation_date` date DEFAULT NULL,
  `status` enum('UNMATCHED','MATCHED_AUTO','MATCHED_MANUAL','DISPUTED','WRITTEN_OFF') NOT NULL DEFAULT 'UNMATCHED',
  `matched_by` bigint unsigned DEFAULT NULL,
  `match_basis` varchar(400) DEFAULT NULL,
  `matched_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_ri_recon` (`reconciliation_id`,`status`,`age_days` DESC),
  KEY `ix_ri_limitation` (`entity_id`,`limitation_date`),
  CONSTRAINT `fk_ri_recon` FOREIGN KEY (`reconciliation_id`) REFERENCES `reconciliation` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reconciliation_item`
--

LOCK TABLES `reconciliation_item` WRITE;
/*!40000 ALTER TABLE `reconciliation_item` DISABLE KEYS */;
INSERT INTO `reconciliation_item` VALUES (1,1,1,'RCP/2026-27/00188','2026-07-24','Export realisation Meridian — bank charges deducted at source not booked',2840000.0000,2812400.0000,27600.0000,'Correspondent bank charges deducted from proceeds',7,NULL,'UNMATCHED',NULL,NULL,NULL),(2,1,1,'PMT/2026-27/00301','2026-07-20','Remittance to Hanyang — value date difference',1240000.0000,NULL,1240000.0000,'In books, not yet in statement',11,NULL,'UNMATCHED',NULL,NULL,NULL),(3,1,1,'BANK-CR-8841','2026-07-29','Unidentified credit in statement',NULL,156400.0000,-156400.0000,'In statement, not in books — under investigation',2,NULL,'DISPUTED',NULL,NULL,NULL),(4,2,1,'BOE-4412','2026-06-03','Declaration in books, credit absent from statement',1145600.0000,NULL,1145600.0000,'Declaration present, credit not reflected',46,'2027-11-30','UNMATCHED',NULL,NULL,NULL),(5,2,1,'BOE-4402','2026-06-14','Bonded deposit — no credit expected until ex-bond clearance',0.0000,NULL,0.0000,'Timing — correct',35,NULL,'MATCHED_MANUAL',NULL,NULL,NULL),(6,2,1,'BOE-4380','2026-05-28','Value mismatch between declaration and statement',428000.0000,412000.0000,16000.0000,'Value mismatch',52,'2027-11-30','UNMATCHED',NULL,NULL,NULL),(7,2,1,'BOE-4471','2026-07-07','Awaiting next statement cycle',7563892.0000,NULL,7563892.0000,'Timing — expected in August statement',24,NULL,'UNMATCHED',NULL,NULL,NULL),(8,3,1,'CS-003 / CL-11','2026-06-02','Ocean freight accrued, provider invoice not received',168000.0000,168000.0000,0.0000,'Accrued not invoiced — 58 days, beyond policy age',58,NULL,'UNMATCHED',NULL,NULL,NULL),(9,3,1,'CS-003 / CL-13','2026-06-02','Terminal handling accrued, provider invoice not received',44000.0000,44000.0000,0.0000,'Accrued not invoiced — 58 days',58,NULL,'UNMATCHED',NULL,NULL,NULL),(10,3,1,'CS-001 / CL-7','2026-07-12','Inland freight accrued, invoice awaited',92000.0000,92000.0000,0.0000,'Accrued not invoiced — within policy',19,NULL,'UNMATCHED',NULL,NULL,NULL),(11,4,1,'SB-8712 / EXP/2025/0288','2025-11-06','Realisation overdue beyond the 9-month period in force for that shipment date',3240000.0000,NULL,3240000.0000,'Overdue — buyer dispute on quality claim',268,'2026-08-06','UNMATCHED',NULL,NULL,NULL),(12,4,1,'SB-8804 / EXP/2025/0311','2025-12-14','Part realisation, balance outstanding',1860000.0000,1200000.0000,660000.0000,'Short realisation pending approval',230,NULL,'UNMATCHED',NULL,NULL,NULL),(13,4,1,'SB-9120 / EXP/2025/0402','2026-01-19','Realised but entry not closed by AD bank',2480000.0000,2480000.0000,0.0000,'Closure pending at bank',194,NULL,'UNMATCHED',NULL,NULL,NULL);
/*!40000 ALTER TABLE `reconciliation_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `regulatory_change`
--

DROP TABLE IF EXISTS `regulatory_change`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `regulatory_change` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `ref_no` varchar(40) NOT NULL,
  `published_on` date DEFAULT NULL,
  `authority` varchar(80) DEFAULT NULL,
  `title` varchar(240) NOT NULL,
  `category` varchar(40) DEFAULT NULL,
  `effective_from` date DEFAULT NULL,
  `impact` varchar(16) DEFAULT NULL,
  `owner_role` varchar(60) DEFAULT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'NEW',
  PRIMARY KEY (`id`),
  KEY `ix_regchg_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regulatory_change`
--

LOCK TABLES `regulatory_change` WRITE;
/*!40000 ALTER TABLE `regulatory_change` DISABLE KEYS */;
INSERT INTO `regulatory_change` VALUES (1,1,'REG-2026-118','2026-07-10','CBIC','Revised AIDC rate on specified capital goods','CUSTOMS','2026-08-01','HIGH','Compliance officer','ASSESSING'),(2,1,'REG-2026-124','2026-07-22','DGFT','RoDTEP rate schedule amendment','FTP','2026-08-15','MEDIUM','Compliance officer','NEW');
/*!40000 ALTER TABLE `regulatory_change` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rollup_check`
--

DROP TABLE IF EXISTS `rollup_check`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rollup_check` (
  `entity_id` bigint unsigned NOT NULL,
  `book_id` bigint unsigned NOT NULL,
  `account_id` bigint unsigned NOT NULL,
  `period_key` int unsigned NOT NULL,
  `rollup_dr` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `rollup_cr` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `fact_dr` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `fact_cr` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `diff_dr` decimal(24,4) GENERATED ALWAYS AS ((`rollup_dr` - `fact_dr`)) STORED,
  `diff_cr` decimal(24,4) GENERATED ALWAYS AS ((`rollup_cr` - `fact_cr`)) STORED,
  `checked_at` datetime(3) NOT NULL,
  PRIMARY KEY (`entity_id`,`book_id`,`account_id`,`period_key`),
  KEY `ix_rc_diff` (`entity_id`,`period_key`,`diff_dr`,`diff_cr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rollup_check`
--

LOCK TABLES `rollup_check` WRITE;
/*!40000 ALTER TABLE `rollup_check` DISABLE KEYS */;
/*!40000 ALTER TABLE `rollup_check` ENABLE KEYS */;
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
INSERT INTO `schema_migration` VALUES ('001_core.sql','9cb40a6fa1b16886ea7006a9ea9140809d032b75638116bfe977ba7420add5a9','2026-08-05 09:11:02.006',300),('002_accounting.sql','38eba7115ba820f096098f4cb5515f9ae4570d343565a2e842303468bb49b160','2026-08-05 09:11:02.604',595),('003_trade.sql','e5c9ae80e466180c9da6597bfd3dabde53808c305c5905018494dd75e0e62dbc','2026-08-05 09:11:03.965',1358),('004_views_procs.sql','8cc084dd474f7318024b2f6e089a1d634db315adcf7486bc964b0a46cd5b47d6','2026-08-05 09:11:04.066',99),('005_ui_fields.sql','c18bfb89ce1fa3791449f0c683d2d9f1ec6c916ebc3b9fdf3497af40de4be11c','2026-08-05 09:11:04.401',334),('006_monthly_2027_partitions.sql','eb1573d3ded976242a2bf634f22f3256d655563a60fde7f0bd912a65f4ebbe23','2026-08-05 09:11:05.587',1182),('007_voucher_names.sql','e14240f606062707fc32246c550f722f50291b965141ee12cbe7e00e60ba247e','2026-08-05 09:11:05.664',76),('008_integration.sql','1a1430f8803aef08ef0b675519b8f59c35af7acdbbe85d712bb24c98ab39c24b','2026-08-05 10:58:12.044',22),('009_operations.sql','1b7f8a2ac5102d5999aa4d27fbff3276578840fcaad03ab41a53aff708cbf754','2026-08-05 12:52:51.736',172),('010_operations2.sql','e5813b1285fa10a0331d8fd2c6bb45b77446b677554bb921e2b3ffcc3c890b03','2026-08-05 13:02:09.475',288);
/*!40000 ALTER TABLE `schema_migration` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scheme`
--

DROP TABLE IF EXISTS `scheme`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scheme` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) NOT NULL,
  `name` varchar(160) NOT NULL,
  `scheme_family` enum('REMISSION','REBATE','DRAWBACK','INPUT_AUTH','CAPITAL_AUTH','ZONE','BONDED','REFUND','CREDIT_SUPPORT') NOT NULL,
  `obligation_type` enum('NONE','VALUE','QUANTITY','MULTIPLE_OF_DUTY_SAVED') NOT NULL DEFAULT 'NONE',
  `obligation_multiple` decimal(8,2) DEFAULT NULL,
  `obligation_months` smallint unsigned DEFAULT NULL,
  `min_value_addition_pct` decimal(6,2) DEFAULT NULL,
  `recognition_point` enum('ON_EXPORT','ON_FILING','ON_SANCTION','ON_RECEIPT') NOT NULL DEFAULT 'ON_SANCTION',
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_scheme` (`code`,`valid_from`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scheme`
--

LOCK TABLES `scheme` WRITE;
/*!40000 ALTER TABLE `scheme` DISABLE KEYS */;
INSERT INTO `scheme` VALUES (1,'EPCG','Export Promotion Capital Goods','CAPITAL_AUTH','MULTIPLE_OF_DUTY_SAVED',6.00,72,NULL,'ON_SANCTION','2020-04-01',NULL),(2,'AA','Advance Authorisation','INPUT_AUTH','VALUE',NULL,18,15.00,'ON_SANCTION','2020-04-01',NULL),(3,'MOOWR','Manufacture in Bonded Warehouse (Section 65)','BONDED','NONE',NULL,NULL,NULL,'ON_RECEIPT','2020-04-01',NULL),(4,'RODTEP','Remission of Duties and Taxes on Exported Products','REBATE','NONE',NULL,NULL,NULL,'ON_SANCTION','2020-04-01',NULL),(5,'DRAWBACK','Duty Drawback','DRAWBACK','NONE',NULL,NULL,NULL,'ON_SANCTION','2020-04-01',NULL);
/*!40000 ALTER TABLE `scheme` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scheme_rate`
--

DROP TABLE IF EXISTS `scheme_rate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scheme_rate` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `scheme_id` bigint unsigned NOT NULL,
  `hs_code` varchar(12) NOT NULL,
  `rate_pct` decimal(10,4) NOT NULL,
  `cap_amount` decimal(20,4) DEFAULT NULL,
  `cap_uom` varchar(10) DEFAULT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_scheme_rate` (`scheme_id`,`hs_code`,`valid_from` DESC),
  CONSTRAINT `fk_sr_scheme` FOREIGN KEY (`scheme_id`) REFERENCES `scheme` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scheme_rate`
--

LOCK TABLES `scheme_rate` WRITE;
/*!40000 ALTER TABLE `scheme_rate` DISABLE KEYS */;
/*!40000 ALTER TABLE `scheme_rate` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `screening_event`
--

DROP TABLE IF EXISTS `screening_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `screening_event` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `party_id` bigint unsigned NOT NULL,
  `list_ref` varchar(80) NOT NULL,
  `list_entry` varchar(300) DEFAULT NULL,
  `score` smallint unsigned DEFAULT NULL,
  `matched_tokens` varchar(300) DEFAULT NULL,
  `verdict` enum('CLEAR','POTENTIAL','CONFIRMED','FALSE_POSITIVE') NOT NULL,
  `disposition` varchar(500) DEFAULT NULL,
  `reviewed_by` bigint unsigned DEFAULT NULL,
  `screened_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `ix_screen_party` (`party_id`,`screened_at` DESC),
  KEY `ix_screen_open` (`entity_id`,`verdict`,`screened_at` DESC),
  CONSTRAINT `fk_se_party` FOREIGN KEY (`party_id`) REFERENCES `trade_party` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `screening_event`
--

LOCK TABLES `screening_event` WRITE;
/*!40000 ALTER TABLE `screening_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `screening_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shipment`
--

DROP TABLE IF EXISTS `shipment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `site_id` bigint unsigned DEFAULT NULL,
  `shipment_no` varchar(40) NOT NULL,
  `direction` enum('IMPORT','EXPORT') NOT NULL,
  `transport_mode` enum('SEA','AIR','ROAD','RAIL','COURIER','PIPELINE') NOT NULL,
  `party_id` bigint unsigned NOT NULL,
  `forwarder_id` bigint unsigned DEFAULT NULL,
  `broker_id` bigint unsigned DEFAULT NULL,
  `carrier` varchar(120) DEFAULT NULL,
  `vessel` varchar(120) DEFAULT NULL,
  `voyage` varchar(40) DEFAULT NULL,
  `transport_doc_no` varchar(60) DEFAULT NULL,
  `transport_doc_date` date DEFAULT NULL,
  `transport_doc_type` enum('BL','AWB','LR','RR','CN','OTHER') DEFAULT NULL,
  `port_of_loading` varchar(10) NOT NULL,
  `port_of_discharge` varchar(10) NOT NULL,
  `place_of_delivery` varchar(120) DEFAULT NULL,
  `incoterm` char(3) NOT NULL,
  `etd` date DEFAULT NULL,
  `atd` date DEFAULT NULL,
  `eta` date DEFAULT NULL,
  `ata` date DEFAULT NULL,
  `free_time_expires_on` date DEFAULT NULL,
  `stage` enum('PLANNED','BOOKED','IN_TRANSIT','ARRIVED','UNDER_CLEARANCE','CLEARED','DELIVERED','CLOSED') NOT NULL DEFAULT 'PLANNED',
  `stage_label` varchar(80) DEFAULT NULL,
  `status` varchar(40) NOT NULL DEFAULT 'OPEN',
  `currency` char(3) NOT NULL,
  `goods_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `gross_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `net_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `volume_cbm` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `chargeable_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `container_count` smallint unsigned NOT NULL DEFAULT '0',
  `docs_required` smallint unsigned NOT NULL DEFAULT '0',
  `docs_received` smallint unsigned NOT NULL DEFAULT '0',
  `open_exceptions` smallint unsigned NOT NULL DEFAULT '0',
  `goods_in_transit_open` tinyint(1) NOT NULL DEFAULT '0',
  `cost_accrued` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `cost_actual` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `risk_transfer_date` date DEFAULT NULL,
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_by` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_shipment` (`entity_id`,`shipment_no`),
  KEY `ix_shp_list` (`entity_id`,`direction`,`stage`,`eta`,`id`),
  KEY `ix_shp_party` (`entity_id`,`party_id`,`eta`),
  KEY `ix_shp_doc` (`entity_id`,`transport_doc_no`),
  KEY `ix_shp_eta` (`entity_id`,`eta`,`id`),
  KEY `ix_shp_git` (`entity_id`,`goods_in_transit_open`,`ata`),
  KEY `ix_shp_freetime` (`entity_id`,`free_time_expires_on`),
  KEY `fk_shp_site` (`site_id`),
  KEY `fk_shp_party` (`party_id`),
  KEY `fk_shp_fwd` (`forwarder_id`),
  KEY `fk_shp_brk` (`broker_id`),
  KEY `fk_shp_incoterm` (`incoterm`),
  CONSTRAINT `fk_shp_brk` FOREIGN KEY (`broker_id`) REFERENCES `trade_party` (`id`),
  CONSTRAINT `fk_shp_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`),
  CONSTRAINT `fk_shp_fwd` FOREIGN KEY (`forwarder_id`) REFERENCES `trade_party` (`id`),
  CONSTRAINT `fk_shp_incoterm` FOREIGN KEY (`incoterm`) REFERENCES `incoterm` (`code`),
  CONSTRAINT `fk_shp_party` FOREIGN KEY (`party_id`) REFERENCES `trade_party` (`id`),
  CONSTRAINT `fk_shp_site` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shipment`
--

LOCK TABLES `shipment` WRITE;
/*!40000 ALTER TABLE `shipment` DISABLE KEYS */;
INSERT INTO `shipment` VALUES (1,1,1,'SHP-2026-04471','IMPORT','SEA',2,3,4,'Ocean Star Lines','MV Pacific Trader','026E','OSLNSA2604471','2026-06-22','BL','KRPUS','INNSA',NULL,'CIF','2026-06-20','2026-06-22','2026-07-08','2026-07-09','2026-07-16','UNDER_CLEARANCE','Under clearance','Under clearance','USD',184500.0000,6320.000000,5950.000000,0.000000,0.000000,2,13,11,3,0,0.0000,0.0000,NULL,1,NULL,'2026-08-05 13:02:21.366','2026-08-05 13:02:21.366'),(2,1,1,'SHP-2026-04502','EXPORT','SEA',5,3,4,'Baltic Container Line','MV Hansa Bremen','118W','BCLHAM2604502','2026-07-30','BL','INNSA','DEHAM',NULL,'FOB','2026-07-29','2026-07-30','2026-08-24',NULL,'2026-08-03','CLEARED','Documents with bank','Documents presented','EUR',342800.0000,9860.000000,9320.000000,0.000000,0.000000,1,11,11,1,0,0.0000,0.0000,NULL,1,NULL,'2026-08-05 13:02:21.399','2026-08-05 13:02:21.399'),(3,1,1,'SHP-2026-04518','IMPORT','AIR',10,3,4,'SkyCargo',NULL,NULL,'176-44821905','2026-08-01','AWB','SEGOT','INBOM',NULL,'FCA','2026-08-01','2026-08-01','2026-08-03','2026-08-03',NULL,'ARRIVED','Arrived','Arrived','EUR',96400.0000,1120.000000,986.000000,0.000000,0.000000,0,10,7,2,0,0.0000,0.0000,NULL,1,NULL,'2026-08-05 13:02:21.411','2026-08-05 13:02:21.411'),(4,1,1,'SHP-2026-04530','EXPORT','SEA',6,3,4,'Gulf Feeder Services',NULL,NULL,NULL,NULL,'BL','INNSA','AEJEA',NULL,'CFR','2026-08-12',NULL,'2026-08-19',NULL,NULL,'PLANNED','Planned','Planned','USD',128600.0000,3120.000000,2880.000000,0.000000,0.000000,0,9,2,2,0,0.0000,0.0000,NULL,1,NULL,'2026-08-05 13:02:21.418','2026-08-05 13:02:21.418'),(5,1,1,'SHP-2026-04412','IMPORT','SEA',2,3,4,'Ocean Star Lines','MV Pacific Trader','024E','OSLNSA2604412','2026-05-18','BL','KRPUS','INNSA',NULL,'CIF','2026-05-16','2026-05-18','2026-06-02','2026-06-02','2026-06-09','CLEARED','Costed','Cost sheet open','USD',96200.0000,3980.000000,3720.000000,0.000000,0.000000,1,13,13,1,0,0.0000,0.0000,NULL,1,NULL,'2026-08-05 13:02:21.423','2026-08-05 13:02:21.423');
/*!40000 ALTER TABLE `shipment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shipment_line`
--

DROP TABLE IF EXISTS `shipment_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment_line` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shipment_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `line_no` smallint unsigned NOT NULL,
  `order_line_id` bigint unsigned DEFAULT NULL,
  `item_id` bigint unsigned DEFAULT NULL,
  `item_code` varchar(40) NOT NULL,
  `description` varchar(300) NOT NULL,
  `qty` decimal(20,6) NOT NULL,
  `uom` varchar(10) NOT NULL,
  `unit_price` decimal(20,6) NOT NULL,
  `line_value` decimal(20,4) NOT NULL,
  `currency` char(3) NOT NULL,
  `net_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `gross_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `volume_cbm` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `container_no` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sl` (`shipment_id`,`line_no`),
  KEY `ix_sl_orderline` (`order_line_id`),
  KEY `ix_sl_item` (`entity_id`,`item_id`),
  CONSTRAINT `fk_sl_ol` FOREIGN KEY (`order_line_id`) REFERENCES `trade_order_line` (`id`),
  CONSTRAINT `fk_sl_shp` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shipment_line`
--

LOCK TABLES `shipment_line` WRITE;
/*!40000 ALTER TABLE `shipment_line` DISABLE KEYS */;
/*!40000 ALTER TABLE `shipment_line` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shipment_milestone`
--

DROP TABLE IF EXISTS `shipment_milestone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment_milestone` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shipment_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `seq` smallint unsigned NOT NULL,
  `milestone_key` varchar(40) NOT NULL,
  `label` varchar(120) NOT NULL,
  `planned_on` date DEFAULT NULL,
  `revised_on` date DEFAULT NULL,
  `actual_on` date DEFAULT NULL,
  `source` enum('MANUAL','CARRIER','BROKER','PORTAL','SYSTEM') NOT NULL DEFAULT 'MANUAL',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sm` (`shipment_id`,`milestone_key`),
  KEY `ix_sm_due` (`entity_id`,`actual_on`,`planned_on`),
  CONSTRAINT `fk_sm_shp` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shipment_milestone`
--

LOCK TABLES `shipment_milestone` WRITE;
/*!40000 ALTER TABLE `shipment_milestone` DISABLE KEYS */;
INSERT INTO `shipment_milestone` VALUES (1,1,1,1,'booked','Booking confirmed','2026-06-12',NULL,'2026-06-18','MANUAL'),(2,1,1,2,'gateIn','Gate in at origin','2026-06-18',NULL,'2026-06-20','MANUAL'),(3,1,1,3,'onBoard','Loaded on board','2026-06-20',NULL,'2026-06-22','MANUAL'),(4,1,1,4,'departed','Vessel departed','2026-06-20',NULL,'2026-06-22','MANUAL'),(5,1,1,5,'arrived','Vessel arrived','2026-07-08',NULL,'2026-07-09','MANUAL'),(6,1,1,6,'igmFiled','Arrival manifest filed','2026-07-09',NULL,'2026-07-09','MANUAL'),(7,1,1,7,'declFiled','Declaration filed','2026-07-07',NULL,'2026-07-07','MANUAL'),(8,1,1,8,'assessed','Assessed','2026-07-10',NULL,NULL,'MANUAL'),(9,1,1,9,'dutyPaid','Duty paid','2026-07-10',NULL,NULL,'MANUAL'),(10,1,1,10,'examined','Examination','2026-07-11',NULL,NULL,'MANUAL'),(11,1,1,11,'cleared','Out of charge','2026-07-11',NULL,NULL,'MANUAL'),(12,1,1,12,'gateOut','Gate out','2026-07-12',NULL,NULL,'MANUAL'),(13,1,1,13,'delivered','Delivered at site','2026-07-13',NULL,NULL,'MANUAL'),(14,1,1,14,'emptyReturn','Empty returned','2026-07-15',NULL,NULL,'MANUAL'),(15,2,1,1,'booked','Booking confirmed','2026-07-16',NULL,'2026-07-16','MANUAL'),(16,2,1,2,'stuffed','Container stuffed','2026-07-24',NULL,'2026-07-25','MANUAL'),(17,2,1,3,'declFiled','Shipping bill filed','2026-07-26',NULL,'2026-07-26','MANUAL'),(18,2,1,4,'leo','Let export order','2026-07-28',NULL,'2026-07-28','MANUAL'),(19,2,1,5,'onBoard','Loaded on board','2026-07-29',NULL,'2026-07-30','MANUAL'),(20,2,1,6,'egmFiled','Export manifest filed','2026-07-31',NULL,'2026-07-31','MANUAL'),(21,2,1,7,'docsDispatched','Documents to bank','2026-08-01',NULL,'2026-08-01','MANUAL'),(22,2,1,8,'arrived','Vessel arrival','2026-08-24',NULL,NULL,'MANUAL'),(23,3,1,1,'booked','Booking confirmed','2026-07-28',NULL,'2026-07-28','MANUAL'),(24,3,1,2,'departed','Flight departed','2026-08-01',NULL,'2026-08-01','MANUAL'),(25,3,1,3,'arrived','Flight arrived','2026-08-03',NULL,'2026-08-03','MANUAL'),(26,3,1,4,'declFiled','Declaration filed','2026-08-04',NULL,NULL,'MANUAL'),(27,3,1,5,'cleared','Out of charge','2026-08-05',NULL,NULL,'MANUAL'),(28,4,1,1,'booked','Booking confirmed','2026-08-06',NULL,NULL,'MANUAL'),(29,4,1,2,'stuffed','Container stuffed','2026-08-10',NULL,NULL,'MANUAL'),(30,4,1,3,'declFiled','Shipping bill filed','2026-08-11',NULL,NULL,'MANUAL'),(31,5,1,1,'arrived','Vessel arrived','2026-06-02',NULL,'2026-06-02','MANUAL'),(32,5,1,2,'cleared','Out of charge','2026-06-05',NULL,'2026-06-06','MANUAL'),(33,5,1,3,'delivered','Delivered at site','2026-06-08',NULL,'2026-06-08','MANUAL');
/*!40000 ALTER TABLE `shipment_milestone` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shipment_order`
--

DROP TABLE IF EXISTS `shipment_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment_order` (
  `shipment_id` bigint unsigned NOT NULL,
  `order_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`shipment_id`,`order_id`),
  KEY `ix_so_order` (`order_id`),
  CONSTRAINT `fk_so_ord` FOREIGN KEY (`order_id`) REFERENCES `trade_order` (`id`),
  CONSTRAINT `fk_so_shp` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shipment_order`
--

LOCK TABLES `shipment_order` WRITE;
/*!40000 ALTER TABLE `shipment_order` DISABLE KEYS */;
INSERT INTO `shipment_order` VALUES (1,1),(5,1),(2,2),(3,3),(4,4);
/*!40000 ALTER TABLE `shipment_order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `site`
--

DROP TABLE IF EXISTS `site`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `site` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(200) NOT NULL,
  `gstin` varchar(15) DEFAULT NULL,
  `state_code` varchar(10) DEFAULT NULL,
  `is_bonded` tinyint(1) NOT NULL DEFAULT '0',
  `bond_licence` varchar(50) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_site` (`entity_id`,`code`),
  CONSTRAINT `fk_site_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `site`
--

LOCK TABLES `site` WRITE;
/*!40000 ALTER TABLE `site` DISABLE KEYS */;
INSERT INTO `site` VALUES (1,1,'PUN1','Pune Unit I','27AABCH1234K1Z8','27',0,NULL,'2026-08-05 13:02:21.111','2026-08-05 13:02:21.111'),(2,1,'PUN2','Pune Unit II (bonded)','27AABCH1234K1Z8','27',1,'MOOWR/2025/0009','2026-08-05 13:02:21.113','2026-08-05 13:02:21.113');
/*!40000 ALTER TABLE `site` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sourcing_quote`
--

DROP TABLE IF EXISTS `sourcing_quote`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sourcing_quote` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `rfq_no` varchar(40) NOT NULL,
  `rfq_date` date NOT NULL,
  `item_desc` varchar(240) DEFAULT NULL,
  `supplier` varchar(160) DEFAULT NULL,
  `country_code` varchar(2) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'USD',
  `unit_price` decimal(16,4) NOT NULL DEFAULT '0.0000',
  `lead_time_days` int NOT NULL DEFAULT '0',
  `landed_estimate` decimal(18,2) NOT NULL DEFAULT '0.00',
  `status` varchar(24) NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (`id`),
  KEY `ix_srcq_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sourcing_quote`
--

LOCK TABLES `sourcing_quote` WRITE;
/*!40000 ALTER TABLE `sourcing_quote` DISABLE KEYS */;
INSERT INTO `sourcing_quote` VALUES (1,1,'RFQ-2026-0301','2026-06-15','Precision bearings, sealed','Hanwha Precision Co','KR','USD',6.8000,35,1846500.00,'AWARDED'),(2,1,'RFQ-2026-0312','2026-07-02','Hex bolts, grade 8.8','Zhejiang Fastener Works','CN','USD',0.0900,28,512000.00,'REJECTED'),(3,1,'RFQ-2026-0320','2026-07-18','Servo controller cards','Bosch Rexroth AG','DE','EUR',210.0000,45,2210400.00,'SHORTLISTED');
/*!40000 ALTER TABLE `sourcing_quote` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statement_mapping`
--

DROP TABLE IF EXISTS `statement_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `statement_mapping` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `statement` enum('BALANCE_SHEET','PROFIT_AND_LOSS','CASH_FLOW','EQUITY','NOTE') NOT NULL,
  `caption` varchar(200) NOT NULL,
  `note_ref` varchar(10) DEFAULT NULL,
  `seq_no` smallint unsigned NOT NULL,
  `sign` tinyint NOT NULL DEFAULT '1',
  `version` varchar(20) NOT NULL DEFAULT 'v1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sm` (`entity_id`,`statement`,`caption`,`version`),
  KEY `ix_sm_seq` (`entity_id`,`statement`,`seq_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `statement_mapping`
--

LOCK TABLES `statement_mapping` WRITE;
/*!40000 ALTER TABLE `statement_mapping` DISABLE KEYS */;
/*!40000 ALTER TABLE `statement_mapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statement_mapping_account`
--

DROP TABLE IF EXISTS `statement_mapping_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `statement_mapping_account` (
  `mapping_id` bigint unsigned NOT NULL,
  `account_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`mapping_id`,`account_id`),
  KEY `fk_sma_account` (`account_id`),
  CONSTRAINT `fk_sma_account` FOREIGN KEY (`account_id`) REFERENCES `gl_account` (`id`),
  CONSTRAINT `fk_sma_mapping` FOREIGN KEY (`mapping_id`) REFERENCES `statement_mapping` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `statement_mapping_account`
--

LOCK TABLES `statement_mapping_account` WRITE;
/*!40000 ALTER TABLE `statement_mapping_account` DISABLE KEYS */;
/*!40000 ALTER TABLE `statement_mapping_account` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stock_balance`
--

DROP TABLE IF EXISTS `stock_balance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_balance` (
  `entity_id` bigint unsigned NOT NULL,
  `site_id` bigint unsigned NOT NULL,
  `item_id` bigint unsigned NOT NULL,
  `period_key` int unsigned NOT NULL,
  `is_bonded` tinyint(1) NOT NULL DEFAULT '0',
  `opening_qty` decimal(24,6) NOT NULL DEFAULT '0.000000',
  `opening_value` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `in_qty` decimal(24,6) NOT NULL DEFAULT '0.000000',
  `in_value` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `out_qty` decimal(24,6) NOT NULL DEFAULT '0.000000',
  `out_value` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `closing_qty` decimal(24,6) NOT NULL DEFAULT '0.000000',
  `closing_value` decimal(24,4) NOT NULL DEFAULT '0.0000',
  `wavg_unit_cost` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`entity_id`,`site_id`,`item_id`,`period_key`,`is_bonded`),
  KEY `ix_sb_period` (`entity_id`,`period_key`,`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stock_balance`
--

LOCK TABLES `stock_balance` WRITE;
/*!40000 ALTER TABLE `stock_balance` DISABLE KEYS */;
/*!40000 ALTER TABLE `stock_balance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stock_ledger`
--

DROP TABLE IF EXISTS `stock_ledger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_ledger` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `period_key` int unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `site_id` bigint unsigned NOT NULL,
  `item_id` bigint unsigned NOT NULL,
  `lot_no` varchar(40) DEFAULT NULL,
  `txn_date` date NOT NULL,
  `txn_type` enum('RECEIPT','ISSUE','TRANSFER_IN','TRANSFER_OUT','ADJUST_UP','ADJUST_DOWN','REVALUE','SCRAP','RETURN') NOT NULL,
  `source_type` varchar(40) DEFAULT NULL,
  `source_id` bigint unsigned DEFAULT NULL,
  `qty` decimal(20,6) NOT NULL,
  `uom` varchar(10) NOT NULL,
  `unit_cost` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `goods_component` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `duty_component` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `freight_component` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `other_component` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `is_bonded` tinyint(1) NOT NULL DEFAULT '0',
  `voucher_id` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`period_key`,`id`),
  KEY `ix_stk_id` (`id`),
  KEY `ix_stk_item` (`entity_id`,`site_id`,`item_id`,`period_key`,`txn_date`,`id`),
  KEY `ix_stk_lot` (`entity_id`,`item_id`,`lot_no`,`txn_date`),
  KEY `ix_stk_source` (`source_type`,`source_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50100 PARTITION BY RANGE (`period_key`)
(PARTITION p2025 VALUES LESS THAN (202601) ENGINE = InnoDB,
 PARTITION p202601 VALUES LESS THAN (202602) ENGINE = InnoDB,
 PARTITION p202602 VALUES LESS THAN (202603) ENGINE = InnoDB,
 PARTITION p202603 VALUES LESS THAN (202604) ENGINE = InnoDB,
 PARTITION p202604 VALUES LESS THAN (202605) ENGINE = InnoDB,
 PARTITION p202605 VALUES LESS THAN (202606) ENGINE = InnoDB,
 PARTITION p202606 VALUES LESS THAN (202607) ENGINE = InnoDB,
 PARTITION p202607 VALUES LESS THAN (202608) ENGINE = InnoDB,
 PARTITION p202608 VALUES LESS THAN (202609) ENGINE = InnoDB,
 PARTITION p202609 VALUES LESS THAN (202610) ENGINE = InnoDB,
 PARTITION p202610 VALUES LESS THAN (202611) ENGINE = InnoDB,
 PARTITION p202611 VALUES LESS THAN (202612) ENGINE = InnoDB,
 PARTITION p202612 VALUES LESS THAN (202701) ENGINE = InnoDB,
 PARTITION p202701 VALUES LESS THAN (202702) ENGINE = InnoDB,
 PARTITION p202702 VALUES LESS THAN (202703) ENGINE = InnoDB,
 PARTITION p202703 VALUES LESS THAN (202704) ENGINE = InnoDB,
 PARTITION p202704 VALUES LESS THAN (202705) ENGINE = InnoDB,
 PARTITION p202705 VALUES LESS THAN (202706) ENGINE = InnoDB,
 PARTITION p202706 VALUES LESS THAN (202707) ENGINE = InnoDB,
 PARTITION p202707 VALUES LESS THAN (202708) ENGINE = InnoDB,
 PARTITION p202708 VALUES LESS THAN (202709) ENGINE = InnoDB,
 PARTITION p202709 VALUES LESS THAN (202710) ENGINE = InnoDB,
 PARTITION p202710 VALUES LESS THAN (202711) ENGINE = InnoDB,
 PARTITION p202711 VALUES LESS THAN (202712) ENGINE = InnoDB,
 PARTITION p202712 VALUES LESS THAN (202801) ENGINE = InnoDB,
 PARTITION pmax VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stock_ledger`
--

LOCK TABLES `stock_ledger` WRITE;
/*!40000 ALTER TABLE `stock_ledger` DISABLE KEYS */;
/*!40000 ALTER TABLE `stock_ledger` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stuffing`
--

DROP TABLE IF EXISTS `stuffing`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stuffing` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `stuffing_no` varchar(40) NOT NULL,
  `stuffing_date` date NOT NULL,
  `shipment_no` varchar(40) DEFAULT NULL,
  `container_no` varchar(24) DEFAULT NULL,
  `location` varchar(80) DEFAULT NULL,
  `supervisor` varchar(120) DEFAULT NULL,
  `packages` int NOT NULL DEFAULT '0',
  `gross_weight_kg` decimal(14,2) NOT NULL DEFAULT '0.00',
  `status` varchar(24) NOT NULL DEFAULT 'PLANNED',
  PRIMARY KEY (`id`),
  KEY `ix_stuff_entity` (`entity_id`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stuffing`
--

LOCK TABLES `stuffing` WRITE;
/*!40000 ALTER TABLE `stuffing` DISABLE KEYS */;
INSERT INTO `stuffing` VALUES (1,1,'STF-2026-0091','2026-07-22','SHP-2026-04512','MSKU7788112','Pune ICD','R. Iyer',220,18400.00,'COMPLETED'),(2,1,'STF-2026-0095','2026-07-30','SHP-2026-04520','HLXU5540221','JNPT CFS','K. Menon',96,9100.00,'SEALED');
/*!40000 ALTER TABLE `stuffing` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `trade_agreement`
--

DROP TABLE IF EXISTS `trade_agreement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trade_agreement` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `name` varchar(160) NOT NULL,
  `in_force_from` date NOT NULL,
  `proof_modes` varchar(120) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_agreement` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `trade_agreement`
--

LOCK TABLES `trade_agreement` WRITE;
/*!40000 ALTER TABLE `trade_agreement` DISABLE KEYS */;
/*!40000 ALTER TABLE `trade_agreement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `trade_order`
--

DROP TABLE IF EXISTS `trade_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trade_order` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `site_id` bigint unsigned DEFAULT NULL,
  `order_no` varchar(40) NOT NULL,
  `direction` enum('IMPORT','EXPORT') NOT NULL,
  `order_date` date NOT NULL,
  `party_id` bigint unsigned NOT NULL,
  `currency` char(3) NOT NULL,
  `fx_rate_indicative` decimal(18,8) NOT NULL DEFAULT '1.00000000',
  `incoterm` char(3) NOT NULL,
  `named_place` varchar(120) NOT NULL,
  `transport_mode` enum('SEA','AIR','ROAD','RAIL','COURIER','PIPELINE') NOT NULL,
  `port_of_loading` varchar(10) NOT NULL,
  `port_of_discharge` varchar(10) NOT NULL,
  `payment_term` varchar(60) NOT NULL,
  `instrument_id` bigint unsigned DEFAULT NULL,
  `shipment_window_from` date DEFAULT NULL,
  `shipment_window_to` date DEFAULT NULL,
  `zero_rating_route` enum('LUT','IGST','NA') NOT NULL DEFAULT 'NA',
  `order_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `order_value_func` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `shipped_value` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `status` enum('DRAFT','APPROVED','PART_SHIPPED','SHIPPED','CLOSED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  `approved_by` bigint unsigned DEFAULT NULL,
  `approved_at` datetime(3) DEFAULT NULL,
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_by` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_order` (`entity_id`,`order_no`),
  KEY `ix_order_list` (`entity_id`,`direction`,`order_date`,`id`),
  KEY `ix_order_party` (`entity_id`,`party_id`,`order_date`),
  KEY `ix_order_status` (`entity_id`,`status`,`order_date`),
  KEY `ix_order_instrument` (`instrument_id`),
  KEY `fk_ord_site` (`site_id`),
  KEY `fk_ord_party` (`party_id`),
  KEY `fk_ord_ccy` (`currency`),
  KEY `fk_ord_incoterm` (`incoterm`),
  CONSTRAINT `fk_ord_ccy` FOREIGN KEY (`currency`) REFERENCES `currency` (`code`),
  CONSTRAINT `fk_ord_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`),
  CONSTRAINT `fk_ord_incoterm` FOREIGN KEY (`incoterm`) REFERENCES `incoterm` (`code`),
  CONSTRAINT `fk_ord_party` FOREIGN KEY (`party_id`) REFERENCES `trade_party` (`id`),
  CONSTRAINT `fk_ord_site` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `trade_order`
--

LOCK TABLES `trade_order` WRITE;
/*!40000 ALTER TABLE `trade_order` DISABLE KEYS */;
INSERT INTO `trade_order` VALUES (1,1,1,'IPO-2026-0912','IMPORT','2026-05-28',2,'USD',1.00000000,'CIF','Nhava Sheva','SEA','KRPUS','INNSA','LC 60 days',1,'2026-06-10','2026-06-30','NA',184500.0000,0.0000,0.0000,'APPROVED',NULL,NULL,1,NULL,'2026-08-05 13:02:21.346','2026-08-05 13:02:21.346'),(2,1,1,'EXO-2026-0441','EXPORT','2026-06-14',5,'EUR',1.00000000,'FOB','Nhava Sheva','SEA','INNSA','DEHAM','LC at sight',2,'2026-07-20','2026-08-10','LUT',342800.0000,0.0000,0.0000,'APPROVED',NULL,NULL,1,NULL,'2026-08-05 13:02:21.356','2026-08-05 13:02:21.356'),(3,1,1,'IPO-2026-0948','IMPORT','2026-07-02',10,'EUR',1.00000000,'FCA','Gothenburg','SEA','SEGOT','INNSA','Open account 45 days',NULL,'2026-07-25','2026-08-15','NA',96400.0000,0.0000,0.0000,'APPROVED',NULL,NULL,1,NULL,'2026-08-05 13:02:21.359','2026-08-05 13:02:21.359'),(4,1,1,'EXO-2026-0468','EXPORT','2026-07-21',6,'USD',1.00000000,'CFR','Jebel Ali','SEA','INNSA','AEJEA','Advance 30% balance DP',NULL,'2026-08-05','2026-08-25','IGST',128600.0000,0.0000,0.0000,'APPROVED',NULL,NULL,1,NULL,'2026-08-05 13:02:21.362','2026-08-05 13:02:21.362'),(5,1,1,'IPO-2026-0955','IMPORT','2026-07-18',7,'USD',1.00000000,'FOB','Ningbo','SEA','CNNGB','INNSA','Advance 100%',NULL,'2026-08-01','2026-08-20','NA',41200.0000,0.0000,0.0000,'APPROVED',NULL,NULL,1,NULL,'2026-08-05 13:02:21.364','2026-08-05 13:02:21.364');
/*!40000 ALTER TABLE `trade_order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `trade_order_line`
--

DROP TABLE IF EXISTS `trade_order_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trade_order_line` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `line_no` smallint unsigned NOT NULL,
  `item_id` bigint unsigned DEFAULT NULL,
  `item_code` varchar(40) NOT NULL,
  `description` varchar(300) NOT NULL,
  `hs_code` varchar(12) DEFAULT NULL,
  `qty` decimal(20,6) NOT NULL,
  `uom` varchar(10) NOT NULL,
  `unit_price` decimal(20,6) NOT NULL,
  `line_value` decimal(20,4) NOT NULL,
  `currency` char(3) NOT NULL,
  `origin_country` char(2) DEFAULT NULL,
  `net_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `gross_weight_kg` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `volume_cbm` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `preference_agreement` varchar(20) DEFAULT NULL,
  `scheme_intent` varchar(120) DEFAULT NULL,
  `licence_id` bigint unsigned DEFAULT NULL,
  `est_landed_unit_cost` decimal(20,6) DEFAULT NULL,
  `qty_shipped` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `qty_cleared` decimal(20,6) NOT NULL DEFAULT '0.000000',
  `status` enum('OPEN','PART_SHIPPED','SHIPPED','CLOSED','CANCELLED') NOT NULL DEFAULT 'OPEN',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ol` (`order_id`,`line_no`),
  KEY `ix_ol_entity_item` (`entity_id`,`item_id`),
  KEY `ix_ol_licence` (`licence_id`),
  KEY `ix_ol_open` (`entity_id`,`status`,`order_id`),
  KEY `fk_ol_item` (`item_id`),
  CONSTRAINT `fk_ol_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`),
  CONSTRAINT `fk_ol_order` FOREIGN KEY (`order_id`) REFERENCES `trade_order` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `trade_order_line`
--

LOCK TABLES `trade_order_line` WRITE;
/*!40000 ALTER TABLE `trade_order_line` DISABLE KEYS */;
INSERT INTO `trade_order_line` VALUES (1,1,1,1,1,'HPB-4400','Bearing housing, cast steel','84821020',1200.000000,'PCS',42.500000,51000.0000,'USD','KR',2480.000000,0.000000,0.000000,'AIFTA','',NULL,4358.333333,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.349','2026-08-05 13:02:21.349'),(2,1,1,2,2,'HPB-4410','Precision bearing, sealed','84821010',4000.000000,'PCS',11.400000,45600.0000,'USD','KR',1240.000000,0.000000,0.000000,'AIFTA','',NULL,1052.500000,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.353','2026-08-05 13:02:21.353'),(3,1,1,3,3,'HPB-4420','Seal kit, nitrile','40169390',8000.000000,'PCS',3.100000,24800.0000,'USD','KR',1020.000000,0.000000,0.000000,NULL,'',NULL,297.500000,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.354','2026-08-05 13:02:21.354'),(4,1,1,4,4,'HPB-4430','Spindle assembly','84831099',600.000000,'PCS',71.200000,42720.0000,'USD','KR',1210.000000,0.000000,0.000000,NULL,'',NULL,6633.333333,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.355','2026-08-05 13:02:21.355'),(5,2,1,1,5,'FIN-8801','Machined gearbox housing','84839000',900.000000,'PCS',214.000000,192600.0000,'EUR','IN',5400.000000,0.000000,0.000000,NULL,'RoDTEP,Drawback',NULL,NULL,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.357','2026-08-05 13:02:21.357'),(6,2,1,2,6,'FIN-8815','Drive shaft, hardened','84832000',1400.000000,'PCS',106.000000,148400.0000,'EUR','IN',3920.000000,0.000000,0.000000,NULL,'RoDTEP',NULL,NULL,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.358','2026-08-05 13:02:21.358'),(7,3,1,1,7,'NC-2201','Hydraulic valve block','84811000',340.000000,'PCS',214.000000,72760.0000,'EUR','SE',890.000000,0.000000,0.000000,NULL,'',NULL,NULL,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.360','2026-08-05 13:02:21.360'),(8,3,1,2,8,'NC-2208','Servo controller card','85371000',120.000000,'PCS',197.000000,23640.0000,'EUR','SE',96.000000,0.000000,0.000000,NULL,'',NULL,NULL,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.361','2026-08-05 13:02:21.361'),(9,4,1,1,9,'FIN-9002','Pump assembly, industrial','84139200',480.000000,'PCS',268.000000,128640.0000,'USD','IN',2880.000000,0.000000,0.000000,NULL,'RoDTEP',NULL,NULL,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.363','2026-08-05 13:02:21.363'),(10,5,1,1,10,'ZF-1100','Hex bolt, grade 8.8','73181500',240000.000000,'PCS',0.170000,40800.0000,'USD','CN',4100.000000,0.000000,0.000000,NULL,'',NULL,NULL,0.000000,0.000000,'OPEN','2026-08-05 13:02:21.365','2026-08-05 13:02:21.365');
/*!40000 ALTER TABLE `trade_order_line` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `trade_party`
--

DROP TABLE IF EXISTS `trade_party`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trade_party` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `contact_code` varchar(30) NOT NULL,
  `name` varchar(200) NOT NULL,
  `legal_name` varchar(200) NOT NULL,
  `country_code` char(2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `gstin` varchar(15) DEFAULT NULL,
  `pan` varchar(10) DEFAULT NULL,
  `iec` varchar(20) DEFAULT NULL,
  `ledger_group` varchar(60) DEFAULT NULL,
  `ledger_account_id` bigint unsigned DEFAULT NULL,
  `default_incoterm` char(3) DEFAULT NULL,
  `default_payment_term` varchar(60) DEFAULT NULL,
  `is_related_party` tinyint(1) NOT NULL DEFAULT '0',
  `bank_verified` tinyint(1) NOT NULL DEFAULT '0',
  `bank_verified_by` bigint unsigned DEFAULT NULL,
  `bank_changed_at` datetime(3) DEFAULT NULL,
  `screening_status` enum('CLEAR','REVIEW','MATCH','NOT_SCREENED') NOT NULL DEFAULT 'NOT_SCREENED',
  `screened_at` datetime(3) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_party` (`entity_id`,`contact_code`),
  KEY `ix_party_name` (`entity_id`,`name`),
  KEY `ix_party_screening` (`entity_id`,`screening_status`),
  KEY `ix_party_country` (`entity_id`,`country_code`),
  KEY `fk_party_country` (`country_code`),
  CONSTRAINT `fk_party_country` FOREIGN KEY (`country_code`) REFERENCES `country` (`code`),
  CONSTRAINT `fk_party_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `trade_party`
--

LOCK TABLES `trade_party` WRITE;
/*!40000 ALTER TABLE `trade_party` DISABLE KEYS */;
INSERT INTO `trade_party` VALUES (1,1,'CON-006299','INDIA IMPEX','INDIA IMPEX','IN','INR','07AABFI8721R1ZP','AABFI8721R','0507012345','Sundry Debtors',NULL,NULL,NULL,0,1,NULL,NULL,'CLEAR','2026-07-28 09:00:00.000',1,1,'2026-08-05 13:02:21.255','2026-08-05 13:02:21.255'),(2,1,'CON-006301','Hanyang Precision Co','Hanyang Precision Co Ltd','KR','USD',NULL,NULL,NULL,'Sundry Creditors',NULL,'CIF','LC 60 days',0,1,NULL,NULL,'CLEAR','2026-08-01 09:00:00.000',1,1,'2026-08-05 13:02:21.259','2026-08-05 13:02:21.259'),(3,1,'CON-006344','Acme Global Logistics','Acme Global Logistics Pvt Ltd','IN','INR','27AACCA1234M1Z5',NULL,NULL,'Sundry Creditors',NULL,NULL,NULL,0,1,NULL,NULL,'CLEAR','2026-07-20 09:00:00.000',1,1,'2026-08-05 13:02:21.262','2026-08-05 13:02:21.262'),(4,1,'CON-006350','Bluewave Clearing','Bluewave Clearing & Forwarding','IN','INR','27AAGCB9911K1Z2',NULL,NULL,NULL,NULL,NULL,NULL,0,1,NULL,NULL,'CLEAR','2026-07-20 09:00:00.000',1,1,'2026-08-05 13:02:21.264','2026-08-05 13:02:21.264'),(5,1,'CON-006377','Meridian Industries GmbH','Meridian Industries GmbH','DE','EUR',NULL,NULL,NULL,'Sundry Debtors',NULL,'FOB','LC at sight',0,1,NULL,NULL,'CLEAR','2026-08-02 09:00:00.000',1,1,'2026-08-05 13:02:21.266','2026-08-05 13:02:21.266'),(6,1,'CON-006390','Orient Traders FZE','Orient Traders FZE','AE','USD',NULL,NULL,NULL,'Sundry Debtors',NULL,'CFR','Advance 30%',0,0,NULL,NULL,'REVIEW','2026-08-03 09:00:00.000',1,1,'2026-08-05 13:02:21.268','2026-08-05 13:02:21.268'),(7,1,'CON-006401','Zhejiang Fastener Works','Zhejiang Fastener Works Co','CN','USD',NULL,NULL,NULL,'Sundry Creditors',NULL,NULL,NULL,0,0,NULL,NULL,'MATCH','2026-08-04 09:00:00.000',1,1,'2026-08-05 13:02:21.270','2026-08-05 13:02:21.270'),(8,1,'CON-006412','Sundar Roadways','Sundar Roadways Pvt Ltd','IN','INR','27AAECS5522L1ZQ',NULL,NULL,NULL,NULL,NULL,NULL,0,1,NULL,NULL,'CLEAR','2026-06-30 09:00:00.000',1,1,'2026-08-05 13:02:21.271','2026-08-05 13:02:21.271'),(9,1,'CON-006420','Sentinel Marine Insurance','Sentinel Marine Insurance Ltd','IN','INR',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,NULL,NULL,'CLEAR','2026-05-15 09:00:00.000',1,1,'2026-08-05 13:02:21.273','2026-08-05 13:02:21.273'),(10,1,'CON-006433','Nordic Components AB','Nordic Components AB','SE','EUR',NULL,NULL,NULL,'Sundry Creditors',NULL,'FCA','Open account 45 days',1,1,NULL,NULL,'CLEAR','2026-07-11 09:00:00.000',1,1,'2026-08-05 13:02:21.275','2026-08-05 13:02:21.275'),(11,1,'BANK-STATE','State Bank of India, Mumbai','State Bank of India, Mumbai','IN','INR',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,NULL,NULL,'CLEAR',NULL,1,1,'2026-08-05 13:02:21.277','2026-08-05 13:02:21.277'),(12,1,'BANK-WOORI','Woori Bank, Seoul','Woori Bank, Seoul','KR','INR',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,NULL,NULL,'CLEAR',NULL,1,1,'2026-08-05 13:02:21.279','2026-08-05 13:02:21.279'),(13,1,'BANK-COMMER','Commerzbank AG, Hamburg','Commerzbank AG, Hamburg','DE','INR',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,NULL,NULL,'CLEAR',NULL,1,1,'2026-08-05 13:02:21.281','2026-08-05 13:02:21.281'),(14,1,'BANK-HDFCB','HDFC Bank, Mumbai','HDFC Bank, Mumbai','IN','INR',NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,NULL,NULL,'CLEAR',NULL,1,1,'2026-08-05 13:02:21.282','2026-08-05 13:02:21.282');
/*!40000 ALTER TABLE `trade_party` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `trade_party_role`
--

DROP TABLE IF EXISTS `trade_party_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trade_party_role` (
  `party_id` bigint unsigned NOT NULL,
  `role` enum('CUSTOMER','SUPPLIER','MANUFACTURER','CONSIGNEE','NOTIFY','FORWARDER','BROKER','TRANSPORTER','INSPECTION','INSURER','BANK') NOT NULL,
  PRIMARY KEY (`party_id`,`role`),
  CONSTRAINT `fk_tpr_party` FOREIGN KEY (`party_id`) REFERENCES `trade_party` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `trade_party_role`
--

LOCK TABLES `trade_party_role` WRITE;
/*!40000 ALTER TABLE `trade_party_role` DISABLE KEYS */;
INSERT INTO `trade_party_role` VALUES (1,'CUSTOMER'),(2,'SUPPLIER'),(2,'MANUFACTURER'),(3,'FORWARDER'),(4,'BROKER'),(5,'CUSTOMER'),(6,'CUSTOMER'),(7,'SUPPLIER'),(8,'TRANSPORTER'),(9,'INSURER'),(10,'SUPPLIER'),(10,'MANUFACTURER'),(11,'BANK'),(12,'BANK'),(13,'BANK'),(14,'BANK');
/*!40000 ALTER TABLE `trade_party_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `uom`
--

DROP TABLE IF EXISTS `uom`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `uom` (
  `code` varchar(10) NOT NULL,
  `name` varchar(60) NOT NULL,
  `uom_class` varchar(20) NOT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uom`
--

LOCK TABLES `uom` WRITE;
/*!40000 ALTER TABLE `uom` DISABLE KEYS */;
INSERT INTO `uom` VALUES ('BOX','Box','count'),('CBM','Cubic metre','volume'),('EA','Each','count'),('KG','Kilogram','mass'),('LTR','Litre','volume'),('MT','Metric tonne','mass'),('NOS','Numbers','count'),('PCS','Pieces','count'),('ROLL','Roll','count'),('SET','Set','count');
/*!40000 ALTER TABLE `uom` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_clearing_ageing`
--

DROP TABLE IF EXISTS `v_clearing_ageing`;
/*!50001 DROP VIEW IF EXISTS `v_clearing_ageing`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_clearing_ageing` AS SELECT 
 1 AS `entity_id`,
 1 AS `book_id`,
 1 AS `account_id`,
 1 AS `account_code`,
 1 AS `account_name`,
 1 AS `shipment_id`,
 1 AS `oldest_entry`,
 1 AS `age_days`,
 1 AS `total_dr`,
 1 AS `total_cr`,
 1 AS `net_balance`,
 1 AS `line_count`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_cost_sheet_summary`
--

DROP TABLE IF EXISTS `v_cost_sheet_summary`;
/*!50001 DROP VIEW IF EXISTS `v_cost_sheet_summary`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_cost_sheet_summary` AS SELECT 
 1 AS `entity_id`,
 1 AS `cost_sheet_id`,
 1 AS `cost_sheet_no`,
 1 AS `status`,
 1 AS `direction`,
 1 AS `shipment_no`,
 1 AS `transport_doc_no`,
 1 AS `goods_value`,
 1 AS `total_estimate`,
 1 AS `total_accrued`,
 1 AS `total_actual`,
 1 AS `variance_invoiced`,
 1 AS `uninvoiced_accrual`,
 1 AS `capitalised_amount`,
 1 AS `expensed_amount`,
 1 AS `recoverable_amount`,
 1 AS `landed_value_to_date`,
 1 AS `tolerance_breaches`,
 1 AS `stock_on_hand_pct`,
 1 AS `closed_on`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_declaration_register`
--

DROP TABLE IF EXISTS `v_declaration_register`;
/*!50001 DROP VIEW IF EXISTS `v_declaration_register`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_declaration_register` AS SELECT 
 1 AS `entity_id`,
 1 AS `period_key`,
 1 AS `declaration_id`,
 1 AS `declaration_no`,
 1 AS `declaration_type`,
 1 AS `direction`,
 1 AS `declaration_date`,
 1 AS `filed_on`,
 1 AS `cleared_on`,
 1 AS `status`,
 1 AS `is_provisional`,
 1 AS `port_code`,
 1 AS `currency`,
 1 AS `statutory_fx_rate`,
 1 AS `assessable_value`,
 1 AS `duty_total`,
 1 AS `duty_recoverable`,
 1 AS `duty_inventoriable`,
 1 AS `duty_assessed`,
 1 AS `duty_assessment_difference`,
 1 AS `duty_saved`,
 1 AS `duty_blocked`,
 1 AS `error_count`,
 1 AS `warning_count`,
 1 AS `party_name`,
 1 AS `party_country`,
 1 AS `shipment_no`,
 1 AS `transport_doc_no`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_document_gaps`
--

DROP TABLE IF EXISTS `v_document_gaps`;
/*!50001 DROP VIEW IF EXISTS `v_document_gaps`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_document_gaps` AS SELECT 
 1 AS `entity_id`,
 1 AS `object_type`,
 1 AS `object_id`,
 1 AS `doc_type`,
 1 AS `title`,
 1 AS `doc_ref`,
 1 AS `created_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_duty_by_levy`
--

DROP TABLE IF EXISTS `v_duty_by_levy`;
/*!50001 DROP VIEW IF EXISTS `v_duty_by_levy`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_duty_by_levy` AS SELECT 
 1 AS `entity_id`,
 1 AS `period_key`,
 1 AS `levy_code`,
 1 AS `levy_name`,
 1 AS `rate_source`,
 1 AS `line_count`,
 1 AS `duty_amount`,
 1 AS `recoverable_amount`,
 1 AS `inventoriable_amount`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_licence_status`
--

DROP TABLE IF EXISTS `v_licence_status`;
/*!50001 DROP VIEW IF EXISTS `v_licence_status`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_licence_status` AS SELECT 
 1 AS `entity_id`,
 1 AS `licence_id`,
 1 AS `licence_no`,
 1 AS `scheme_code`,
 1 AS `scheme_name`,
 1 AS `status`,
 1 AS `issued_on`,
 1 AS `import_valid_to`,
 1 AS `export_valid_to`,
 1 AS `cif_entitlement`,
 1 AS `cif_utilised`,
 1 AS `cif_available`,
 1 AS `duty_saved`,
 1 AS `obligation_type`,
 1 AS `obligation_amount`,
 1 AS `obligation_fulfilled`,
 1 AS `pct_fulfilled`,
 1 AS `obligation_shortfall`,
 1 AS `exposure_duty`,
 1 AS `exposure_interest`,
 1 AS `total_exposure`,
 1 AS `days_to_deadline`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_open_exceptions`
--

DROP TABLE IF EXISTS `v_open_exceptions`;
/*!50001 DROP VIEW IF EXISTS `v_open_exceptions`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_open_exceptions` AS SELECT 
 1 AS `entity_id`,
 1 AS `exception_id`,
 1 AS `rule_id`,
 1 AS `severity`,
 1 AS `exception_type`,
 1 AS `title`,
 1 AS `detail`,
 1 AS `object_type`,
 1 AS `object_id`,
 1 AS `object_ref`,
 1 AS `exposure`,
 1 AS `deadline_on`,
 1 AS `age_days`,
 1 AS `owner_user_id`,
 1 AS `severity_weight`,
 1 AS `rank_score`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_trial_balance`
--

DROP TABLE IF EXISTS `v_trial_balance`;
/*!50001 DROP VIEW IF EXISTS `v_trial_balance`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_trial_balance` AS SELECT 
 1 AS `entity_id`,
 1 AS `book_id`,
 1 AS `period_key`,
 1 AS `account_id`,
 1 AS `account_code`,
 1 AS `account_name`,
 1 AS `account_class`,
 1 AS `account_type`,
 1 AS `schedule_iii_group`,
 1 AS `subledger`,
 1 AS `is_monetary`,
 1 AS `opening_dr`,
 1 AS `opening_cr`,
 1 AS `period_dr`,
 1 AS `period_cr`,
 1 AS `closing_dr`,
 1 AS `closing_cr`,
 1 AS `net_balance`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `voucher`
--

DROP TABLE IF EXISTS `voucher`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `voucher` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `period_key` int unsigned NOT NULL,
  `entity_id` bigint unsigned NOT NULL,
  `book_id` bigint unsigned NOT NULL,
  `voucher_type_id` bigint unsigned NOT NULL,
  `voucher_no` varchar(40) DEFAULT NULL,
  `voucher_date` date NOT NULL,
  `narration` varchar(1000) NOT NULL,
  `status` enum('PARKED','PENDING_APPROVAL','POSTED','REVERSED','CANCELLED') NOT NULL DEFAULT 'PARKED',
  `source_type` varchar(40) DEFAULT NULL,
  `source_id` bigint unsigned DEFAULT NULL,
  `business_event` varchar(60) DEFAULT NULL,
  `posting_rule_code` varchar(30) DEFAULT NULL,
  `posting_rule_version` varchar(10) DEFAULT NULL,
  `currency` char(3) NOT NULL DEFAULT 'INR',
  `fx_rate` decimal(18,8) NOT NULL DEFAULT '1.00000000',
  `total_dr` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `total_cr` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `prepared_by` bigint unsigned NOT NULL,
  `prepared_by_name` varchar(200) DEFAULT NULL,
  `approved_by` bigint unsigned DEFAULT NULL,
  `approved_by_name` varchar(200) DEFAULT NULL,
  `posted_at` datetime(3) DEFAULT NULL,
  `reversal_of_id` bigint unsigned DEFAULT NULL,
  `reversed_by_id` bigint unsigned DEFAULT NULL,
  `cancel_reason` varchar(500) DEFAULT NULL,
  `evidence_complete` tinyint(1) NOT NULL DEFAULT '0',
  `row_version` int unsigned NOT NULL DEFAULT '1',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `book_label` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`period_key`,`id`),
  UNIQUE KEY `uq_voucher_no` (`entity_id`,`voucher_type_id`,`voucher_no`,`period_key`),
  KEY `ix_voucher_id` (`id`),
  KEY `ix_voucher_register` (`entity_id`,`period_key`,`voucher_type_id`,`status`),
  KEY `ix_voucher_status` (`entity_id`,`status`,`voucher_date`),
  KEY `ix_voucher_source` (`source_type`,`source_id`),
  KEY `ix_voucher_date` (`entity_id`,`voucher_date`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50100 PARTITION BY RANGE (`period_key`)
(PARTITION p2025 VALUES LESS THAN (202601) ENGINE = InnoDB,
 PARTITION p202601 VALUES LESS THAN (202602) ENGINE = InnoDB,
 PARTITION p202602 VALUES LESS THAN (202603) ENGINE = InnoDB,
 PARTITION p202603 VALUES LESS THAN (202604) ENGINE = InnoDB,
 PARTITION p202604 VALUES LESS THAN (202605) ENGINE = InnoDB,
 PARTITION p202605 VALUES LESS THAN (202606) ENGINE = InnoDB,
 PARTITION p202606 VALUES LESS THAN (202607) ENGINE = InnoDB,
 PARTITION p202607 VALUES LESS THAN (202608) ENGINE = InnoDB,
 PARTITION p202608 VALUES LESS THAN (202609) ENGINE = InnoDB,
 PARTITION p202609 VALUES LESS THAN (202610) ENGINE = InnoDB,
 PARTITION p202610 VALUES LESS THAN (202611) ENGINE = InnoDB,
 PARTITION p202611 VALUES LESS THAN (202612) ENGINE = InnoDB,
 PARTITION p202612 VALUES LESS THAN (202701) ENGINE = InnoDB,
 PARTITION p202701 VALUES LESS THAN (202702) ENGINE = InnoDB,
 PARTITION p202702 VALUES LESS THAN (202703) ENGINE = InnoDB,
 PARTITION p202703 VALUES LESS THAN (202704) ENGINE = InnoDB,
 PARTITION p202704 VALUES LESS THAN (202705) ENGINE = InnoDB,
 PARTITION p202705 VALUES LESS THAN (202706) ENGINE = InnoDB,
 PARTITION p202706 VALUES LESS THAN (202707) ENGINE = InnoDB,
 PARTITION p202707 VALUES LESS THAN (202708) ENGINE = InnoDB,
 PARTITION p202708 VALUES LESS THAN (202709) ENGINE = InnoDB,
 PARTITION p202709 VALUES LESS THAN (202710) ENGINE = InnoDB,
 PARTITION p202710 VALUES LESS THAN (202711) ENGINE = InnoDB,
 PARTITION p202711 VALUES LESS THAN (202712) ENGINE = InnoDB,
 PARTITION p202712 VALUES LESS THAN (202801) ENGINE = InnoDB,
 PARTITION pmax VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `voucher`
--

LOCK TABLES `voucher` WRITE;
/*!40000 ALTER TABLE `voucher` DISABLE KEYS */;
INSERT INTO `voucher` VALUES (7,202606,1,1,10,'LCV/2026-27/00033','2026-06-30','Landed cost closure SHP-2026-04412 — differential split by stock position 18% on hand','PARKED',NULL,NULL,NULL,'PR-IMP-11','v2','INR',1.00000000,21200.0000,21200.0000,17,'M. Shah',NULL,NULL,NULL,NULL,NULL,NULL,1,1,'2026-08-05 13:02:21.601','2026-08-05 13:02:21.601','Primary'),(1,202607,1,1,1,'PJV/2026-27/00418','2026-07-12','Goods receipt against BOE-4471 / SHP-2026-04471 at estimated landed cost','POSTED','goodsReceipt',NULL,'goodsReceipt','PR-IMP-08','v3','INR',1.00000000,14833983.2800,14833983.2800,14,'A. Kulkarni',13,'S. Menon','2026-07-12 14:22:00.000',NULL,NULL,NULL,1,1,'2026-08-05 13:02:21.549','2026-08-05 13:02:21.549','Primary'),(2,202607,1,1,4,'DTY/2026-27/00212','2026-07-10','Customs duty and levies assessed on BOE-4471 — recoverable and inventoriable split','POSTED','declaration',NULL,'declaration','PR-IMP-05','v3','INR',1.00000000,3452336.6200,3452336.6200,14,'A. Kulkarni',13,'S. Menon','2026-07-10 14:22:00.000',NULL,NULL,NULL,1,1,'2026-08-05 13:02:21.576','2026-08-05 13:02:21.576','Primary'),(3,202607,1,1,5,'SIV/2026-27/00094','2026-07-30','Export invoice EXP/2026/0441 to Meridian Industries GmbH — LUT, without payment of IGST','POSTED','exportInvoice',NULL,'exportInvoice','PR-EXP-02','v2','EUR',1.00000000,33045920.0000,33045920.0000,14,'A. Kulkarni',13,'S. Menon','2026-07-30 14:22:00.000',NULL,NULL,NULL,1,1,'2026-08-05 13:02:21.582','2026-08-05 13:02:21.582','Primary'),(4,202607,1,1,11,'ENT/2026-27/00061','2026-07-31','RoDTEP entitlement accrued on SB-0119 — recognised on sanction per Ind AS 20','POSTED','entitlementClaim',NULL,'entitlementClaim','PR-EXP-10','v4','INR',1.00000000,260064.0000,260064.0000,14,'A. Kulkarni',13,'S. Menon','2026-07-31 14:22:00.000',NULL,NULL,NULL,1,1,'2026-08-05 13:02:21.588','2026-08-05 13:02:21.588','Primary'),(5,202607,1,1,9,'JVM/2026-27/00027','2026-07-31','Reclassification of demurrage wrongly capitalised on SHP-2026-04412','PENDING_APPROVAL',NULL,NULL,NULL,NULL,NULL,'INR',1.00000000,18000.0000,18000.0000,15,'R. Iyer',NULL,NULL,NULL,NULL,NULL,NULL,0,1,'2026-08-05 13:02:21.592','2026-08-05 13:02:21.592','Primary'),(6,202607,1,1,12,'FXR/2026-27/00004','2026-07-31','Period-end revaluation of foreign currency monetary items at closing rate — auto-reversing','POSTED',NULL,NULL,NULL,'PR-PER-02','v2','INR',1.00000000,412000.0000,412000.0000,14,'A. Kulkarni',13,'S. Menon','2026-07-31 14:22:00.000',NULL,NULL,NULL,1,1,'2026-08-05 13:02:21.597','2026-08-05 13:02:21.597','Primary');
/*!40000 ALTER TABLE `voucher` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `voucher_evidence`
--

DROP TABLE IF EXISTS `voucher_evidence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `voucher_evidence` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `voucher_id` bigint unsigned NOT NULL,
  `period_key` int unsigned NOT NULL,
  `doc_type` varchar(80) NOT NULL,
  `file_name` varchar(300) DEFAULT NULL,
  `storage_key` varchar(400) DEFAULT NULL,
  `checksum` char(64) DEFAULT NULL,
  `issuer` varchar(160) DEFAULT NULL,
  `doc_ref` varchar(80) DEFAULT NULL,
  `doc_date` date DEFAULT NULL,
  `is_mandatory` tinyint(1) NOT NULL DEFAULT '1',
  `is_attached` tinyint(1) NOT NULL DEFAULT '0',
  `version_no` smallint unsigned NOT NULL DEFAULT '0',
  `superseded_by` bigint unsigned DEFAULT NULL,
  `size_kb` int unsigned DEFAULT NULL,
  `uploaded_by` bigint unsigned DEFAULT NULL,
  `uploaded_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_ve_voucher` (`voucher_id`),
  KEY `ix_ve_missing` (`voucher_id`,`is_mandatory`,`is_attached`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `voucher_evidence`
--

LOCK TABLES `voucher_evidence` WRITE;
/*!40000 ALTER TABLE `voucher_evidence` DISABLE KEYS */;
INSERT INTO `voucher_evidence` VALUES (1,1,202607,'Supplier invoice','HANYANG-INV-88412.pdf',NULL,NULL,'Hanyang Precision Co','INV-88412','2026-06-20',1,1,1,NULL,184,NULL,NULL),(2,1,202607,'Packing list','HANYANG-PL-88412.pdf',NULL,NULL,'Hanyang Precision Co','PL-88412','2026-06-20',1,1,1,NULL,96,NULL,NULL),(3,1,202607,'Bill of entry','BOE-4471.pdf',NULL,NULL,'Customs','4471021','2026-07-07',1,1,1,NULL,240,NULL,NULL),(4,1,202607,'Goods receipt note','GRN-2026-0881.pdf',NULL,NULL,'Stores','GRN-2026-0881','2026-07-12',1,1,1,NULL,72,NULL,NULL),(5,2,202607,'Bill of entry','BOE-4471.pdf',NULL,NULL,'Customs','4471021','2026-07-07',1,1,1,NULL,240,NULL,NULL),(6,2,202607,'Assessment','ASSESS-4471021.pdf',NULL,NULL,'Customs','4471021','2026-07-10',1,1,1,NULL,118,NULL,NULL),(7,3,202607,'Export order','EXO-2026-0441.pdf',NULL,NULL,NULL,NULL,NULL,1,1,1,NULL,88,NULL,NULL),(8,3,202607,'Shipping bill','SB-0119.pdf',NULL,NULL,'Customs','0119284','2026-07-26',1,1,1,NULL,210,NULL,NULL),(9,3,202607,'Packing list','PL-0441.pdf',NULL,NULL,NULL,NULL,NULL,1,1,1,NULL,74,NULL,NULL),(10,4,202607,'Shipping bill','SB-0119.pdf',NULL,NULL,NULL,NULL,NULL,1,1,1,NULL,210,NULL,NULL),(11,4,202607,'Sanction / scroll','SCROLL-1188.pdf',NULL,NULL,NULL,NULL,NULL,1,1,1,NULL,64,NULL,NULL),(12,5,202607,'Reason note','JV-27-reason.pdf',NULL,NULL,NULL,NULL,NULL,1,1,1,NULL,42,NULL,NULL),(13,5,202607,'Supporting computation','demurrage-calc.xlsx',NULL,NULL,NULL,NULL,NULL,1,0,0,NULL,NULL,NULL,NULL),(14,6,202607,'Rate source','closing-rates-2026-07-31.pdf',NULL,NULL,NULL,NULL,NULL,1,1,1,NULL,30,NULL,NULL),(15,7,202606,'Cost sheet','CS-003.pdf',NULL,NULL,NULL,NULL,NULL,1,1,1,NULL,92,NULL,NULL);
/*!40000 ALTER TABLE `voucher_evidence` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `voucher_type`
--

DROP TABLE IF EXISTS `voucher_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `voucher_type` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `code` varchar(10) NOT NULL,
  `name` varchar(160) NOT NULL,
  `document_class` enum('FINANCIAL','INVENTORY','STATUTORY','MEMORANDUM') NOT NULL,
  `statutory_series` tinyint(1) NOT NULL DEFAULT '0',
  `posts_on` enum('SAVE','APPROVAL') NOT NULL DEFAULT 'APPROVAL',
  `reversible` tinyint(1) NOT NULL DEFAULT '1',
  `required_evidence` varchar(600) NOT NULL DEFAULT '',
  `approval_matrix` varchar(300) DEFAULT NULL,
  `print_format` varchar(120) DEFAULT NULL,
  `retention_years` tinyint unsigned NOT NULL DEFAULT '8',
  `books` varchar(80) NOT NULL DEFAULT 'PRIMARY',
  `allow_soft_closed` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vtype` (`entity_id`,`code`),
  CONSTRAINT `fk_vt_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `voucher_type`
--

LOCK TABLES `voucher_type` WRITE;
/*!40000 ALTER TABLE `voucher_type` DISABLE KEYS */;
INSERT INTO `voucher_type` VALUES (1,1,'PJV','Purchase / goods receipt voucher','INVENTORY',0,'APPROVAL',1,'Supplier invoice; Packing list; Bill of entry; Goods receipt note','Value band — stores then finance','GRN / purchase voucher',8,'PRIMARY,TAX',0),(2,1,'PIV','Purchase invoice voucher','FINANCIAL',0,'APPROVAL',1,'Supplier invoice; Purchase order; Goods receipt','Value band — AP then controller','Purchase voucher',8,'PRIMARY,TAX',0),(3,1,'SVI','Service invoice voucher','FINANCIAL',0,'APPROVAL',1,'Provider invoice; Rate contract reference','Value band — logistics then AP','Service voucher',8,'PRIMARY,TAX',0),(4,1,'DTY','Duty and levy voucher','STATUTORY',0,'APPROVAL',0,'Bill of entry; Assessment','Compliance then finance','Duty voucher',8,'PRIMARY,TAX',0),(5,1,'SIV','Sales invoice voucher — export','STATUTORY',1,'APPROVAL',0,'Export order; Shipping bill reference; Packing list','Documentation then finance','Export tax invoice',8,'PRIMARY,TAX',0),(6,1,'CNV','Credit note voucher','STATUTORY',1,'APPROVAL',0,'Original invoice; Reason; Approval','Value band — controller above threshold','Credit note',8,'PRIMARY,TAX',0),(7,1,'PMT','Payment voucher','FINANCIAL',0,'APPROVAL',1,'Approved payable; Bank advice','Value band — treasury then CFO','Payment advice',8,'PRIMARY',0),(8,1,'RCP','Receipt voucher','FINANCIAL',0,'APPROVAL',1,'Bank advice','AR then controller','Receipt voucher',8,'PRIMARY',0),(9,1,'JVM','Journal voucher — manual','FINANCIAL',0,'APPROVAL',1,'Reason note; Supporting computation','One level above preparer; controller above threshold','Journal voucher',8,'PRIMARY,TAX,GROUP',0),(10,1,'LCV','Landed cost voucher','INVENTORY',0,'APPROVAL',0,'Cost sheet; Allocation trace','Cost accountant then controller','Landed cost statement',8,'PRIMARY',0),(11,1,'ENT','Entitlement voucher','FINANCIAL',0,'APPROVAL',1,'Shipping bill; Claim or sanction record','Export head then finance','Entitlement voucher',8,'PRIMARY',0),(12,1,'FXR','Foreign exchange revaluation voucher','FINANCIAL',0,'SAVE',1,'Rate source; Run log','Controller','Revaluation register',8,'PRIMARY,GROUP',0),(13,1,'BND','Bonded movement voucher','MEMORANDUM',0,'APPROVAL',0,'Declaration; Facility record','Compliance officer','Bonded movement note',8,'PRIMARY,MEMORANDUM',0);
/*!40000 ALTER TABLE `voucher_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_task`
--

DROP TABLE IF EXISTS `work_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_task` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` bigint unsigned NOT NULL,
  `task_kind` varchar(40) NOT NULL,
  `title` varchar(300) NOT NULL,
  `detail` varchar(1000) NOT NULL,
  `severity` enum('CRITICAL','HIGH','MEDIUM','INFO') NOT NULL DEFAULT 'MEDIUM',
  `object_type` varchar(40) NOT NULL,
  `object_id` bigint unsigned NOT NULL,
  `route` varchar(200) NOT NULL,
  `due_on` date DEFAULT NULL,
  `assigned_user_id` bigint unsigned DEFAULT NULL,
  `assigned_role_id` bigint unsigned DEFAULT NULL,
  `status` enum('OPEN','IN_PROGRESS','DONE','CANCELLED') NOT NULL DEFAULT 'OPEN',
  `completed_by` bigint unsigned DEFAULT NULL,
  `completed_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `ix_wt_inbox` (`entity_id`,`assigned_user_id`,`status`,`severity`,`due_on`),
  KEY `ix_wt_role` (`entity_id`,`assigned_role_id`,`status`),
  KEY `ix_wt_object` (`entity_id`,`object_type`,`object_id`),
  CONSTRAINT `fk_wt_entity` FOREIGN KEY (`entity_id`) REFERENCES `legal_entity` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_task`
--

LOCK TABLES `work_task` WRITE;
/*!40000 ALTER TABLE `work_task` DISABLE KEYS */;
INSERT INTO `work_task` VALUES (1,1,'exception','Attach origin proof or drop preferential claim','BOE-4471 line 2 — preferential duty saving blocked','CRITICAL','declaration',1,'/import/declarations/D-001','2026-08-05',NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.621','2026-08-05 13:02:21.621'),(2,1,'deadline','Present documents under LC/2026/0918','Presentation deadline 05-Aug-2026; one certificate unsigned','CRITICAL','instrument',2,'/finance/presentations/I-002','2026-08-05',NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.624','2026-08-05 13:02:21.624'),(3,1,'review','Dispose screening match — Orient Traders FZE','Score 87 on list refresh; order release blocked','CRITICAL','party',6,'/compliance/screening','2026-08-05',NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.626','2026-08-05 13:02:21.626'),(4,1,'approval','Approve duty variance on BOE-4471','Assessed amount exceeds the module’s own computation by ₹21,400','HIGH','declaration',1,'/import/declarations/D-001',NULL,NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.627','2026-08-05 13:02:21.627'),(5,1,'approval','Approve JVM/2026-27/00027','Manual journal — demurrage reclassification; supporting computation not attached','HIGH','voucher',0,'/accounting/vouchers/V-005',NULL,NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.628','2026-08-05 13:02:21.628'),(6,1,'exception','Close cost sheet CS-003','Open 58 days; 2 provider invoices awaited; ₹2,12,000 uninvoiced accrual','HIGH','costSheet',2,'/finance/landed-cost/CS-003',NULL,NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.629','2026-08-05 13:02:21.629'),(7,1,'review','Confirm classification on 4 items','Tariff schedule re-baselined 01-May-2026; 4 items on split headings','HIGH','item',0,'/setup/items',NULL,NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.630','2026-08-05 13:02:21.630'),(8,1,'exception','EPCG/2024/0117 obligation projected short','Block 1 projected completion 06-Feb-2028 against deadline 13-Mar-2028','HIGH','licence',1,'/compliance/licences/L-001',NULL,NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.631','2026-08-05 13:02:21.631'),(9,1,'exception','Reconcile 9 overdue EDPMS entries','₹89,40,000 unreconciled beyond the realisation period','HIGH','reconciliation',0,'/finance/reconciliations/R-04',NULL,NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.632','2026-08-05 13:02:21.632'),(10,1,'query','Answer customs query on BOE-4471','Valuation query raised 09-Jul-2026, reply due 12-Jul-2026','HIGH','declaration',1,'/import/declarations/D-001','2026-08-06',NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.633','2026-08-05 13:02:21.633'),(11,1,'approval','Verify beneficiary bank details — Orient Traders','Changed 01-Aug-2026; payment suspended pending dual verification','MEDIUM','party',6,'/setup/parties/P-006',NULL,NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.634','2026-08-05 13:02:21.634'),(12,1,'exception','Attach missing evidence to LCV/2026-27/00033','Parked voucher; allocation trace attached, cost sheet sign-off pending','MEDIUM','voucher',0,'/accounting/vouchers/V-007',NULL,NULL,NULL,'OPEN',NULL,NULL,'2026-08-05 13:02:21.635','2026-08-05 13:02:21.635');
/*!40000 ALTER TABLE `work_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'hb_tenant_acme'
--

--
-- Dumping routines for database 'hb_tenant_acme'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_add_month_partition` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`hb_app`@`%` PROCEDURE `sp_add_month_partition`(IN p_table VARCHAR(64), IN p_period INT)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_check_rollup` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`hb_app`@`%` PROCEDURE `sp_check_rollup`(IN p_entity BIGINT UNSIGNED, IN p_period INT)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_extend_partitions` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`hb_app`@`%` PROCEDURE `sp_extend_partitions`(IN p_period INT)
BEGIN
  CALL sp_add_month_partition('voucher',          p_period);
  CALL sp_add_month_partition('posting_line',     p_period);
  CALL sp_add_month_partition('declaration',      p_period);
  CALL sp_add_month_partition('declaration_line', p_period);
  CALL sp_add_month_partition('declaration_levy', p_period);
  CALL sp_add_month_partition('stock_ledger',     p_period);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Current Database: `hb_tenant_acme`
--

USE `hb_tenant_acme`;

--
-- Final view structure for view `v_clearing_ageing`
--

/*!50001 DROP VIEW IF EXISTS `v_clearing_ageing`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hb_app`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_clearing_ageing` AS select `pl`.`entity_id` AS `entity_id`,`pl`.`book_id` AS `book_id`,`pl`.`account_id` AS `account_id`,`a`.`code` AS `account_code`,`a`.`name` AS `account_name`,`pl`.`shipment_id` AS `shipment_id`,min(`pl`.`voucher_date`) AS `oldest_entry`,(to_days(curdate()) - to_days(min(`pl`.`voucher_date`))) AS `age_days`,sum((case when (`pl`.`dr_cr` = 'DR') then `pl`.`amount_func` else 0 end)) AS `total_dr`,sum((case when (`pl`.`dr_cr` = 'CR') then `pl`.`amount_func` else 0 end)) AS `total_cr`,sum((case when (`pl`.`dr_cr` = 'DR') then `pl`.`amount_func` else -(`pl`.`amount_func`) end)) AS `net_balance`,count(0) AS `line_count` from (`posting_line` `pl` join `gl_account` `a` on((`a`.`id` = `pl`.`account_id`))) where (`a`.`account_type` = 'CLEARING') group by `pl`.`entity_id`,`pl`.`book_id`,`pl`.`account_id`,`a`.`code`,`a`.`name`,`pl`.`shipment_id` having (`net_balance` <> 0) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_cost_sheet_summary`
--

/*!50001 DROP VIEW IF EXISTS `v_cost_sheet_summary`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hb_app`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_cost_sheet_summary` AS select `cs`.`entity_id` AS `entity_id`,`cs`.`id` AS `cost_sheet_id`,`cs`.`cost_sheet_no` AS `cost_sheet_no`,`cs`.`status` AS `status`,`cs`.`direction` AS `direction`,`sh`.`shipment_no` AS `shipment_no`,`sh`.`transport_doc_no` AS `transport_doc_no`,`cs`.`goods_value` AS `goods_value`,`cs`.`total_estimate` AS `total_estimate`,`cs`.`total_accrued` AS `total_accrued`,`cs`.`total_actual` AS `total_actual`,`cs`.`variance_invoiced` AS `variance_invoiced`,`cs`.`uninvoiced_accrual` AS `uninvoiced_accrual`,`cs`.`capitalised_amount` AS `capitalised_amount`,`cs`.`expensed_amount` AS `expensed_amount`,`cs`.`recoverable_amount` AS `recoverable_amount`,(`cs`.`goods_value` + `cs`.`total_actual`) AS `landed_value_to_date`,`cs`.`tolerance_breaches` AS `tolerance_breaches`,`cs`.`stock_on_hand_pct` AS `stock_on_hand_pct`,`cs`.`closed_on` AS `closed_on` from (`cost_sheet` `cs` join `shipment` `sh` on((`sh`.`id` = `cs`.`shipment_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_declaration_register`
--

/*!50001 DROP VIEW IF EXISTS `v_declaration_register`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hb_app`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_declaration_register` AS select `d`.`entity_id` AS `entity_id`,`d`.`period_key` AS `period_key`,`d`.`id` AS `declaration_id`,`d`.`declaration_no` AS `declaration_no`,`d`.`declaration_type` AS `declaration_type`,`d`.`direction` AS `direction`,`d`.`declaration_date` AS `declaration_date`,`d`.`filed_on` AS `filed_on`,`d`.`cleared_on` AS `cleared_on`,`d`.`status` AS `status`,`d`.`is_provisional` AS `is_provisional`,`d`.`port_code` AS `port_code`,`d`.`currency` AS `currency`,`d`.`statutory_fx_rate` AS `statutory_fx_rate`,`d`.`assessable_value` AS `assessable_value`,`d`.`duty_total` AS `duty_total`,`d`.`duty_recoverable` AS `duty_recoverable`,`d`.`duty_inventoriable` AS `duty_inventoriable`,`d`.`duty_assessed` AS `duty_assessed`,(`d`.`duty_assessed` - `d`.`duty_total`) AS `duty_assessment_difference`,`d`.`duty_saved` AS `duty_saved`,`d`.`duty_blocked` AS `duty_blocked`,`d`.`error_count` AS `error_count`,`d`.`warning_count` AS `warning_count`,`p`.`name` AS `party_name`,`p`.`country_code` AS `party_country`,`s`.`shipment_no` AS `shipment_no`,`s`.`transport_doc_no` AS `transport_doc_no` from ((`declaration` `d` left join `trade_party` `p` on((`p`.`id` = `d`.`party_id`))) left join `shipment` `s` on((`s`.`id` = `d`.`shipment_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_document_gaps`
--

/*!50001 DROP VIEW IF EXISTS `v_document_gaps`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hb_app`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_document_gaps` AS select `document`.`entity_id` AS `entity_id`,`document`.`object_type` AS `object_type`,`document`.`object_id` AS `object_id`,`document`.`doc_type` AS `doc_type`,`document`.`title` AS `title`,`document`.`doc_ref` AS `doc_ref`,`document`.`created_at` AS `created_at` from `document` where ((`document`.`is_mandatory` = 1) and (`document`.`is_received` = 0)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_duty_by_levy`
--

/*!50001 DROP VIEW IF EXISTS `v_duty_by_levy`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hb_app`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_duty_by_levy` AS select `declaration_levy`.`entity_id` AS `entity_id`,`declaration_levy`.`period_key` AS `period_key`,`declaration_levy`.`levy_code` AS `levy_code`,`declaration_levy`.`levy_name` AS `levy_name`,`declaration_levy`.`rate_source` AS `rate_source`,count(0) AS `line_count`,sum(`declaration_levy`.`amount`) AS `duty_amount`,sum((case when (`declaration_levy`.`is_recoverable` = 1) then `declaration_levy`.`amount` else 0 end)) AS `recoverable_amount`,sum((case when (`declaration_levy`.`is_recoverable` = 0) then `declaration_levy`.`amount` else 0 end)) AS `inventoriable_amount` from `declaration_levy` group by `declaration_levy`.`entity_id`,`declaration_levy`.`period_key`,`declaration_levy`.`levy_code`,`declaration_levy`.`levy_name`,`declaration_levy`.`rate_source` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_licence_status`
--

/*!50001 DROP VIEW IF EXISTS `v_licence_status`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hb_app`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_licence_status` AS select `l`.`entity_id` AS `entity_id`,`l`.`id` AS `licence_id`,`l`.`licence_no` AS `licence_no`,`s`.`code` AS `scheme_code`,`s`.`name` AS `scheme_name`,`l`.`status` AS `status`,`l`.`issued_on` AS `issued_on`,`l`.`import_valid_to` AS `import_valid_to`,`l`.`export_valid_to` AS `export_valid_to`,`l`.`cif_entitlement` AS `cif_entitlement`,`l`.`cif_utilised` AS `cif_utilised`,(`l`.`cif_entitlement` - `l`.`cif_utilised`) AS `cif_available`,`l`.`duty_saved` AS `duty_saved`,`l`.`obligation_type` AS `obligation_type`,`l`.`obligation_amount` AS `obligation_amount`,`l`.`obligation_fulfilled` AS `obligation_fulfilled`,(case when (`l`.`obligation_amount` = 0) then 100.0000 else round(((100 * `l`.`obligation_fulfilled`) / `l`.`obligation_amount`),4) end) AS `pct_fulfilled`,greatest((`l`.`obligation_amount` - `l`.`obligation_fulfilled`),0) AS `obligation_shortfall`,`l`.`exposure_duty` AS `exposure_duty`,`l`.`exposure_interest` AS `exposure_interest`,(`l`.`exposure_duty` + `l`.`exposure_interest`) AS `total_exposure`,(to_days(`l`.`export_valid_to`) - to_days(curdate())) AS `days_to_deadline` from (`licence` `l` join `scheme` `s` on((`s`.`id` = `l`.`scheme_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_open_exceptions`
--

/*!50001 DROP VIEW IF EXISTS `v_open_exceptions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hb_app`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_open_exceptions` AS select `e`.`entity_id` AS `entity_id`,`e`.`id` AS `exception_id`,`e`.`rule_id` AS `rule_id`,`e`.`severity` AS `severity`,`e`.`exception_type` AS `exception_type`,`e`.`title` AS `title`,`e`.`detail` AS `detail`,`e`.`object_type` AS `object_type`,`e`.`object_id` AS `object_id`,`e`.`object_ref` AS `object_ref`,`e`.`exposure` AS `exposure`,`e`.`deadline_on` AS `deadline_on`,`e`.`age_days` AS `age_days`,`e`.`owner_user_id` AS `owner_user_id`,(case `e`.`severity` when 'CRITICAL' then 4 when 'HIGH' then 3 when 'MEDIUM' then 2 else 1 end) AS `severity_weight`,((((case `e`.`severity` when 'CRITICAL' then 4 when 'HIGH' then 3 when 'MEDIUM' then 2 else 1 end) * 1000000) + least(`e`.`exposure`,999999)) + least(`e`.`age_days`,999)) AS `rank_score` from `exception_item` `e` where (`e`.`is_open` = 1) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_trial_balance`
--

/*!50001 DROP VIEW IF EXISTS `v_trial_balance`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`hb_app`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `v_trial_balance` AS select `b`.`entity_id` AS `entity_id`,`b`.`book_id` AS `book_id`,`b`.`period_key` AS `period_key`,`a`.`id` AS `account_id`,`a`.`code` AS `account_code`,`a`.`name` AS `account_name`,`a`.`account_class` AS `account_class`,`a`.`account_type` AS `account_type`,`a`.`schedule_iii_group` AS `schedule_iii_group`,`a`.`subledger` AS `subledger`,`a`.`is_monetary` AS `is_monetary`,`b`.`opening_dr` AS `opening_dr`,`b`.`opening_cr` AS `opening_cr`,`b`.`period_dr` AS `period_dr`,`b`.`period_cr` AS `period_cr`,(`b`.`opening_dr` + `b`.`period_dr`) AS `closing_dr`,(`b`.`opening_cr` + `b`.`period_cr`) AS `closing_cr`,((`b`.`opening_dr` + `b`.`period_dr`) - (`b`.`opening_cr` + `b`.`period_cr`)) AS `net_balance` from (`account_period_balance` `b` join `gl_account` `a` on((`a`.`id` = `b`.`account_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-08-05 13:09:48
