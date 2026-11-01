/* Module 07 - bảo mật và phân quyền cho 3K Store */
USE PhoneStore;
GO
SET NOCOUNT ON;

/* LOGIN/USER mẫu: chỉ bật khi DBA đã thay mật khẩu mẫu bằng mật khẩu riêng.
   Không đưa mật khẩu thật vào kho mã nguồn. */
-- CREATE LOGIN report_reader WITH PASSWORD = N'<DBA thay bằng mật khẩu riêng tối thiểu 12 ký tự>';

/* Tạo database role nếu chưa có. */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_store_admin') CREATE ROLE role_store_admin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_store_staff') CREATE ROLE role_store_staff;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'role_report_viewer') CREATE ROLE role_report_viewer;
GO

/* Nếu LOGIN đã được DBA tạo trước đó thì tạo USER và gán role. */
IF SUSER_ID(N'report_reader') IS NOT NULL
BEGIN
    IF DATABASE_PRINCIPAL_ID(N'report_reader') IS NULL
        CREATE USER report_reader FOR LOGIN report_reader;
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.database_role_members drm
        JOIN sys.database_principals r ON r.principal_id=drm.role_principal_id
        JOIN sys.database_principals u ON u.principal_id=drm.member_principal_id
        WHERE r.name=N'role_report_viewer' AND u.name=N'report_reader'
    )
        ALTER ROLE role_report_viewer ADD MEMBER report_reader;
END;

IF SUSER_ID(N'phone_app') IS NOT NULL
BEGIN
    IF DATABASE_PRINCIPAL_ID(N'phone_app') IS NULL
        CREATE USER phone_app FOR LOGIN phone_app;
END;
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

/* Ung dung kiem tra quyen tai API; quyen SQL cua phone_app duoc gioi han. */
IF DATABASE_PRINCIPAL_ID(N'phone_app') IS NOT NULL
BEGIN
    GRANT SELECT ON dbo.vw_ProductInventory TO phone_app;
    GRANT SELECT ON dbo.vw_OrderDetails TO phone_app;
    GRANT SELECT ON dbo.vw_MonthlyRevenue TO phone_app;
    GRANT SELECT ON dbo.vw_AdminDashboard TO phone_app;
    GRANT SELECT ON dbo.Categories TO phone_app;
    GRANT SELECT ON dbo.Brands TO phone_app;
    GRANT EXECUTE ON dbo.usp_CreateOrder TO phone_app;
    DENY DELETE ON dbo.Products TO phone_app;
END;
GO

/* Ví dụ REVOKE dùng khi thu hồi quyền tạm thời. Chạy theo tình huống quản trị,
   sau đó cấp lại quyền nếu tài khoản vẫn cần xem doanh thu. */
-- REVOKE SELECT ON dbo.vw_MonthlyRevenue FROM role_report_viewer;
