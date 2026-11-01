# SQL của 3K Store — database PhoneStore

## Chạy trên database thử nghiệm mới

File điều phối là `master_run.sql` ở thư mục gốc. Mở SSMS, bật **Query > SQLCMD Mode**, chọn thư mục `sql` làm thư mục làm việc rồi chạy file. Bước tạo lại database trong file đang được comment để tránh xoá nhầm dữ liệu; chỉ bỏ comment `:r .\01_database_init.sql` khi đã kết nối đúng máy thử nghiệm.

1. `01_database_init.sql`: tạo lại toàn bộ PhoneStore và dữ liệu mẫu. **Có lệnh DROP DATABASE**; chỉ chạy trên database thử nghiệm có thể xóa.
2. `02_schema_upgrade.sql`: nâng cấp schema nền cho web, giữ các role `admin`, `staff`, `customer` và cho phép `user` của web.
3. `03_catalog_seed.sql`, rồi `04_catalog_expand.sql`: nạp catalog tới 500 SKU.
4. `05_hide_base_samples.sql`: ngừng bán 40 sản phẩm mẫu `SKU-001`–`SKU-040` nếu chưa có dòng đơn; giữ nguyên bản ghi. Sau đó chạy `06_product_filters.sql` để tạo thủ tục lọc danh mục, thương hiệu và từ khóa.
5. `07_checkout.sql`: cài thủ tục đặt hàng. Cần tạo SQL user `phone_app` trước câu `GRANT` cuối tệp.
6. `08_business_logic.sql`: tạo 2 hàm, 3 thủ tục và trigger nghiệp vụ; file này chỉ tạo đối tượng, không tự chạy thao tác thử thay đổi dữ liệu.
7. `09_report_queries.sql`: 11 truy vấn nghiệp vụ, chỉ đọc; có JOIN, GROUP BY/HAVING, truy vấn con, UNION, TOP, BETWEEN và LIKE.
8. `10_security_roles.sql`: tạo role, cấp quyền, DENY và có khối tạo USER/gán `report_reader` khi LOGIN đã được DBA tạo trước. Lệnh `CREATE LOGIN` vẫn để comment để không đưa mật khẩu vào kho mã nguồn. `phone_app` chỉ nhận quyền khi database principal đã tồn tại.
9. `11_security_tests.sql`: xem metadata quyền, kiểm tra quyền trong ngữ cảnh `phone_app` nếu USER tồn tại và thử thao tác DELETE không làm thay đổi dữ liệu. Muốn kiểm tra LOGIN thật, DBA phải tạo tài khoản riêng rồi chạy lại.
10. `12_order_sync_check.sql`: đối chiếu dữ liệu sau khi đặt hàng qua web.

`91_cleanup_legacy.sql` chỉ dùng với các SKU cũ được nêu trong tệp. `90_demo_accounts.sql` tạo/cập nhật tài khoản demo; không chạy trên tài khoản thật.

Các file trong `Module05_Transactions` và `Module06_ErrorHandling` là bài tập giao dịch/kiểm thử, không thuộc chuỗi cài đặt web ở trên. Một số lệnh trong đó tạo đơn thử hoặc mở nhiều session, vì vậy chỉ chạy trên database thử nghiệm theo README riêng. Hiện thủ tục bán hàng ở Module 05 chưa ghi `Orders.TotalAmount`; thủ tục tạo đơn an toàn ở Module 06 để đơn ở trạng thái `draft` và chưa ghi tổng tiền. Không dùng các thủ tục đó thay cho `usp_CreateOrder` của web nếu chưa đồng bộ quy tắc doanh thu.

## Database đang sử dụng

Sao lưu trước khi nâng cấp. **Không chạy lại `01_database_init.sql`** vì script xóa PhoneStore. Chỉ chạy các tệp cần thiết sau khi kiểm tra schema hiện có. `03_catalog_seed.sql` có nhánh cập nhật theo SKU, nên có thể ghi đè giá hoặc metadata đã chỉnh trong trang quản trị. Không coi việc chạy lại seed là đồng bộ hai chiều. Các thư mục tên `Module05_Transactions` và `Module06_ErrorHandling` là phần bài tập riêng, chưa được thay đổi mã trong đợt sửa này.

Ngày 01/11/2026 đã kiểm tra SQL Server trực tiếp: 500 sản phẩm đang bán khớp 500 SKU CSV; 3 đơn có tổng tiền khớp dòng đơn. `05_hide_base_samples.sql` được lưu để có thể lặp lại bước ngừng bán 40 mẫu nền. Chưa chạy lại toàn bộ thứ tự script trên database thử nghiệm; hãy thử trên bản sao trước khi áp dụng lên dữ liệu thật.

Ngày 01/11/2026 kiểm tra cú pháp bằng `SET PARSEONLY ON`: cả 20 file SQL đều không báo lỗi cú pháp. Đã chạy chỉ đọc `09_report_queries.sql`, `11_security_tests.sql`, `12_order_sync_check.sql`: không có lỗi thực thi. Chưa xác nhận chạy liền mạch các script tạo/cập nhật trên database mới vì tài khoản kiểm tra không có quyền tạo database; tuyệt đối không chạy `01_database_init.sql` trên PhoneStore đang dùng vì file này xóa database cũ.

Để chạy lại kiểm thử an toàn trong PowerShell: `.\run_readonly_tests.ps1`. Script này chỉ kiểm tra cú pháp và chạy các truy vấn đọc; không tạo database, không đổi tồn kho và không tạo đơn.
