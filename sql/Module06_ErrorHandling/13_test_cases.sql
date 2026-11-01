/* MODULE 06 - KIEM THU DU LIEU
   Co so du lieu: PhoneStore | SQL Server
   Script co chu dich tao loi rang buoc trong khoi TRY/CATCH.
   Chay sau 12_error_handling.sql; cac ca kiem thu duoc thiet ke de khong luu du lieu thu.
*/
USE PhoneStore;
GO
SET NOCOUNT ON;

DECLARE @Results TABLE
(
    TestNo INT,
    TestName NVARCHAR(100),
    Expected NVARCHAR(300),
    Actual NVARCHAR(500),
    Status VARCHAR(10)
);

/* TC01 - KHOA CHINH: UserId trung voi ban ghi hien co */
BEGIN TRY
    SET IDENTITY_INSERT dbo.Users ON;
    INSERT INTO dbo.Users (UserId, Username, PasswordHash, RoleName, IsActive)
    VALUES (1, 'test_duplicate_pk', 'hash', 'customer', 1);
    SET IDENTITY_INSERT dbo.Users OFF;
    INSERT INTO @Results VALUES (1, 'PRIMARY KEY', N'Tu choi UserId bi trung', N'Khong phat sinh loi', 'FAIL');
END TRY
BEGIN CATCH
    IF OBJECTPROPERTY(OBJECT_ID('dbo.Users'), 'TableHasIdentity') = 1
    BEGIN TRY
        SET IDENTITY_INSERT dbo.Users OFF;
    END TRY
    BEGIN CATCH
    END CATCH;
    INSERT INTO @Results VALUES (1, 'PRIMARY KEY', N'Tu choi UserId bi trung', ERROR_MESSAGE(), 'PASS');
END CATCH;

/* TC02 - KHOA NGOAI: ReceiptId khong ton tai */
BEGIN TRY
    INSERT INTO dbo.StockReceiptItems (ReceiptId, ProductId, Quantity, UnitCost)
    VALUES (-999999, 1, 1, 0);
    INSERT INTO @Results VALUES (2, 'FOREIGN KEY', N'Tu choi ReceiptId khong ton tai', N'Khong phat sinh loi', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Results VALUES (2, 'FOREIGN KEY', N'Tu choi ReceiptId khong ton tai', ERROR_MESSAGE(), 'PASS');
END CATCH;

/* TC03 - DUY NHAT: ten dang nhap bi trung */
BEGIN TRY
    INSERT INTO dbo.Users (Username, PasswordHash, RoleName, IsActive)
    VALUES ('admin', 'hash', 'customer', 1);
    INSERT INTO @Results VALUES (3, 'UNIQUE', N'Tu choi Username bi trung', N'Khong phat sinh loi', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Results VALUES (3, 'UNIQUE', N'Tu choi Username bi trung', ERROR_MESSAGE(), 'PASS');
END CATCH;

/* TC04 - KHONG RONG: PasswordHash khong duoc NULL */
BEGIN TRY
    INSERT INTO dbo.Users (Username, PasswordHash, RoleName, IsActive)
    VALUES ('test_null_password', NULL, 'customer', 1);
    INSERT INTO @Results VALUES (4, 'NOT NULL', N'Tu choi PasswordHash = NULL', N'Khong phat sinh loi', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Results VALUES (4, 'NOT NULL', N'Tu choi PasswordHash = NULL', ERROR_MESSAGE(), 'PASS');
END CATCH;

/* TC05 - KIEM TRA: so dien thoai nha cung cap sai dinh dang */
BEGIN TRY
    INSERT INTO dbo.Suppliers (SupplierName, Phone, IsActive)
    VALUES (N'Test supplier invalid phone', '123', 1);
    INSERT INTO @Results VALUES (5, 'CHECK', N'Tu choi so dien thoai sai dinh dang', N'Khong phat sinh loi', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Results VALUES (5, 'CHECK', N'Tu choi so dien thoai sai dinh dang', ERROR_MESSAGE(), 'PASS');
END CATCH;

/* TC06 - MAC DINH: bo qua IsActive thi nhan gia tri 1; hoan tac ban ghi thu */
DECLARE @BrandName NVARCHAR(100) = N'Test default ' + CONVERT(NVARCHAR(36), NEWID());
DECLARE @DefaultValue BIT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.Brands (BrandName) VALUES (@BrandName);
    SELECT @DefaultValue = IsActive FROM dbo.Brands WHERE BrandName = @BrandName;
    ROLLBACK TRANSACTION;

    INSERT INTO @Results
    VALUES (6, 'DEFAULT', N'Tu dong gan IsActive = 1',
            N'Gia tri IsActive thuc te = ' + COALESCE(CONVERT(NVARCHAR(10), @DefaultValue), N'NULL'),
            CASE WHEN @DefaultValue = 1 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    INSERT INTO @Results VALUES (6, 'DEFAULT', N'Tu dong gan IsActive = 1', ERROR_MESSAGE(), 'FAIL');
END CATCH;

/* TC07 - QUY TAC NGHIEP VU: so luong mua vuot ton kho */
BEGIN TRY
    EXEC dbo.usp_CreateOrder_Safe
        @CustomerId = 1,
        @CreatedByEmployeeId = 1,
        @ProductId = 1,
        @Quantity = 999999;
    INSERT INTO @Results VALUES (7, 'BUSINESS RULE', N'Tu choi khi ton kho khong du', N'Thu tuc khong tu choi yeu cau', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Results VALUES (7, 'BUSINESS RULE', N'Tu choi khi ton kho khong du', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 50005 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

/* TC08 - HOAN TAC: dong chi tiet sai phai hoan tac don hang cha */
DECLARE @OrdersBefore INT, @OrdersAfter INT;
SELECT @OrdersBefore = COUNT(*) FROM dbo.Orders;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.Orders (CustomerId, CreatedByEmployeeId)
    VALUES (1, 1);

    INSERT INTO dbo.OrderItems (OrderId, ProductId, Quantity, UnitPrice, UnitCost)
    VALUES (CONVERT(INT, SCOPE_IDENTITY()), -999999, 1, 0, 0);

    COMMIT TRANSACTION;
    SELECT @OrdersAfter = COUNT(*) FROM dbo.Orders;
    INSERT INTO @Results VALUES (8, 'ROLLBACK', N'Rollback don hang khi chi tiet khong hop le', N'Giao dich khong rollback', 'FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT @OrdersAfter = COUNT(*) FROM dbo.Orders;
    INSERT INTO @Results VALUES (8, 'ROLLBACK', N'Rollback don hang khi chi tiet khong hop le',
        N'Orders truoc = ' + CONVERT(NVARCHAR(20), @OrdersBefore) + N'; sau = ' + CONVERT(NVARCHAR(20), @OrdersAfter),
        CASE WHEN @OrdersBefore = @OrdersAfter THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

SELECT TestNo, TestName, Expected, Actual, Status
FROM @Results
ORDER BY TestNo;

SELECT
    COUNT(*) AS TotalTests,
    SUM(CASE WHEN Status = 'PASS' THEN 1 ELSE 0 END) AS Passed,
    SUM(CASE WHEN Status = 'FAIL' THEN 1 ELSE 0 END) AS Failed
FROM @Results;
GO
