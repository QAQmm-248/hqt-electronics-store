/* Module 07 - bảo mật và phân quyền cho 3K Store */
USE PhoneStore;
GO
SET NOCOUNT ON;

/* Khong tu dong tao LOGIN may chu; DBA phai quan ly mat khau rieng.
   Thong tin ket noi phone_app cua ung dung duoc cau hinh trong admin.env. */
-- CREATE LOGIN report_reader WITH PASSWORD = N'<DBA tạo mật khẩu riêng, tối thiểu 12 ký tự>';

/* Tạo database role nếu chưa có. File này chưa tạo LOGIN/USER và chưa gán thành viên vào role. */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_store_admin') CREATE ROLE role_store_admin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_store_staff') CREATE ROLE role_store_staff;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_report_viewer') CREATE ROLE role_report_viewer;
GO

/* Chi cap quyen doc cac view bao cao; khong cap quyen doc truc tiep bang. */
GRANT SELECT ON dbo.vw_ProductInventory TO role_report_viewer;
GRANT SELECT ON dbo.vw_OrderDetails TO role_report_viewer;
GRANT SELECT ON dbo.vw_MonthlyRevenue TO role_report_viewer;
GRANT SELECT ON dbo.vw_AdminDashboard TO role_report_viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Products TO role_report_viewer;
DENY INSERT, UPDATE, DELETE ON dbo.Orders TO role_report_viewer;
DENY INSERT, UPDATE, DELETE ON dbo.OrderItems TO role_report_viewer;
GO

/* Nhan vien thuc hien nghiep vu qua thu tuc va doc cac view duoc cap quyen. */
GRANT SELECT ON dbo.vw_ProductInventory TO role_store_staff;
GRANT SELECT ON dbo.vw_OrderDetails TO role_store_staff;
GRANT EXECUTE ON dbo.usp_StockIn TO role_store_staff;
GRANT EXECUTE ON dbo.usp_UpdateOrderStatus TO role_store_staff;
DENY DELETE ON dbo.Products TO role_store_staff;
GO

/* Vai tro quan tri duoc cap quyen tren cac doi tuong nghiep vu can thiet. */
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

/* phone_app phải là database principal đã tồn tại trước khi chạy các GRANT bên dưới. */
/* Ung dung kiem tra quyen tai API; quyen SQL cua phone_app duoc gioi han. */
GRANT SELECT ON dbo.vw_ProductInventory TO phone_app;
GRANT SELECT ON dbo.vw_OrderDetails TO phone_app;
GRANT SELECT ON dbo.vw_MonthlyRevenue TO phone_app;
GRANT SELECT ON dbo.vw_AdminDashboard TO phone_app;
GRANT SELECT ON dbo.Categories TO phone_app;
GRANT SELECT ON dbo.Brands TO phone_app;
GRANT EXECUTE ON dbo.usp_CreateOrder TO phone_app;
DENY DELETE ON dbo.Products TO phone_app;
GO
