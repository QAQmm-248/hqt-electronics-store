/* Mục đích: nâng cấp schema PhoneStore theo hướng tương thích ứng dụng; chạy sau schema nền. */
SET NOCOUNT ON;
USE PhoneStore;
GO
/* Nang cap khong pha huy: khong xoa PhoneStore, nguoi dung, don hang hoac san pham. */
IF COL_LENGTH('dbo.Products','ProductName') IS NOT NULL ALTER TABLE dbo.Products ALTER COLUMN ProductName NVARCHAR(400) NOT NULL;
/* Bo sung cac cot ung dung can nhung script nen Module 1-2 chua co. */
IF COL_LENGTH('dbo.Products','RAMGB') IS NULL ALTER TABLE dbo.Products ADD RAMGB INT NULL;
IF COL_LENGTH('dbo.Products','StorageGB') IS NULL ALTER TABLE dbo.Products ADD StorageGB INT NULL;
IF COL_LENGTH('dbo.Products','ImagePath') IS NULL ALTER TABLE dbo.Products ADD ImagePath NVARCHAR(500) NULL;
IF COL_LENGTH('dbo.Products','SourceURL') IS NULL ALTER TABLE dbo.Products ADD SourceURL NVARCHAR(500) NULL;
IF COL_LENGTH('dbo.Products','PriceCheckedAt') IS NULL ALTER TABLE dbo.Products ADD PriceCheckedAt DATETIME2(0) NULL;
IF COL_LENGTH('dbo.Products','IsDemoData') IS NULL ALTER TABLE dbo.Products ADD IsDemoData BIT NOT NULL CONSTRAINT DF_Products_IsDemoData DEFAULT(1) WITH VALUES;
IF COL_LENGTH('dbo.Products','WarrantyMonths') IS NULL ALTER TABLE dbo.Products ADD WarrantyMonths INT NULL;
IF COL_LENGTH('dbo.Products','Description') IS NULL ALTER TABLE dbo.Products ADD Description NVARCHAR(1000) NULL;
IF COL_LENGTH('dbo.Products','DataSource') IS NULL ALTER TABLE dbo.Products ADD DataSource NVARCHAR(80) NULL;
IF COL_LENGTH('dbo.Products','ImportedAt') IS NULL ALTER TABLE dbo.Products ADD ImportedAt DATETIME2(0) NULL;
IF COL_LENGTH('dbo.OrderItems','UnitCost') IS NULL ALTER TABLE dbo.OrderItems ADD UnitCost DECIMAL(18,2) NOT NULL CONSTRAINT DF_OrderItems_UnitCost DEFAULT(0) WITH VALUES;
IF COL_LENGTH('dbo.Orders','CompletedAt') IS NULL ALTER TABLE dbo.Orders ADD CompletedAt DATETIME2(0) NULL;
/* Don cua nhan vien giu CreatedByEmployeeId; don web luu tai khoan o CreatedBy. */
IF COL_LENGTH('dbo.Orders','CreatedByEmployeeId') IS NULL ALTER TABLE dbo.Orders ADD CreatedByEmployeeId INT NULL;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.Orders') AND name=N'CreatedByEmployeeId' AND is_nullable=0)
BEGIN
 IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Orders_Employees' AND parent_object_id=OBJECT_ID(N'dbo.Orders'))
  ALTER TABLE dbo.Orders DROP CONSTRAINT FK_Orders_Employees;
 ALTER TABLE dbo.Orders ALTER COLUMN CreatedByEmployeeId INT NULL;
END;
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Orders_Employees' AND parent_object_id=OBJECT_ID(N'dbo.Orders'))
 ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_Employees FOREIGN KEY(CreatedByEmployeeId) REFERENCES dbo.Employees(EmployeeId);
IF COL_LENGTH('dbo.Orders','CreatedBy') IS NULL ALTER TABLE dbo.Orders ADD CreatedBy INT NULL;
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Orders_CreatedBy' AND parent_object_id=OBJECT_ID(N'dbo.Orders'))
 ALTER TABLE dbo.Orders ADD CONSTRAINT FK_Orders_CreatedBy FOREIGN KEY(CreatedBy) REFERENCES dbo.Users(UserId);
