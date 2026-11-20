-- Explicit SQL/design discrepancy: the supplied schema lacks TableReservation6.note.
-- Apply ONCE, after restman6_schema.sql. All original tables/columns/PK/FK stay unchanged.
USE restman;
ALTER TABLE tblTableReservation6 ADD COLUMN note VARCHAR(255) NULL;

