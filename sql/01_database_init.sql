/* Module 1-2: script nền minh họa tạo schema và dữ liệu mẫu cho PhoneStore. */
USE master;
GO

CREATE DATABASE PhoneStore;
GO
USE PhoneStore;
GO

/* Nhóm tài khoản và hồ sơ người dùng của hệ thống. */
CREATE TABLE dbo.Users
(
    UserId       INT IDENTITY(1,1) NOT NULL,
    Username     VARCHAR(50) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    RoleName     VARCHAR(10) NOT NULL CONSTRAINT DF_Users_RoleName DEFAULT ('customer'),
    IsActive     BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    CreatedAt    DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Users PRIMARY KEY (UserId),
    CONSTRAINT UQ_Users_Username UNIQUE (Username),
    CONSTRAINT CK_Users_RoleName CHECK (RoleName IN ('admin','staff','customer'))
);
GO

CREATE TABLE dbo.Employees
(
    EmployeeId INT IDENTITY(1,1) NOT NULL,
    UserId     INT NOT NULL,
    FullName   NVARCHAR(150) NOT NULL,
    Phone      VARCHAR(10) NOT NULL,
    Position   NVARCHAR(80) NOT NULL CONSTRAINT DF_Employees_Position DEFAULT (N'Nhân viên bán hàng'),
    IsActive   BIT NOT NULL CONSTRAINT DF_Employees_IsActive DEFAULT (1),
    CONSTRAINT PK_Employees PRIMARY KEY (EmployeeId),
    CONSTRAINT UQ_Employees_UserId UNIQUE (UserId),
    CONSTRAINT UQ_Employees_Phone UNIQUE (Phone),
    CONSTRAINT CK_Employees_Phone CHECK (LEN(Phone) = 10 AND Phone NOT LIKE '%[^0-9]%'),
    CONSTRAINT FK_Employees_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId)
);
GO

CREATE TABLE dbo.Customers
(
    CustomerId INT IDENTITY(1,1) NOT NULL,
    UserId     INT NULL,
    FullName   NVARCHAR(150) NOT NULL,
    Phone      VARCHAR(10) NOT NULL,
    Email      VARCHAR(150) NULL,
    Address    NVARCHAR(250) NULL,
    CreatedAt  DATETIME2(0) NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerId),
    CONSTRAINT UQ_Customers_Phone UNIQUE (Phone),
    CONSTRAINT CK_Customers_Phone CHECK (LEN(Phone) = 10 AND Phone NOT LIKE '%[^0-9]%'),
    CONSTRAINT FK_Customers_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId)
);
GO
CREATE UNIQUE INDEX UQ_Customers_UserId_NotNull
    ON dbo.Customers(UserId) WHERE UserId IS NOT NULL;
GO

/* Danh mục, thương hiệu và sản phẩm tạo thành phần catalog. */
CREATE TABLE dbo.Categories
(
    CategoryId   INT IDENTITY(1,1) NOT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    IsActive     BIT NOT NULL CONSTRAINT DF_Categories_IsActive DEFAULT (1),
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryId),
    CONSTRAINT UQ_Categories_CategoryName UNIQUE (CategoryName)
);
GO

CREATE TABLE dbo.Brands
(
    BrandId   INT IDENTITY(1,1) NOT NULL,
    BrandName NVARCHAR(100) NOT NULL,
    IsActive  BIT NOT NULL CONSTRAINT DF_Brands_IsActive DEFAULT (1),
    CONSTRAINT PK_Brands PRIMARY KEY (BrandId),
    CONSTRAINT UQ_Brands_BrandName UNIQUE (BrandName)
);
GO

CREATE TABLE dbo.Suppliers
(
    SupplierId   INT IDENTITY(1,1) NOT NULL,
    SupplierName NVARCHAR(150) NOT NULL,
    Phone        VARCHAR(10) NULL,
    Address      NVARCHAR(250) NULL,
    IsActive     BIT NOT NULL CONSTRAINT DF_Suppliers_IsActive DEFAULT (1),
    CONSTRAINT PK_Suppliers PRIMARY KEY (SupplierId),
    CONSTRAINT UQ_Suppliers_SupplierName UNIQUE (SupplierName),
    CONSTRAINT CK_Suppliers_Phone CHECK (Phone IS NULL OR (LEN(Phone) = 10 AND Phone NOT LIKE '%[^0-9]%'))
);
GO

