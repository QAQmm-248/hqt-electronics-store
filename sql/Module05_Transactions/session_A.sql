/*
MODULE 05 - PHIEN A
Co so du lieu: PhoneStore

BLOCKING:
- Chay phan BLOCKING truoc.
- Ngay sau khi A bat dau, chay phan BLOCKING trong session_B.sql.
- A giu khoa tren ProductId=1 trong 15 giay, sau do COMMIT.
- UPDATE gan gia tri bang chinh no nen khong doi ton kho.

DEADLOCK:
- Sau khi blocking ket thuc, bo comment phan DEADLOCK.
- Chay A, sau do trong vong 5 giay chay DEADLOCK o session_B.sql.
- A khoa Product 1 truoc, roi yeu cau Product 2.
*/

USE PhoneStore;
GO

/* ========== BLOCKING - CHAY KHOI NAY TRUOC ========== */
BEGIN TRANSACTION;

UPDATE dbo.Products
SET StockQuantity = StockQuantity
WHERE ProductId = 1;

WAITFOR DELAY '00:00:15';

COMMIT TRANSACTION;
GO

/* ========== DEADLOCK - CHI BO COMMENT KHI KIEM THU ========== */
-- USE PhoneStore;
-- GO
-- BEGIN TRANSACTION;
-- UPDATE dbo.Products
-- SET StockQuantity = StockQuantity
-- WHERE ProductId = 1;
--
-- WAITFOR DELAY '00:00:05';
--
-- UPDATE dbo.Products
-- SET StockQuantity = StockQuantity
-- WHERE ProductId = 2;
--
-- COMMIT TRANSACTION;
-- GO
