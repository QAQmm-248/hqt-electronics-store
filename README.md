# 3K Store — quản lý cửa hàng thiết bị điện tử

Website FastAPI phục vụ trang mua hàng và trang quản trị tại `localhost:8000`. SQL Server `PhoneStore` là nguồn dữ liệu đang chạy: sản phẩm, tài khoản, đơn hàng và tồn kho. Tên hiển thị là **3K Store**; giữ tên database `PhoneStore`, tài khoản SQL `phone_app` và các định danh container để không làm hỏng kết nối hiện có.

## Cấu trúc và chạy

- `sql/01_database_init.sql`: script nền của bài tập, **xóa và tạo lại toàn bộ PhoneStore**. Không chạy trên database đang chứa đơn hàng hoặc tài khoản cần giữ.
- `sql/02_schema_upgrade.sql`: bổ sung cột web vào schema nền; tạo 4 view, 2 function và 3 procedure. `sql/03_catalog_seed.sql` và `sql/04_catalog_expand.sql` nạp 500 SKU.
- `sql/07_checkout.sql`: cài lại procedure đặt hàng và cấp quyền thực thi cho `phone_app`. `sql/05_hide_base_samples.sql` ngừng bán 40 sản phẩm mẫu nền sau khi nạp catalog, không xóa bản ghi.
- `sql/09_report_queries.sql`: 11 truy vấn báo cáo; `sql/06_product_filters.sql`: lọc sản phẩm.
- `data/products_master.csv`: danh mục chuẩn hóa; `data/du_lieu_nop_thiet_bi_dien_tu.csv`: bản nộp. Ảnh ở `data/anh_san_pham/`, web phục vụ qua `/product-images/`.

Trên máy đã cài Docker Desktop và cấu hình `admin.env`, mở PowerShell trong thư mục này, chạy `docker compose up -d --build web`. Mở `http://localhost:8000/`, `/admin`, `/health`. Thứ tự SQL cho database mới và lưu ý khi nâng cấp xem [sql/README.md](sql/README.md). Giữ `admin.env` ngoài Git.

Để chạy chuỗi SQL theo thứ tự, mở `master_run.sql` trong SSMS và bật **Query > SQLCMD Mode**. Bước tạo lại database nằm trong file nhưng đang comment; chỉ bỏ comment khi dùng database thử nghiệm. Để kiểm thử an toàn trên database hiện tại, chạy `.\run_readonly_tests.ps1`; script chỉ parse toàn bộ SQL và chạy các truy vấn đọc.

## Dòng dữ liệu và kiểm tra

Web đọc sản phẩm qua `vw_ProductInventory`. Khi đặt hàng thành công, API gọi `usp_CreateOrder`: SQL ghi `Orders` và `OrderItems`, giảm `Products.StockQuantity` trong một giao dịch. Quản trị đọc `vw_AdminDashboard`, `vw_MonthlyRevenue`, `vw_OrderDetails`. Sau khi đặt hàng, chạy [12_order_sync_check.sql](sql/12_order_sync_check.sql) trong SSMS để kiểm chứng. CSV là dữ liệu mẫu ban đầu, không tự đổi khi khách mua hàng.

Các file được web sử dụng trực tiếp: `02_schema_upgrade.sql` (view/procedure nền), `06_product_filters.sql` (lọc), `07_checkout.sql` (đặt hàng), `10_security_roles.sql` (quyền), và các view `vw_ProductInventory`, `vw_AdminDashboard`, `vw_MonthlyRevenue`, `vw_OrderDetails`. Các file báo cáo, kiểm thử quyền, Module 05/06 và `91_cleanup_legacy.sql` không được API tự gọi; chúng là script bài tập hoặc vận hành thủ công.

## Phạm vi dữ liệu và tình trạng xác minh

Hai CSV có 500 dòng và 500 SKU khác nhau; 500 tệp ảnh đọc được, nhưng chỉ có 294 nội dung ảnh khác nhau. Có 200 tên `Phiên bản tham khảo` là biến thể dữ liệu mẫu dùng lại ảnh; không trình bày thành 500 sản phẩm độc lập đã cào. Giá vốn và tồn kho là dữ liệu mô phỏng.

Đề PDF yêu cầu tối thiểu 6 bảng chính, ràng buộc dữ liệu, dữ liệu mẫu, 10 truy vấn nghiệp vụ, 3 procedure, 2 function, 3 view, hướng dẫn chạy, báo cáo và slide. Script nền có 11 bảng; script mở rộng có 4 view, 3 procedure, 2 function; truy vấn báo cáo có 11 câu. Ngày 01/11/2026, `/health` trả 200 với database `PhoneStore`; API có 500 sản phẩm đang bán khớp 500 SKU của CSV, không thiếu đường dẫn ảnh. SQL hiện có 3 đơn/3 dòng đơn; 3 đơn xuất hiện qua view và tổng tiền khớp dòng đơn. **Chưa chạy lại toàn bộ script trên một database thử nghiệm và chưa đặt đơn thử trong lần rà soát này.** Vẫn cần đối chiếu ERD, từ điển dữ liệu, báo cáo PDF và slide với mã thực tế.
