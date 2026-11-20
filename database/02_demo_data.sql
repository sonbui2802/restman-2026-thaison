USE restman;
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO tblMember6(username,password,fullName,role)
SELECT 'managerson',SHA2('12345678',256),'Quản lý','MANAGER'
WHERE NOT EXISTS (SELECT 1 FROM tblMember6 WHERE username='managerson');
SET @manager6 = (SELECT MIN(id) FROM tblMember6 WHERE username='managerson');
INSERT INTO tblStaff6(id,position)
SELECT @manager6,'Quản lý' WHERE NOT EXISTS (SELECT 1 FROM tblStaff6 WHERE id=@manager6);
INSERT INTO tblManager6(id)
SELECT @manager6 WHERE NOT EXISTS (SELECT 1 FROM tblManager6 WHERE id=@manager6);

INSERT INTO tblMember6(username,password,fullName,email,phone,role)
SELECT 'customer6',SHA2('12345678',256),'Khách hàng','khach@example.com','0901234567','CUSTOMER'
WHERE NOT EXISTS (SELECT 1 FROM tblMember6 WHERE username='customer6');
SET @customer6 = (SELECT MIN(id) FROM tblMember6 WHERE username='customer6');
INSERT INTO tblCustomer6(id,rewardPoints,cardRank)
SELECT @customer6,0,'STANDARD' WHERE NOT EXISTS (SELECT 1 FROM tblCustomer6 WHERE id=@customer6);

INSERT INTO tblCategory6(name,description)
SELECT 'Cá & hải sản','Các món cá và hải sản'
WHERE NOT EXISTS (SELECT 1 FROM tblCategory6 WHERE name='Cá & hải sản');
INSERT INTO tblCategory6(name,description)
SELECT 'Rau & món phụ','Các món ăn kèm'
WHERE NOT EXISTS (SELECT 1 FROM tblCategory6 WHERE name='Rau & món phụ');

INSERT INTO tblDiningTable6(name,capacity,location,status,description)
SELECT 'Bàn 01',4,'Tầng 1','AVAILABLE','Gần cửa sổ'
WHERE NOT EXISTS (SELECT 1 FROM tblDiningTable6 WHERE name='Bàn 01');
INSERT INTO tblDiningTable6(name,capacity,location,status,description)
SELECT 'Bàn 02',4,'Tầng 1','AVAILABLE','Trong nhà'
WHERE NOT EXISTS (SELECT 1 FROM tblDiningTable6 WHERE name='Bàn 02');

-- 18 extra physical tables. Availability is derived from reservation overlaps,
-- not stored per day: these new tables are free on 20-27/11/2026 and later
-- until a reservation is made. Re-running this seed does not duplicate tables.
INSERT INTO tblDiningTable6(name,capacity,location,status,description)
SELECT seed.name,seed.capacity,seed.location,'AVAILABLE',seed.description
FROM (
    SELECT 'Bàn 03' AS name,2 AS capacity,'Tầng 1' AS location,'Gần cửa sổ' AS description
    UNION ALL SELECT 'Bàn 04',2,'Tầng 1','Trong nhà'
    UNION ALL SELECT 'Bàn 05',4,'Tầng 1','Gần cửa sổ'
    UNION ALL SELECT 'Bàn 06',4,'Tầng 1','Trong nhà'
    UNION ALL SELECT 'Bàn 07',6,'Tầng 1','Khu gia đình'
    UNION ALL SELECT 'Bàn 08',6,'Tầng 1','Khu gia đình'
    UNION ALL SELECT 'Bàn 09',8,'Tầng 1','Bàn nhóm'
    UNION ALL SELECT 'Bàn 10',10,'Tầng 1','Bàn nhóm lớn'
    UNION ALL SELECT 'Bàn 11',2,'Tầng 2','Gần cửa sổ'
    UNION ALL SELECT 'Bàn 12',2,'Tầng 2','Trong nhà'
    UNION ALL SELECT 'Bàn 13',4,'Tầng 2','Gần cửa sổ'
    UNION ALL SELECT 'Bàn 14',4,'Tầng 2','Trong nhà'
    UNION ALL SELECT 'Bàn 15',6,'Tầng 2','Khu gia đình'
    UNION ALL SELECT 'Bàn 16',8,'Tầng 2','Bàn nhóm'
    UNION ALL SELECT 'Bàn 17',2,'Sân vườn','Ngoài trời'
    UNION ALL SELECT 'Bàn 18',4,'Sân vườn','Gần cây xanh'
    UNION ALL SELECT 'Bàn 19',6,'Sân vườn','Khu gia đình'
    UNION ALL SELECT 'Bàn 20',8,'Sân vườn','Bàn nhóm'
) AS seed
WHERE NOT EXISTS (SELECT 1 FROM tblDiningTable6 t WHERE t.name=seed.name);

SET @category6 = (SELECT MIN(id) FROM tblCategory6 WHERE name='Cá & hải sản');
INSERT INTO tblDish6(name,price,unit,image,description,tblCategory6id)
SELECT 'Cá chép om dưa',180000,'Nồi','','',@category6
WHERE NOT EXISTS (SELECT 1 FROM tblDish6 WHERE name='Cá chép om dưa');
INSERT INTO tblDish6(name,price,unit,image,description,tblCategory6id)
SELECT 'Canh chua cá lóc',150000,'Nồi','','',@category6
WHERE NOT EXISTS (SELECT 1 FROM tblDish6 WHERE name='Canh chua cá lóc');
COMMIT;