IF COL_LENGTH('dbo.Orders','TotalAmount') IS NULL ALTER TABLE dbo.Orders ADD TotalAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_Orders_TotalAmount DEFAULT(0) WITH VALUES;
IF COL_LENGTH('dbo.Orders','ShippingName') IS NULL ALTER TABLE dbo.Orders ADD ShippingName NVARCHAR(150) NULL;
IF COL_LENGTH('dbo.Orders','ShippingPhone') IS NULL ALTER TABLE dbo.Orders ADD ShippingPhone VARCHAR(20) NULL;
IF COL_LENGTH('dbo.Orders','ShippingEmail') IS NULL ALTER TABLE dbo.Orders ADD ShippingEmail NVARCHAR(150) NULL;
IF COL_LENGTH('dbo.Orders','ShippingAddress') IS NULL ALTER TABLE dbo.Orders ADD ShippingAddress NVARCHAR(300) NULL;
IF COL_LENGTH('dbo.Orders','PaymentMethod') IS NULL ALTER TABLE dbo.Orders ADD PaymentMethod NVARCHAR(40) NOT NULL CONSTRAINT DF_Orders_PaymentMethod DEFAULT(N'Thanh toán khi nhận hàng') WITH VALUES;
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Employees' AND schema_id=SCHEMA_ID('dbo'))
 CREATE TABLE dbo.Employees(EmployeeId INT IDENTITY PRIMARY KEY,UserId INT NOT NULL UNIQUE,FullName NVARCHAR(150) NOT NULL,Phone VARCHAR(20) NULL,Position NVARCHAR(80) NOT NULL DEFAULT(N'Nhân viên'),IsActive BIT NOT NULL DEFAULT(1),CONSTRAINT FK_Employees_Users FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId));
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Suppliers' AND schema_id=SCHEMA_ID('dbo'))
 CREATE TABLE dbo.Suppliers(SupplierId INT IDENTITY PRIMARY KEY,SupplierName NVARCHAR(150) NOT NULL UNIQUE,Phone VARCHAR(20) NULL,Address NVARCHAR(250) NULL,IsActive BIT NOT NULL DEFAULT(1));
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='StockReceipts' AND schema_id=SCHEMA_ID('dbo'))
 CREATE TABLE dbo.StockReceipts(ReceiptId INT IDENTITY PRIMARY KEY,SupplierId INT NOT NULL,ReceivedByEmployeeId INT NULL,ReceivedAt DATETIME2(0) NOT NULL DEFAULT(SYSDATETIME()),Note NVARCHAR(500) NULL,CONSTRAINT FK_StockReceipts_Suppliers FOREIGN KEY(SupplierId) REFERENCES dbo.Suppliers(SupplierId),CONSTRAINT FK_StockReceipts_Employees FOREIGN KEY(ReceivedByEmployeeId) REFERENCES dbo.Employees(EmployeeId));
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='StockReceiptItems' AND schema_id=SCHEMA_ID('dbo'))
 CREATE TABLE dbo.StockReceiptItems(ReceiptId INT NOT NULL,ProductId INT NOT NULL,Quantity INT NOT NULL,UnitCost DECIMAL(18,2) NOT NULL,CONSTRAINT PK_StockReceiptItems PRIMARY KEY(ReceiptId,ProductId),CONSTRAINT CK_StockReceiptItems_Qty CHECK(Quantity>0),CONSTRAINT FK_StockReceiptItems_Receipt FOREIGN KEY(ReceiptId) REFERENCES dbo.StockReceipts(ReceiptId),CONSTRAINT FK_StockReceiptItems_Product FOREIGN KEY(ProductId) REFERENCES dbo.Products(ProductId));
GO
/* Cap nhat du lieu cu sau khi SQL Server da nhan cac cot vua them. */
UPDATE o SET CreatedBy=e.UserId FROM dbo.Orders o JOIN dbo.Employees e ON e.EmployeeId=o.CreatedByEmployeeId WHERE o.CreatedBy IS NULL;
UPDATE o SET TotalAmount=COALESCE((SELECT SUM(i.LineTotal) FROM dbo.OrderItems i WHERE i.OrderId=o.OrderId),0)
FROM dbo.Orders o WHERE o.TotalAmount=0 AND EXISTS(SELECT 1 FROM dbo.OrderItems i WHERE i.OrderId=o.OrderId);
GO
/* Giu staff/customer cua Module 1-2 va chap nhan user dang ky tu web. */
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_Users_Role') ALTER TABLE dbo.Users DROP CONSTRAINT CK_Users_Role;
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_Users_RoleName') ALTER TABLE dbo.Users DROP CONSTRAINT CK_Users_RoleName;
    ALTER TABLE dbo.Users WITH CHECK ADD CONSTRAINT CK_Users_Role CHECK(RoleName IN ('admin','staff','customer','user'));
