/* Module 04 - nghiep vu, ham va trigger cua 3K Store.
   Chay sau 01_database_init.sql va file nang cap schema web.
   File chi tao/cap nhat doi tuong SQL, khong chay cac vi du sua du lieu. */
USE PhoneStore;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* Giam gia thanh vien: 2% tu 20 trieu, 5% tu 50 trieu, toi da 3 trieu. */
CREATE OR ALTER FUNCTION dbo.VOUCHER
(
    @CustomerId INT,
    @LineTotal DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Discount DECIMAL(18,2) = 0;
    IF @CustomerId IS NULL OR @LineTotal IS NULL OR @LineTotal <= 0
        RETURN 0;
    IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerId = @CustomerId AND UserId IS NOT NULL)
        RETURN 0;
    IF @LineTotal >= 50000000 SET @Discount = @LineTotal * 0.05;
    ELSE IF @LineTotal >= 20000000 SET @Discount = @LineTotal * 0.02;
    IF @Discount > 3000000 SET @Discount = 3000000;
    RETURN @Discount;
END;
GO

/* Loc san pham dang ban theo hang va khoang gia; NULL bo qua dieu kien. */
CREATE OR ALTER FUNCTION dbo.Timkiemsanpham
(
    @BrandId INT,
    @MinPrice DECIMAL(18,2),
    @MaxPrice DECIMAL(18,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT p.ProductId,p.SKU,p.ProductName,b.BrandName,c.CategoryName,
           p.SalePrice,p.StockQuantity,p.WarrantyMonths
    FROM dbo.Products p
    JOIN dbo.Brands b ON b.BrandId=p.BrandId
    JOIN dbo.Categories c ON c.CategoryId=p.CategoryId
    WHERE p.IsActive=1
      AND (@BrandId IS NULL OR p.BrandId=@BrandId)
      AND (@MinPrice IS NULL OR p.SalePrice>=@MinPrice)
      AND (@MaxPrice IS NULL OR p.SalePrice<=@MaxPrice)
);
GO

/* Hoan tat don nhap: kiem tra ton kho, tru kho va ghi tong tien mot lan. */
CREATE OR ALTER PROCEDURE dbo.KTdonhang @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Status VARCHAR(12);
        SELECT @Status=Status FROM dbo.Orders WITH (UPDLOCK,HOLDLOCK) WHERE OrderId=@OrderId;
        IF @Status IS NULL THROW 51040,N'Khong tim thay don hang.',1;
        IF @Status<>'draft' THROW 51041,N'Chi duoc hoan tat don dang nhap.',1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrderItems WHERE OrderId=@OrderId)
            THROW 51042,N'Don hang chua co san pham.',1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.OrderItems oi
            JOIN dbo.Products p WITH (UPDLOCK,HOLDLOCK) ON p.ProductId=oi.ProductId
            WHERE oi.OrderId=@OrderId AND (p.IsActive=0 OR p.StockQuantity<oi.Quantity)
        ) THROW 51043,N'Ton kho khong du hoac san pham ngung ban.',1;
        UPDATE p SET StockQuantity=p.StockQuantity-oi.Quantity
        FROM dbo.Products p JOIN dbo.OrderItems oi ON oi.ProductId=p.ProductId
        WHERE oi.OrderId=@OrderId;
        UPDATE dbo.Orders
        SET Status='completed',CompletedAt=SYSDATETIME(),
            TotalAmount=(SELECT SUM(LineTotal) FROM dbo.OrderItems WHERE OrderId=@OrderId)
        WHERE OrderId=@OrderId;
        COMMIT TRANSACTION;
        SELECT @OrderId AS OrderId,N'Hoan tat don hang' AS ResultMessage;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Nhap kho: tao phieu, dong phieu va cong ton trong cung giao dich. */
CREATE OR ALTER PROCEDURE dbo.Nhaphang
    @SupplierId INT,@ReceivedByEmployeeId INT,@ProductId INT,
    @Quantity INT,@UnitCost DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @Quantity IS NULL OR @Quantity<=0 OR @UnitCost IS NULL OR @UnitCost<0
        THROW 51044,N'So luong hoac gia nhap khong hop le.',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @NewReceiptId INT;
        INSERT dbo.StockReceipts(SupplierId,ReceivedByEmployeeId,ReceivedAt)
        VALUES(@SupplierId,@ReceivedByEmployeeId,SYSDATETIME());
        SET @NewReceiptId=CONVERT(INT,SCOPE_IDENTITY());
        INSERT dbo.StockReceiptItems(ReceiptId,ProductId,Quantity,UnitCost)
        VALUES(@NewReceiptId,@ProductId,@Quantity,@UnitCost);
        UPDATE dbo.Products WITH (UPDLOCK)
        SET StockQuantity=StockQuantity+@Quantity,CostPrice=@UnitCost
        WHERE ProductId=@ProductId;
        IF @@ROWCOUNT<>1 THROW 51045,N'Khong tim thay san pham.',1;
        COMMIT TRANSACTION;
        SELECT @NewReceiptId AS ReceiptId,N'Nhap kho thanh cong' AS ResultMessage;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Huy don mot lan; don hoan tat duoc hoan tra ton kho. */
CREATE OR ALTER PROCEDURE dbo.Huydonhang @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Status VARCHAR(12);
        SELECT @Status=Status FROM dbo.Orders WITH (UPDLOCK,HOLDLOCK) WHERE OrderId=@OrderId;
        IF @Status IS NULL THROW 51046,N'Khong tim thay don hang.',1;
        IF @Status='cancelled' THROW 51047,N'Don hang da huy.',1;
        IF @Status='completed'
        BEGIN
            UPDATE p SET StockQuantity=p.StockQuantity+oi.Quantity
            FROM dbo.Products p JOIN dbo.OrderItems oi ON oi.ProductId=p.ProductId
            WHERE oi.OrderId=@OrderId;
        END;
        UPDATE dbo.Orders SET Status='cancelled',CompletedAt=NULL WHERE OrderId=@OrderId;
        COMMIT TRANSACTION;
        SELECT @OrderId AS OrderId,N'Da huy don hang' AS ResultMessage;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Chan gia ban thap hon gia von khi them hoac sua san pham. */
CREATE OR ALTER TRIGGER dbo.Kiemsoat ON dbo.Products
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE SalePrice<CostPrice)
        THROW 51048,N'Gia ban khong duoc thap hon gia von.',1;
END;
GO

/* Vi du chi doc: SELECT dbo.VOUCHER(1,25000000);
   SELECT * FROM dbo.Timkiemsanpham(NULL,5000000,10000000);
   Cac thu tuc KTdonhang, Nhaphang va Huydonhang co thay doi du lieu;
   chi EXEC tren database thu nghiem voi ma don/san pham da kiem tra. */
