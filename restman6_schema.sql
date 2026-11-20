-- RestMan6 - Physical database schema for ERD / report
-- MySQL-compatible DDL. Creates 23 tables; does not drop or replace existing data.
-- Source: supplied whole-system design class diagram.
-- StatCustomer6, StatDish6, StatIngredient6, StatSupplier6 are derived reports.
-- Subclass id is both PRIMARY KEY and FOREIGN KEY; it is not independently generated.
-- Scalar names/types follow the diagram, including paymenttDate and Category6.attribute.
-- Minimum cardinalities were not specified: non-key columns are left nullable.
-- Booking overlap/concurrency handling belongs to the reservation transaction logic.

CREATE TABLE `tblMember6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(100),
  `password` VARCHAR(255),
  `fullName` VARCHAR(255),
  `address` VARCHAR(255),
  `email` VARCHAR(255),
  `phone` VARCHAR(20),
  `role` VARCHAR(50),
  `note` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblSupplier6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255),
  `address` VARCHAR(255),
  `phone` VARCHAR(20),
  `email` VARCHAR(255),
  `description` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblIngredient6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255),
  `unit` VARCHAR(50),
  `stockQuantity` FLOAT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblCategory6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255),
  `description` VARCHAR(255),
  `attribute` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblCombo6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255),
  `price` FLOAT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblDiningTable6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255),
  `capacity` INT,
  `location` VARCHAR(255),
  `status` VARCHAR(50),
  `description` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblCustomer6` (
  `id` INT NOT NULL,
  `rewardPoints` INT,
  `cardRank` VARCHAR(50),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblCustomer6_id` FOREIGN KEY (`id`) REFERENCES `tblMember6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblStaff6` (
  `id` INT NOT NULL,
  `position` VARCHAR(100),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblStaff6_id` FOREIGN KEY (`id`) REFERENCES `tblMember6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblDish6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255),
  `price` FLOAT,
  `unit` VARCHAR(50),
  `image` VARCHAR(255),
  `description` VARCHAR(255),
  `tblCategory6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblDish6_tblCategory6id` FOREIGN KEY (`tblCategory6id`) REFERENCES `tblCategory6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblSaleStaff6` (
  `id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblSaleStaff6_id` FOREIGN KEY (`id`) REFERENCES `tblStaff6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblInventoryStaff6` (
  `id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblInventoryStaff6_id` FOREIGN KEY (`id`) REFERENCES `tblStaff6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblManager6` (
  `id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblManager6_id` FOREIGN KEY (`id`) REFERENCES `tblStaff6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblComboDish6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `quantity` INT,
  `tblCombo6id` INT,
  `tblDish6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblComboDish6_tblCombo6id` FOREIGN KEY (`tblCombo6id`) REFERENCES `tblCombo6` (`id`),
  CONSTRAINT `fk_tblComboDish6_tblDish6id` FOREIGN KEY (`tblDish6id`) REFERENCES `tblDish6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblTableReservation6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `createdAt` DATETIME,
  `arrivalTime` DATETIME,
  `endTime` DATETIME,
  `guestNumber` INT,
  `contactName` VARCHAR(255),
  `contactEmail` VARCHAR(255),
  `contactPhone` VARCHAR(20),
  `status` VARCHAR(50),
  `tblCustomer6id` INT,
  `tblSaleStaff6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblTableReservation6_tblCustomer6id` FOREIGN KEY (`tblCustomer6id`) REFERENCES `tblCustomer6` (`id`),
  CONSTRAINT `fk_tblTableReservation6_tblSaleStaff6id` FOREIGN KEY (`tblSaleStaff6id`) REFERENCES `tblSaleStaff6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblInvoice6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `paymenttDate` DATETIME,
  `totalAmount` FLOAT,
  `discountAmount` FLOAT,
  `finalAmount` FLOAT,
  `paymentMethod` VARCHAR(50),
  `tblCustomer6id` INT,
  `tblSaleStaff6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblInvoice6_tblCustomer6id` FOREIGN KEY (`tblCustomer6id`) REFERENCES `tblCustomer6` (`id`),
  CONSTRAINT `fk_tblInvoice6_tblSaleStaff6id` FOREIGN KEY (`tblSaleStaff6id`) REFERENCES `tblSaleStaff6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblOnlineOrder6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `orderTime` DATETIME,
  `orderAddress` VARCHAR(255),
  `status` VARCHAR(50),
  `totalAmount` INT,
  `tblCustomer6id` INT,
  `tblSaleStaff6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblOnlineOrder6_tblCustomer6id` FOREIGN KEY (`tblCustomer6id`) REFERENCES `tblCustomer6` (`id`),
  CONSTRAINT `fk_tblOnlineOrder6_tblSaleStaff6id` FOREIGN KEY (`tblSaleStaff6id`) REFERENCES `tblSaleStaff6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblImportOrder6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `importDate` DATETIME,
  `importAmount` FLOAT,
  `tblSupplier6id` INT,
  `tblInventoryStaff6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblImportOrder6_tblSupplier6id` FOREIGN KEY (`tblSupplier6id`) REFERENCES `tblSupplier6` (`id`),
  CONSTRAINT `fk_tblImportOrder6_tblInventoryStaff6id` FOREIGN KEY (`tblInventoryStaff6id`) REFERENCES `tblInventoryStaff6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblReservationDetail6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `tblTableReservation6id` INT,
  `tblDiningTable6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblReservationDetail6_tblTableReservation6id` FOREIGN KEY (`tblTableReservation6id`) REFERENCES `tblTableReservation6` (`id`),
  CONSTRAINT `fk_tblReservationDetail6_tblDiningTable6id` FOREIGN KEY (`tblDiningTable6id`) REFERENCES `tblDiningTable6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblOrder6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `orderTime` DATETIME,
  `status` VARCHAR(50),
  `tblInvoice6id` INT,
  `tblDiningTable6id` INT,
  `tblTableReservation6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblOrder6_tblInvoice6id` FOREIGN KEY (`tblInvoice6id`) REFERENCES `tblInvoice6` (`id`),
  CONSTRAINT `fk_tblOrder6_tblDiningTable6id` FOREIGN KEY (`tblDiningTable6id`) REFERENCES `tblDiningTable6` (`id`),
  CONSTRAINT `fk_tblOrder6_tblTableReservation6id` FOREIGN KEY (`tblTableReservation6id`) REFERENCES `tblTableReservation6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblOnlineOrderItem6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `quantity` INT,
  `price` FLOAT,
  `tblOnlineOrder6id` INT,
  `tblDish6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblOnlineOrderItem6_tblOnlineOrder6id` FOREIGN KEY (`tblOnlineOrder6id`) REFERENCES `tblOnlineOrder6` (`id`),
  CONSTRAINT `fk_tblOnlineOrderItem6_tblDish6id` FOREIGN KEY (`tblDish6id`) REFERENCES `tblDish6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblImportOrderItem6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `quantity` FLOAT,
  `importPrice` FLOAT,
  `tblImportOrder6id` INT,
  `tblIngredient6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblImportOrderItem6_tblImportOrder6id` FOREIGN KEY (`tblImportOrder6id`) REFERENCES `tblImportOrder6` (`id`),
  CONSTRAINT `fk_tblImportOrderItem6_tblIngredient6id` FOREIGN KEY (`tblIngredient6id`) REFERENCES `tblIngredient6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblOrderDish6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `quantity` INT,
  `price` FLOAT,
  `note` VARCHAR(255),
  `tblOrder6id` INT,
  `tblDish6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblOrderDish6_tblOrder6id` FOREIGN KEY (`tblOrder6id`) REFERENCES `tblOrder6` (`id`),
  CONSTRAINT `fk_tblOrderDish6_tblDish6id` FOREIGN KEY (`tblDish6id`) REFERENCES `tblDish6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tblOrderComboItem6` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `quantity` INT,
  `price` FLOAT,
  `note` VARCHAR(255),
  `tblOrder6id` INT,
  `tblCombo6id` INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_tblOrderComboItem6_tblOrder6id` FOREIGN KEY (`tblOrder6id`) REFERENCES `tblOrder6` (`id`),
  CONSTRAINT `fk_tblOrderComboItem6_tblCombo6id` FOREIGN KEY (`tblCombo6id`) REFERENCES `tblCombo6` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