/* Sản phẩm giữ khóa tham chiếu đến danh mục và thương hiệu; giá/tồn có ràng buộc miền. */
CREATE TABLE dbo.Products
(
    ProductId     INT IDENTITY(1,1) NOT NULL,
    SKU           VARCHAR(30) NOT NULL,
    ProductName   NVARCHAR(200) NOT NULL,
    BrandId       INT NOT NULL,
    CategoryId    INT NOT NULL,
    SalePrice     DECIMAL(18,2) NOT NULL,
    CostPrice     DECIMAL(18,2) NOT NULL CONSTRAINT DF_Products_CostPrice DEFAULT (0),
    StockQuantity INT NOT NULL CONSTRAINT DF_Products_StockQuantity DEFAULT (0),
    IsActive      BIT NOT NULL CONSTRAINT DF_Products_IsActive DEFAULT (1),
    CreatedAt     DATETIME2(0) NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Products PRIMARY KEY (ProductId),
    CONSTRAINT UQ_Products_SKU UNIQUE (SKU),
    CONSTRAINT CK_Products_SalePrice CHECK (SalePrice >= 0),
    CONSTRAINT CK_Products_CostPrice CHECK (CostPrice >= 0),
    CONSTRAINT CK_Products_StockQuantity CHECK (StockQuantity >= 0),
    CONSTRAINT FK_Products_Brands FOREIGN KEY (BrandId) REFERENCES dbo.Brands(BrandId),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories(CategoryId)
);
GO

/* Phiếu nhập và dòng phiếu nhập lưu lịch sử nhận hàng theo nhà cung cấp. */
CREATE TABLE dbo.StockReceipts
(
    ReceiptId            INT IDENTITY(1,1) NOT NULL,
    SupplierId           INT NOT NULL,
    ReceivedByEmployeeId INT NOT NULL,
    ReceivedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_StockReceipts_ReceivedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_StockReceipts PRIMARY KEY (ReceiptId),
    CONSTRAINT FK_StockReceipts_Suppliers FOREIGN KEY (SupplierId) REFERENCES dbo.Suppliers(SupplierId),
    CONSTRAINT FK_StockReceipts_Employees FOREIGN KEY (ReceivedByEmployeeId) REFERENCES dbo.Employees(EmployeeId)
);
GO

CREATE TABLE dbo.StockReceiptItems
(
    ReceiptId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity  INT NOT NULL,
    UnitCost  DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_StockReceiptItems PRIMARY KEY (ReceiptId, ProductId),
    CONSTRAINT CK_StockReceiptItems_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_StockReceiptItems_UnitCost CHECK (UnitCost >= 0),
    CONSTRAINT FK_StockReceiptItems_Receipts FOREIGN KEY (ReceiptId) REFERENCES dbo.StockReceipts(ReceiptId),
    CONSTRAINT FK_StockReceiptItems_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId)
);
GO

/* Đơn hàng và dòng đơn tách riêng để lưu nhiều sản phẩm trong một giao dịch. */
CREATE TABLE dbo.Orders
(
    OrderId             INT IDENTITY(1,1) NOT NULL,
    CustomerId          INT NULL,
    CreatedByEmployeeId INT NOT NULL,
    OrderDate           DATETIME2(0) NOT NULL CONSTRAINT DF_Orders_OrderDate DEFAULT (SYSDATETIME()),
    Status              VARCHAR(12) NOT NULL CONSTRAINT DF_Orders_Status DEFAULT ('draft'),
    CompletedAt         DATETIME2(0) NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (OrderId),
    CONSTRAINT CK_Orders_Status CHECK (Status IN ('draft','completed','cancelled')),
    CONSTRAINT CK_Orders_CompletedAt CHECK
      ((Status = 'completed' AND CompletedAt IS NOT NULL)
       OR (Status = 'draft' AND CompletedAt IS NULL)
       OR Status = 'cancelled'),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId),
    CONSTRAINT FK_Orders_Employees FOREIGN KEY (CreatedByEmployeeId) REFERENCES dbo.Employees(EmployeeId)
);
GO

CREATE TABLE dbo.OrderItems
(
    OrderId   INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity  INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    UnitCost  DECIMAL(18,2) NOT NULL,
    LineTotal AS (CONVERT(DECIMAL(18,2), Quantity * UnitPrice)) PERSISTED,
    CONSTRAINT PK_OrderItems PRIMARY KEY (OrderId, ProductId),
    CONSTRAINT CK_OrderItems_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_OrderItems_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT CK_OrderItems_UnitCost CHECK (UnitCost >= 0),
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(OrderId),
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId)
);
GO

/* Dữ liệu mẫu được nạp theo thứ tự bảng cha trước bảng phụ thuộc. */
INSERT dbo.Users (Username, PasswordHash, RoleName)
VALUES ('admin', 'demo_hash_admin', 'admin'),
       ('staff01', 'demo_hash_staff01', 'staff'),
       ('staff02', 'demo_hash_staff02', 'staff');