GO
CREATE OR ALTER VIEW dbo.vw_ProductInventory AS
 SELECT p.ProductId,p.SKU,p.ProductName,b.BrandName,c.CategoryName,p.RAMGB,p.StorageGB,p.SalePrice,p.CostPrice,p.StockQuantity,p.ImagePath,
        CAST(NULL AS NVARCHAR(500)) AS SourceURL,p.PriceCheckedAt,p.IsDemoData,p.IsActive,p.WarrantyMonths,p.Description,p.DataSource
 FROM dbo.Products p JOIN dbo.Brands b ON b.BrandId=p.BrandId JOIN dbo.Categories c ON c.CategoryId=p.CategoryId;
GO
CREATE OR ALTER VIEW dbo.vw_OrderDetails AS
 SELECT o.OrderId,o.OrderDate,o.Status,o.TotalAmount,COALESCE(c.FullName,o.ShippingName,N'Khách hàng') CustomerName,
        COALESCE(c.Phone,o.ShippingPhone) Phone,COALESCE(u.Username,eu.Username,N'Không xác định') Username,p.ProductName,oi.Quantity,oi.UnitPrice,oi.LineTotal
 FROM dbo.Orders o LEFT JOIN dbo.Customers c ON c.CustomerId=o.CustomerId LEFT JOIN dbo.Users u ON u.UserId=o.CreatedBy
 LEFT JOIN dbo.Employees e ON e.EmployeeId=o.CreatedByEmployeeId LEFT JOIN dbo.Users eu ON eu.UserId=e.UserId
 JOIN dbo.OrderItems oi ON oi.OrderId=o.OrderId JOIN dbo.Products p ON p.ProductId=oi.ProductId;
GO
CREATE OR ALTER VIEW dbo.vw_MonthlyRevenue AS
 SELECT YEAR(OrderDate) SaleYear,MONTH(OrderDate) SaleMonth,COUNT(DISTINCT OrderId) OrderCount,SUM(TotalAmount) Revenue
 FROM dbo.Orders WHERE Status='completed' GROUP BY YEAR(OrderDate),MONTH(OrderDate);
GO
CREATE OR ALTER VIEW dbo.vw_AdminDashboard AS
 SELECT (SELECT COUNT(*) FROM dbo.Products WHERE IsActive=1) ActiveProductCount,
        (SELECT COALESCE(SUM(StockQuantity),0) FROM dbo.Products WHERE IsActive=1) UnitsInStock,
        (SELECT COUNT(*) FROM dbo.Orders WHERE Status<>'cancelled' AND CONVERT(date,OrderDate)=CONVERT(date,SYSDATETIME())) OrdersToday,
        (SELECT COALESCE(SUM(TotalAmount),0) FROM dbo.Orders WHERE Status='completed' AND CONVERT(date,OrderDate)=CONVERT(date,SYSDATETIME())) RevenueToday,
        (SELECT COALESCE(SUM(TotalAmount),0) FROM dbo.Orders WHERE Status='completed') RevenueAllTime,
        (SELECT COUNT(*) FROM dbo.Customers) CustomerCount,
        (SELECT COUNT(*) FROM dbo.Products WHERE IsActive=1 AND StockQuantity<=5) LowStockCount,
        (SELECT COALESCE(SUM(StockQuantity*CostPrice),0) FROM dbo.Products WHERE IsActive=1) InventoryCostValue;
