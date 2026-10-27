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

/* Positive checks: reporting views and checkout procedure must be executable. */
SELECT HAS_PERMS_BY_NAME(N'dbo.vw_ProductInventory','OBJECT','SELECT') AS CanReadProductView,
       HAS_PERMS_BY_NAME(N'dbo.usp_CreateOrder','OBJECT','EXECUTE') AS CanCreateOrder;
GO

/* Negative checks are expressed as explicit DENY rows, avoiding destructive tests. */
SELECT pr.name AS PrincipalName, pe.state_desc, pe.permission_name,
       OBJECT_SCHEMA_NAME(pe.major_id)+N'.'+OBJECT_NAME(pe.major_id) AS ObjectName
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pr.principal_id=pe.grantee_principal_id
WHERE pr.name IN (N'role_report_viewer',N'role_store_staff',N'phone_app')
  AND pe.state_desc='DENY'
ORDER BY pr.name,ObjectName,pe.permission_name;
GO