GO
;WITH N AS
(
    SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT dbo.Users (Username, PasswordHash, RoleName)
SELECT CONCAT('customer', RIGHT(CONCAT('00', n), 2)), 'demo_hash_customer', 'customer'
FROM N;
GO

INSERT dbo.Employees (UserId, FullName, Phone, Position)
VALUES (2, N'Nguyễn Minh An', '0900000001', N'Quản lý cửa hàng'),
       (3, N'Trần Thu Hà', '0900000002', N'Nhân viên bán hàng');
GO

INSERT dbo.Customers (UserId, FullName, Phone, Email, Address)
SELECT UserId,
       CONCAT(N'Khách hàng ', RIGHT(Username, 2)),
       CONCAT('091', RIGHT(CONCAT('0000000', UserId), 7)),
       CONCAT(Username, '@example.com'),
       CASE WHEN UserId % 2 = 0 THEN N'Hà Nội' ELSE N'TP. Hồ Chí Minh' END
FROM dbo.Users
WHERE RoleName = 'customer';
GO
INSERT dbo.Customers (UserId, FullName, Phone, Email, Address)
VALUES (NULL, N'Khách vãng lai 01', '0920000001', NULL, N'Hà Nội'),
       (NULL, N'Khách vãng lai 02', '0920000002', NULL, N'Đà Nẵng'),
       (NULL, N'Khách vãng lai 03', '0920000003', NULL, N'Hải Phòng'),
       (NULL, N'Khách vãng lai 04', '0920000004', NULL, N'Cần Thơ'),
       (NULL, N'Khách vãng lai 05', '0920000005', NULL, N'TP. Hồ Chí Minh');
GO

INSERT dbo.Categories (CategoryName)
VALUES (N'Điện thoại'), (N'Máy tính bảng'), (N'Laptop'), (N'Phụ kiện');
GO
INSERT dbo.Brands (BrandName)
VALUES (N'Apple'), (N'Samsung'), (N'Xiaomi'), (N'OPPO'), (N'Dell'), (N'Lenovo');
GO
INSERT dbo.Suppliers (SupplierName, Phone, Address)
VALUES (N'Công ty phân phối A', '0241234567', N'Hà Nội'),
       (N'Công ty phân phối B', '0281234567', N'TP. Hồ Chí Minh'),
       (N'Công ty phân phối C', '0236123456', N'Đà Nẵng');
GO

;WITH N AS
(
    SELECT TOP (40) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT dbo.Products (SKU, ProductName, BrandId, CategoryId, SalePrice, CostPrice, StockQuantity)
SELECT CONCAT('SKU-', RIGHT(CONCAT('000', n), 3)),
       CONCAT(N'Sản phẩm mẫu ', RIGHT(CONCAT('00', n), 2)),
       ((n - 1) % 6) + 1,
       ((n - 1) % 4) + 1,
       CONVERT(DECIMAL(18,2), 3000000 + n * 250000),
       CONVERT(DECIMAL(18,2), 2200000 + n * 180000),
       100
FROM N;
GO

;WITH N AS
(
    SELECT TOP (10) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT dbo.StockReceipts (SupplierId, ReceivedByEmployeeId, ReceivedAt)
SELECT ((n - 1) % 3) + 1, ((n - 1) % 2) + 1, DATEADD(DAY, -n, SYSDATETIME())
FROM N;
GO
INSERT dbo.StockReceiptItems (ReceiptId, ProductId, Quantity, UnitCost)
SELECT R.ReceiptId, P.ProductId, 100, P.CostPrice
FROM dbo.StockReceipts R
JOIN dbo.Products P ON P.ProductId BETWEEN ((R.ReceiptId - 1) * 4 + 1) AND (R.ReceiptId * 4);
GO

;WITH N AS
(
    SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT dbo.Orders (CustomerId, CreatedByEmployeeId, OrderDate, Status, CompletedAt)
SELECT ((n - 1) % 35) + 1,
       ((n - 1) % 2) + 1,
       DATEADD(DAY, -n, SYSDATETIME()),
       CASE WHEN n <= 20 THEN 'completed'
            WHEN n <= 25 THEN 'draft'
            ELSE 'cancelled' END,
       CASE WHEN n <= 20 THEN DATEADD(DAY, -n, SYSDATETIME()) ELSE NULL END
FROM N;
GO

INSERT dbo.OrderItems (OrderId, ProductId, Quantity, UnitPrice, UnitCost)
SELECT O.OrderId,
       P.ProductId,
       1 + (O.OrderId % 3),
       P.SalePrice,
       P.CostPrice
FROM dbo.Orders O
JOIN dbo.Products P ON P.ProductId = (((O.OrderId - 1) * 2) % 40) + 1
UNION ALL
SELECT O.OrderId,
       P.ProductId,
       1 + (O.OrderId % 2),
       P.SalePrice,
       P.CostPrice
FROM dbo.Orders O
JOIN dbo.Products P ON P.ProductId = (((O.OrderId - 1) * 2 + 1) % 40) + 1;
GO