GO
CREATE OR ALTER FUNCTION dbo.fn_OrderTotal(@OrderId INT) RETURNS DECIMAL(18,2) AS
BEGIN DECLARE @Total DECIMAL(18,2); SELECT @Total=COALESCE(SUM(LineTotal),0) FROM dbo.OrderItems WHERE OrderId=@OrderId; RETURN @Total; END;
GO
CREATE OR ALTER FUNCTION dbo.fn_ProductRevenue(@ProductId INT) RETURNS DECIMAL(18,2) AS
BEGIN DECLARE @Total DECIMAL(18,2); SELECT @Total=COALESCE(SUM(oi.LineTotal),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.OrderId=oi.OrderId WHERE oi.ProductId=@ProductId AND o.Status='completed'; RETURN @Total; END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_CreateOrder
 @UserId INT,@FullName NVARCHAR(150),@Phone VARCHAR(20),@Email NVARCHAR(150)=NULL,@Address NVARCHAR(300)=NULL,@Items NVARCHAR(MAX)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISJSON(@Items)<>1 THROW 51000,N'Danh sách sản phẩm không hợp lệ.',1;
 BEGIN TRY
  BEGIN TRAN;
  DECLARE @CustomerId INT;
  SELECT @CustomerId=CustomerId FROM dbo.Customers WITH(UPDLOCK,HOLDLOCK) WHERE UserId=@UserId;
  IF @CustomerId IS NULL THROW 51001,N'Tài khoản chưa có hồ sơ khách hàng.',1;
  UPDATE dbo.Customers SET FullName=@FullName,Phone=@Phone,Email=@Email,Address=@Address WHERE CustomerId=@CustomerId;
  DECLARE @Cart TABLE(ProductId INT PRIMARY KEY,Quantity INT NOT NULL,UnitPrice DECIMAL(18,2),UnitCost DECIMAL(18,2),ProductName NVARCHAR(200));
  INSERT @Cart(ProductId,Quantity)
   SELECT TRY_CONVERT(INT,product_id),SUM(TRY_CONVERT(INT,quantity)) FROM OPENJSON(@Items)
   WITH(product_id NVARCHAR(30) '$.product_id',quantity NVARCHAR(30) '$.quantity')
   GROUP BY TRY_CONVERT(INT,product_id);
  IF NOT EXISTS(SELECT 1 FROM @Cart) OR EXISTS(SELECT 1 FROM @Cart WHERE ProductId IS NULL OR Quantity<1 OR Quantity>20) THROW 51002,N'Giỏ hàng không hợp lệ.',1;
  UPDATE c SET UnitPrice=p.SalePrice,UnitCost=p.CostPrice,ProductName=p.ProductName FROM @Cart c JOIN dbo.Products p WITH(UPDLOCK,HOLDLOCK) ON p.ProductId=c.ProductId AND p.IsActive=1 WHERE p.StockQuantity>=c.Quantity;
  IF EXISTS(SELECT 1 FROM @Cart WHERE UnitPrice IS NULL) THROW 51003,N'Sản phẩm đã hết hàng hoặc tồn kho không đủ.',1;
  DECLARE @Total DECIMAL(18,2)=(SELECT SUM(Quantity*UnitPrice) FROM @Cart),@OrderId INT;
  INSERT dbo.Orders(CustomerId,CreatedBy,Status,TotalAmount,CompletedAt,ShippingName,ShippingPhone,ShippingEmail,ShippingAddress)
   VALUES(@CustomerId,@UserId,'completed',@Total,SYSDATETIME(),@FullName,@Phone,@Email,@Address);
  SET @OrderId=SCOPE_IDENTITY();
  INSERT dbo.OrderItems(OrderId,ProductId,Quantity,UnitPrice,UnitCost) SELECT @OrderId,ProductId,Quantity,UnitPrice,UnitCost FROM @Cart;
  UPDATE p SET StockQuantity=p.StockQuantity-c.Quantity FROM dbo.Products p JOIN @Cart c ON c.ProductId=p.ProductId;
  COMMIT; SELECT @OrderId OrderId,@Total TotalAmount;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_UpdateOrderStatus @OrderId INT,@Status VARCHAR(12) AS
BEGIN SET NOCOUNT ON; IF @Status NOT IN('draft','completed','cancelled') THROW 51010,N'Trạng thái không hợp lệ.',1;
 UPDATE dbo.Orders SET Status=@Status,CompletedAt=CASE WHEN @Status='completed' THEN COALESCE(CompletedAt,SYSDATETIME()) ELSE NULL END WHERE OrderId=@OrderId;
 IF @@ROWCOUNT=0 THROW 51011,N'Không tìm thấy đơn hàng.',1; END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_StockIn @ProductId INT,@Quantity INT,@UnitCost DECIMAL(18,2) AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; IF @Quantity<=0 OR @UnitCost<0 THROW 51020,N'Số lượng hoặc giá vốn không hợp lệ.',1;
 BEGIN TRAN; UPDATE dbo.Products WITH(UPDLOCK) SET StockQuantity=StockQuantity+@Quantity,CostPrice=@UnitCost WHERE ProductId=@ProductId;
 IF @@ROWCOUNT=0 BEGIN ROLLBACK; THROW 51021,N'Không tìm thấy sản phẩm.',1; END; COMMIT; END;
GO
