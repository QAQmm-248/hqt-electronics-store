/* MODULE 06 - XU LY LOI
   Co so du lieu: PhoneStore | SQL Server
   Chon co so du lieu PhoneStore trong SSMS truoc khi chay script.
*/
USE PhoneStore;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateOrder_Safe
    @CustomerId INT = NULL,
    @CreatedByEmployeeId INT,
    @ProductId INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StockQuantity INT;
    DECLARE @SalePrice DECIMAL(18,2);
    DECLARE @CostPrice DECIMAL(18,2);
    DECLARE @OrderId INT;

    BEGIN TRY
        -- Kiem tra du lieu dau vao va ban ghi lien quan truoc khi mo giao dich.
        IF @Quantity IS NULL OR @Quantity <= 0
            THROW 50001, N'So luong phai lon hon 0.', 1;

        IF @ProductId IS NULL
            THROW 50002, N'ProductId khong duoc de trong.', 1;

        IF @CreatedByEmployeeId IS NULL
            THROW 50003, N'EmployeeId khong duoc de trong.', 1;

        IF @CustomerId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerId = @CustomerId)
            THROW 50004, N'Khach hang khong ton tai.', 1;

        IF NOT EXISTS (
            SELECT 1 FROM dbo.Employees
            WHERE EmployeeId = @CreatedByEmployeeId AND IsActive = 1
        )
            THROW 50006, N'Nhan vien khong ton tai hoac da ngung hoat dong.', 1;

        BEGIN TRANSACTION;

        -- Khoa dong san pham de tranh hai don dong thoi ban vuot ton kho.
        SELECT
            @StockQuantity = StockQuantity,
            @SalePrice = SalePrice,
            @CostPrice = CostPrice
        FROM dbo.Products WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductId = @ProductId AND IsActive = 1;

        IF @StockQuantity IS NULL
            THROW 50007, N'San pham khong ton tai hoac da ngung kinh doanh.', 1;

        IF @StockQuantity < @Quantity
            THROW 50005, N'So luong ton kho khong du.', 1;

        INSERT INTO dbo.Orders (CustomerId, CreatedByEmployeeId)
        VALUES (@CustomerId, @CreatedByEmployeeId);

        SET @OrderId = CONVERT(INT, SCOPE_IDENTITY());

        -- LineTotal la cot tinh toan nen khong duoc chen gia tri truc tiep.
        INSERT INTO dbo.OrderItems (OrderId, ProductId, Quantity, UnitPrice, UnitCost)
        VALUES (@OrderId, @ProductId, @Quantity, @SalePrice, @CostPrice);

        UPDATE dbo.Products
        SET StockQuantity = StockQuantity - @Quantity
        WHERE ProductId = @ProductId;

        COMMIT TRANSACTION;

        SELECT
            N'Tao don hang thanh cong.' AS Message,
            @OrderId AS OrderId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Kiem thu thu cong tuy chon (bo dau comment de chay):
-- EXEC dbo.usp_CreateOrder_Safe
--     @CustomerId = 1,
--     @CreatedByEmployeeId = 1,
--     @ProductId = 1,
--     @Quantity = 1;
