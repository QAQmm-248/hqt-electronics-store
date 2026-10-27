/* Module 07 - bảo mật và phân quyền cho 3K Store */
USE PhoneStore;
GO
SET NOCOUNT ON;

/* Server LOGIN is deliberately not created automatically. It requires a DBA-owned
   secret. The application login phone_app is provisioned separately in admin.env. */
-- CREATE LOGIN report_reader WITH PASSWORD = N'<DBA tạo mật khẩu riêng, tối thiểu 12 ký tự>';

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_store_admin') CREATE ROLE role_store_admin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_store_staff') CREATE ROLE role_store_staff;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_report_viewer') CREATE ROLE role_report_viewer;
GO

/* Read-only reporting surface. Direct table access is not granted. */
GRANT SELECT ON dbo.vw_ProductInventory TO role_report_viewer;
GRANT SELECT ON dbo.vw_OrderDetails TO role_report_viewer;
GRANT SELECT ON dbo.vw_MonthlyRevenue TO role_report_viewer;
GRANT SELECT ON dbo.vw_AdminDashboard TO role_report_viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Products TO role_report_viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Orders TO role_report_viewer;
DENY INSERT, UPDATE, DELETE ON dbo.OrderItems TO role_report_viewer;
GO

/* Staff can manage catalog through stored procedures and read reporting views. */
GRANT SELECT ON dbo.vw_ProductInventory TO role_store_staff;
GRANT SELECT ON dbo.vw_OrderDetails TO role_store_staff;
GRANT EXECUTE ON dbo.usp_StockIn TO role_store_staff;
GRANT EXECUTE ON dbo.usp_UpdateOrderStatus TO role_store_staff;
DENY DELETE ON dbo.Products TO role_store_staff;
GO

/* Admin receives the operational surface. */
GRANT SELECT, INSERT, UPDATE ON dbo.Products TO role_store_admin;
GRANT SELECT, INSERT, UPDATE ON dbo.Brands TO role_store_admin;
GRANT SELECT, INSERT, UPDATE ON dbo.Categories TO role_store_admin;
GRANT SELECT ON dbo.vw_ProductInventory TO role_store_admin;
GRANT SELECT ON dbo.vw_OrderDetails TO role_store_admin;
GRANT SELECT ON dbo.vw_MonthlyRevenue TO role_store_admin;
GRANT SELECT ON dbo.vw_AdminDashboard TO role_store_admin;
GRANT EXECUTE ON dbo.usp_StockIn TO role_store_admin;
GRANT EXECUTE ON dbo.usp_UpdateOrderStatus TO role_store_admin;
GRANT EXECUTE ON dbo.usp_CreateOrder TO role_store_admin;
GO

/* Application login uses API authorization; keep its SQL surface narrow. */
GRANT SELECT ON dbo.vw_ProductInventory TO phone_app;
GRANT SELECT ON dbo.vw_OrderDetails TO phone_app;
GRANT SELECT ON dbo.vw_MonthlyRevenue TO phone_app;
GRANT SELECT ON dbo.vw_AdminDashboard TO phone_app;
GRANT SELECT ON dbo.Categories TO phone_app;
GRANT SELECT ON dbo.Brands TO phone_app;
GRANT EXECUTE ON dbo.usp_CreateOrder TO phone_app;
DENY DELETE ON dbo.Products TO phone_app;
GO
