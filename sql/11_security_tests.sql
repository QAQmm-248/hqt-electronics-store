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
