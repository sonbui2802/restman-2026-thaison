-- Run as a MySQL administrator; do not change the original schema file.
CREATE DATABASE IF NOT EXISTS restman CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'restman'@'localhost' IDENTIFIED BY 'restman123';
-- MySQL requires UPDATE permission for SELECT ... FOR UPDATE locking reads.
GRANT SELECT, INSERT, UPDATE ON restman.* TO 'restman'@'localhost';
USE restman;

