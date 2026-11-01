/*
MODULE 05 - KIEM THU TRUY CAP DONG THOI
Co so du lieu: PhoneStore

Can 2 cua so query / 2 connection rieng biet trong SSMS.
Tat ca cac lenh UPDATE trong bai nay chi cap nhat gia tri ton kho ve chinh no
(StockQuantity = StockQuantity), khong lam thay doi so luong hang.

PHAN A - BLOCKING:
  1. Chay session_A.sql - BLOCKING truoc.
  2. Ngay sau khi A bat dau chay, chay session_B.sql - BLOCKING.
  3. B se doi cho den khi A COMMIT.
  4. Moi session chi chay mot lan.

PHAN B - DEADLOCK:
  1. Chay session_A.sql - DEADLOCK.
  2. Trong khoang 5 giay, chay session_B.sql - DEADLOCK.
  3. Mot session du kien nhan loi 1205 (deadlock victim).
  4. Session con lai tiep tuc va COMMIT.

Sau khi kiem thu, chay phan kiem tra cuoi file.
*/

USE PhoneStore;
GO

/* Kiem tra hai san pham dung de test */
SELECT ProductId, ProductName, StockQuantity
FROM dbo.Products
WHERE ProductId IN (1, 2);
GO

/*
Kiem tra blocking/deadlock dang hoat dong:
Mo query thu ba va chay trong luc hai session dang thuc thi.
*/
-- SELECT
--     r.session_id,
--     r.blocking_session_id,
--     r.status,
--     r.wait_type,
--     r.wait_time,
--     DB_NAME(r.database_id) AS DatabaseName
-- FROM sys.dm_exec_requests AS r
-- WHERE r.database_id = DB_ID('PhoneStore')
--   AND (r.blocking_session_id <> 0 OR r.wait_type LIKE 'LCK%');
-- GO

/*
Kiem tra ton kho sau cac bai test.
Vi cac UPDATE trong test la update-no-op, ton kho khong doi.
*/
SELECT ProductId, ProductName, StockQuantity
FROM dbo.Products
WHERE ProductId IN (1, 2);
GO
