/*
MODULE 05 - GIAO DICH
Co so du lieu: PhoneStore
Cac nghiep vu:
  1. Ban hang: tao Orders, OrderItems, tru ton kho, hoan tat don.
  2. Nhap kho: tao StockReceipts, StockReceiptItems, cong ton kho, cap nhat CostPrice.

Luu y:
- Khong DROP DATABASE, khong xoa du lieu mau.
- Chay file nay de tao/cap nhat 2 stored procedures.
- Cac lenh kiem thu nam trong comment, chi chay khi muon kiem thu.
- OrderItems.LineTotal la computed column nen KHONG INSERT truc tiep.
*/

USE PhoneStore;
GO

/* =========================================================
   1. GIAO DICH BAN HANG
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_CreateOrderWithTransaction
    @CustomerId INT,
    @EmployeeId INT,
    @ProductId INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Stock INT;
    DECLARE @SalePrice DECIMAL(18,2);
    DECLARE @CostPrice DECIMAL(18,2);
    DECLARE @OrderId INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Quantity IS NULL OR @Quantity <= 0
            THROW 50001, N'So luong phai lon hon 0.', 1;

        IF NOT EXISTS (
            SELECT 1 FROM dbo.Customers
            WHERE CustomerId = @CustomerId
        )
            THROW 50002, N'Khach hang khong ton tai.', 1;

        IF NOT EXISTS (
            SELECT 1 FROM dbo.Employees
            WHERE EmployeeId = @EmployeeId AND IsActive = 1
        )
            THROW 50003, N'Nhan vien khong ton tai hoac da ngung hoat dong.', 1;

        SELECT
            @Stock = StockQuantity,
            @SalePrice = SalePrice,
            @CostPrice = CostPrice
        FROM dbo.Products WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductId = @ProductId AND IsActive = 1;

        IF @Stock IS NULL
            THROW 50004, N'San pham khong ton tai hoac da ngung kinh doanh.', 1;

        IF @Stock < @Quantity
            THROW 50005, N'So luong ton kho khong du.', 1;

        INSERT INTO dbo.Orders (CustomerId, CreatedByEmployeeId)
        VALUES (@CustomerId, @EmployeeId);

        SET @OrderId = CONVERT(INT, SCOPE_IDENTITY());

        INSERT INTO dbo.OrderItems
            (OrderId, ProductId, Quantity, UnitPrice, UnitCost)
        VALUES
            (@OrderId, @ProductId, @Quantity, @SalePrice, @CostPrice);

        UPDATE dbo.Products
        SET StockQuantity = StockQuantity - @Quantity
        WHERE ProductId = @ProductId;

        UPDATE dbo.Orders
        SET Status = 'completed',
            CompletedAt = SYSDATETIME()
        WHERE OrderId = @OrderId;

        COMMIT TRANSACTION;

        SELECT
            @OrderId AS OrderId,
            @ProductId AS ProductId,
            @Quantity AS QuantitySold,
            @Stock - @Quantity AS StockAfterSale,
            N'Tao don hang thanh cong' AS ResultMessage;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   2. GIAO DICH NHAP KHO
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_ProcessStockReceipt
    @SupplierId INT,
    @ReceivedByEmployeeId INT,
    @ProductId INT,
    @Quantity INT,
    @UnitCost DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity IS NULL OR @Quantity <= 0
        THROW 52001, N'So luong nhap phai lon hon 0.', 1;

    IF @UnitCost IS NULL OR @UnitCost < 0
        THROW 52002, N'Gia von khong duoc am.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentStock INT;

        SELECT @CurrentStock = StockQuantity
        FROM dbo.Products WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductId = @ProductId;

        IF @CurrentStock IS NULL
            THROW 52003, N'Khong tim thay san pham can nhap kho.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Suppliers WHERE SupplierId = @SupplierId)
            THROW 52004, N'Khong tim thay nha cung cap.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @ReceivedByEmployeeId)
            THROW 52005, N'Khong tim thay nhan vien nhap kho.', 1;

        INSERT INTO dbo.StockReceipts
            (SupplierId, ReceivedByEmployeeId, ReceivedAt)
        VALUES
            (@SupplierId, @ReceivedByEmployeeId, SYSDATETIME());

        DECLARE @ReceiptId INT = CONVERT(INT, SCOPE_IDENTITY());

        INSERT INTO dbo.StockReceiptItems
            (ReceiptId, ProductId, Quantity, UnitCost)
        VALUES
            (@ReceiptId, @ProductId, @Quantity, @UnitCost);

        UPDATE dbo.Products
        SET StockQuantity = StockQuantity + @Quantity,
            CostPrice = @UnitCost
        WHERE ProductId = @ProductId;

        COMMIT TRANSACTION;

        SELECT
            @ReceiptId AS ReceiptId,
            @ProductId AS ProductId,
            @Quantity AS QuantityReceived,
            @CurrentStock + @Quantity AS StockAfterReceipt,
            N'Nhap kho thanh cong' AS ResultMessage;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   3. KIEM THU BAN HANG - THANH CONG NHUNG ROLLBACK DE HOAN NGUYEN
   Du lieu mau da xac nhan:
   CustomerId=1, EmployeeId=1, ProductId=1, ton kho ban dau=100.
   Chay rieng khoi nay neu can lap lai kiem thu.
   ========================================================= */
