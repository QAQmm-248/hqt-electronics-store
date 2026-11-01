/*
MODULE 05 - PHIEN B
Co so du lieu: PhoneStore

BLOCKING:
- Chay phan BLOCKING trong session_A.sql truoc.
- Ngay sau do chay khoi BLOCKING ben duoi.
- B se bi block khi cap nhat ProductId=1, sau khi A COMMIT thi B tiep tuc.
- UPDATE gan gia tri bang chinh no nen khong doi ton kho.

DEADLOCK:
- Sau khi blocking ket thuc, bo comment phan DEADLOCK.
- Chay A truoc, trong vong 5 giay chay B.
- B khoa Product 2 truoc, roi yeu cau Product 1.
- SQL Server du kien huy mot giao dich voi loi 1205.
*/

USE PhoneStore;
GO

/* ========== BLOCKING - CHAY SAU SESSION A ========== */
BEGIN TRANSACTION;

UPDATE dbo.Products
SET StockQuantity = StockQuantity
WHERE ProductId = 1;

COMMIT TRANSACTION;
GO

/* ========== DEADLOCK - CHI BO COMMENT KHI KIEM THU ========== */
-- USE PhoneStore;
-- GO
-- BEGIN TRANSACTION;
-- UPDATE dbo.Products
-- SET StockQuantity = StockQuantity
-- WHERE ProductId = 2;
--
-- WAITFOR DELAY '00:00:05';
--
-- UPDATE dbo.Products
-- SET StockQuantity = StockQuantity
-- WHERE ProductId = 1;
--
-- COMMIT TRANSACTION;
-- GO
