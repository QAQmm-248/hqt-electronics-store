USE PhoneStore;
GO
SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

-- The assignment's Orders/OrderItems/Products remain the source of truth.
-- Web orders use the existing CreatedBy user and CustomerId links.
CREATE OR ALTER PROCEDURE dbo.usp_CreateOrder
    @UserId INT,
    @FullName NVARCHAR(150),
    @Phone VARCHAR(20),
    @Email NVARCHAR(150) = NULL,
    @Address NVARCHAR(300) = NULL,
    @Items NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISJSON(@Items) <> 1 THROW 51000, N'Giỏ hàng không hợp lệ.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CustomerId INT;
        SELECT @CustomerId = CustomerId
        FROM dbo.Customers WITH (UPDLOCK, HOLDLOCK)
        WHERE UserId = @UserId;
        IF @CustomerId IS NULL
        BEGIN
            INSERT dbo.Customers (FullName, Phone, Email, Address, UserId)
            VALUES (@FullName, @Phone, @Email, @Address, @UserId);
            SET @CustomerId = CONVERT(INT, SCOPE_IDENTITY());
        END;

        DECLARE @Cart TABLE (
            ProductId INT PRIMARY KEY,
            Quantity INT NOT NULL,
            UnitPrice DECIMAL(18,2) NULL,
            UnitCost DECIMAL(18,2) NULL
        );

        INSERT @Cart (ProductId, Quantity)
        SELECT TRY_CONVERT(INT, product_id), SUM(TRY_CONVERT(INT, quantity))
        FROM OPENJSON(@Items)
        WITH (product_id NVARCHAR(30) '$.product_id', quantity NVARCHAR(30) '$.quantity')
        GROUP BY TRY_CONVERT(INT, product_id);

        IF NOT EXISTS (SELECT 1 FROM @Cart)
           OR EXISTS (SELECT 1 FROM @Cart WHERE ProductId IS NULL OR Quantity NOT BETWEEN 1 AND 20)
            THROW 51002, N'Giỏ hàng không hợp lệ.', 1;

        UPDATE c
        SET UnitPrice = p.SalePrice, UnitCost = p.CostPrice
        FROM @Cart c
        JOIN dbo.Products p WITH (UPDLOCK, HOLDLOCK) ON p.ProductId = c.ProductId
        WHERE p.IsActive = 1 AND p.StockQuantity >= c.Quantity;

        IF EXISTS (SELECT 1 FROM @Cart WHERE UnitPrice IS NULL)
            THROW 51003, N'Sản phẩm đã hết hàng hoặc tồn kho không đủ.', 1;

        UPDATE dbo.Customers
        SET FullName = @FullName, Phone = @Phone, Email = @Email, Address = @Address
        WHERE CustomerId = @CustomerId;

        DECLARE @Total DECIMAL(18,2) = (SELECT SUM(Quantity * UnitPrice) FROM @Cart);
        DECLARE @OrderId INT;

        INSERT dbo.Orders
            (CustomerId, CreatedBy, Status, TotalAmount, CompletedAt,
             ShippingName, ShippingPhone, ShippingEmail, ShippingAddress)
        VALUES
            (@CustomerId, @UserId, 'completed', @Total, SYSDATETIME(),
             @FullName, @Phone, @Email, @Address);
        SET @OrderId = CONVERT(INT, SCOPE_IDENTITY());

        INSERT dbo.OrderItems (OrderId, ProductId, Quantity, UnitPrice, UnitCost)
        SELECT @OrderId, ProductId, Quantity, UnitPrice, UnitCost FROM @Cart;

        UPDATE p SET StockQuantity = p.StockQuantity - c.Quantity
        FROM dbo.Products p JOIN @Cart c ON c.ProductId = p.ProductId;

        COMMIT TRANSACTION;
        SELECT @OrderId AS OrderId, @Total AS TotalAmount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
GRANT EXECUTE ON OBJECT::dbo.usp_CreateOrder TO phone_app;
GO