-- BEGIN TRANSACTION;
-- EXEC dbo.usp_CreateOrderWithTransaction
--     @CustomerId = 1, @EmployeeId = 1, @ProductId = 1, @Quantity = 2;
-- SELECT ProductId, StockQuantity FROM dbo.Products WHERE ProductId = 1;
-- SELECT TOP (1) * FROM dbo.Orders ORDER BY OrderId DESC;
-- SELECT TOP (1) * FROM dbo.OrderItems ORDER BY OrderId DESC;
-- ROLLBACK TRANSACTION;
-- GO

/* =========================================================
   4. KIEM THU BAN HANG - THAT BAI DO KHONG DU TON KHO
   Chay rieng khoi nay. Loi du kien 50005.
   ========================================================= */
-- BEGIN TRY
--     EXEC dbo.usp_CreateOrderWithTransaction
--         @CustomerId = 1, @EmployeeId = 1, @ProductId = 1, @Quantity = 200;
-- END TRY
-- BEGIN CATCH
--     SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
-- END CATCH;
-- GO

/* =========================================================
   5. KIEM THU NHAP KHO - THANH CONG NHUNG ROLLBACK DE HOAN NGUYEN
   Du lieu mau da xac nhan: SupplierId=1, EmployeeId=1, ProductId=1.
   ========================================================= */
-- BEGIN TRANSACTION;
-- EXEC dbo.usp_ProcessStockReceipt
--     @SupplierId = 1, @ReceivedByEmployeeId = 1,
--     @ProductId = 1, @Quantity = 5, @UnitCost = 23800000;
-- SELECT ProductId, StockQuantity, CostPrice FROM dbo.Products WHERE ProductId = 1;
-- SELECT TOP (1) * FROM dbo.StockReceipts ORDER BY ReceiptId DESC;
-- SELECT TOP (1) * FROM dbo.StockReceiptItems ORDER BY ReceiptId DESC;
-- ROLLBACK TRANSACTION;
-- GO

/* =========================================================
   6. KIEM THU NHAP KHO - THAT BAI DO PRODUCT KHONG TON TAI
   Loi du kien 52003. Procedure tu ROLLBACK trong CATCH.
   ========================================================= */
-- BEGIN TRY
--     EXEC dbo.usp_ProcessStockReceipt
--         @SupplierId = 1, @ReceivedByEmployeeId = 1,
--         @ProductId = -999999, @Quantity = 5, @UnitCost = 23800000;
-- END TRY
-- BEGIN CATCH
--     SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
-- END CATCH;
-- GO
