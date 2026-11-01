/* Module 07 - kiểm thử quyền. Chạy trong SSMS bằng tài khoản DBA để xem kết quả. */
USE PhoneStore;
GO
SELECT name, type_desc FROM sys.database_principals
WHERE name IN (N'role_store_admin',N'role_store_staff',N'role_report_viewer',N'phone_app');
GO
SELECT pr.name AS PrincipalName, pe.state_desc, pe.permission_name,
       OBJECT_SCHEMA_NAME(pe.major_id)+N'.'+OBJECT_NAME(pe.major_id) AS ObjectName
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pr.principal_id=pe.grantee_principal_id
WHERE pr.name IN (N'role_store_admin',N'role_store_staff',N'role_report_viewer',N'phone_app')
ORDER BY pr.name,ObjectName,pe.permission_name;
GO

/* Kiểm thử trong đúng ngữ cảnh của phone_app nếu USER đã tồn tại. */
IF DATABASE_PRINCIPAL_ID(N'phone_app') IS NOT NULL
BEGIN
    EXECUTE AS USER = N'phone_app';
    SELECT USER_NAME() AS CurrentUser,
           HAS_PERMS_BY_NAME(N'dbo.vw_ProductInventory','OBJECT','SELECT') AS CanReadProductView,
           HAS_PERMS_BY_NAME(N'dbo.usp_CreateOrder','OBJECT','EXECUTE') AS CanCreateOrder,
           HAS_PERMS_BY_NAME(N'dbo.Products','OBJECT','DELETE') AS CanDeleteProducts;
    REVERT;
END;
GO

/* Thử thao tác bị từ chối mà không thay đổi dữ liệu. */
IF DATABASE_PRINCIPAL_ID(N'phone_app') IS NOT NULL
BEGIN
    EXECUTE AS USER = N'phone_app';
    BEGIN TRY
        BEGIN TRAN;
        DELETE FROM dbo.Products WHERE ProductId = -1;
        ROLLBACK;
        SELECT N'Không phát sinh lỗi quyền vì không có dòng phù hợp' AS TestResult;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
    REVERT;
END;
GO

/* HAS_PERMS_BY_NAME phản ánh ngữ cảnh đang chạy truy vấn; tự nó không giả lập từng role. */
/* Kiem tra quyen doc view bao cao va quyen thuc thi thu tuc dat hang. */
SELECT HAS_PERMS_BY_NAME(N'dbo.vw_ProductInventory','OBJECT','SELECT') AS CanReadProductView,
       HAS_PERMS_BY_NAME(N'dbo.usp_CreateOrder','OBJECT','EXECUTE') AS CanCreateOrder;
GO

/* Truy vấn dưới đây liệt kê DENY đã cấu hình; chưa trực tiếp thử đăng nhập và thao tác bằng từng principal. */
/* Kiem tra quyen bi tu choi qua cac dong DENY, khong chay thao tac pha huy. */
SELECT pr.name AS PrincipalName, pe.state_desc, pe.permission_name,
       OBJECT_SCHEMA_NAME(pe.major_id)+N'.'+OBJECT_NAME(pe.major_id) AS ObjectName
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pr.principal_id=pe.grantee_principal_id
WHERE pr.name IN (N'role_report_viewer',N'role_store_staff',N'phone_app')
  AND pe.state_desc='DENY'
ORDER BY pr.name,ObjectName,pe.permission_name;
GO
