/*
  3K Store / PhoneStore - chuỗi chạy SQL Server
  Mở SSMS ở chế độ SQLCMD (Query > SQLCMD Mode) và chạy file này.
  Bước 0 là tuỳ chọn và XÓA/TẠO LẠI PhoneStore. Chỉ chạy trên database thử nghiệm.
  Nếu đang dùng database hiện tại, bắt đầu từ Bước 1.
*/

/* BƯỚC 0 - tạo lại database thử nghiệm (destructive) */
-- :r .\01_database_init.sql

/* BƯỚC 1 - nâng cấp schema, không xoá dữ liệu */
:r .\02_schema_upgrade.sql

/* BƯỚC 2 - nạp catalog */
:r .\03_catalog_seed.sql
:r .\04_catalog_expand.sql
:r .\05_hide_base_samples.sql
:r .\06_product_filters.sql

/* BƯỚC 3 - nghiệp vụ web */
:r .\07_checkout.sql
:r .\08_business_logic.sql

/* BƯỚC 4 - phân quyền và tài khoản kiểm thử */
:r .\10_security_roles.sql
-- :r .\90_demo_accounts.sql

/* BƯỚC 5 - báo cáo chỉ đọc và kiểm tra đồng bộ */
:r .\09_report_queries.sql
:r .\11_security_tests.sql
:r .\12_order_sync_check.sql

/* Không tự chạy 91_cleanup_legacy.sql; chỉ dùng khi đã duyệt SKU cần xử lý. */
