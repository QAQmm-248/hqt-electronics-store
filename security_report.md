# Module 07 — Bảo mật và phân quyền

## Mô hình

Ứng dụng có ba nhóm nghiệp vụ: quản trị (`role_store_admin`), nhân viên (`role_store_staff`) và người xem báo cáo (`role_report_viewer`). Tài khoản web `phone_app` chỉ được đọc các view cần cho cửa hàng và gọi thủ tục tạo đơn. Người dùng đăng ký trên web luôn nhận vai trò `user`; API kiểm tra vai trò trong SQL cho từng request.

## Quyền tối thiểu

- Người xem báo cáo: chỉ đọc các view báo cáo, bị DENY thêm/sửa/xóa bảng nghiệp vụ.
- Nhân viên: đọc catalog, nhập kho và đổi trạng thái đơn qua stored procedure, bị DENY xóa sản phẩm.
- Quản trị: quản lý catalog, đọc dashboard và gọi các procedure nghiệp vụ.
- `phone_app`: đọc view/catalog và gọi `usp_CreateOrder`; không được xóa sản phẩm.

## Đối tượng bảo vệ

`vw_ProductInventory`, `vw_OrderDetails`, `vw_MonthlyRevenue` và `vw_AdminDashboard` giới hạn dữ liệu báo cáo. `usp_CreateOrder` ghi Orders/OrderItems và giảm tồn kho trong một transaction. Mật khẩu web được lưu PBKDF2; cookie phiên được ký HMAC và kiểm tra lại tài khoản trong SQL.

## Kiểm thử

Chạy `sql/15_security_tests.sql` bằng tài khoản DBA. Kết quả cần có các role, quyền SELECT/EXECUTE cho thao tác được phép và các dòng DENY cho thao tác bị từ chối. Không chạy lệnh INSERT/DELETE phá dữ liệu để kiểm thử.

## Rủi ro đã kiểm soát

SQL injection được giảm bằng truy vấn tham số hóa; tài khoản bị khóa được kiểm tra lại mỗi request; tồn kho được khóa trong transaction; báo cáo đọc qua view; quyền xóa bị hạn chế. `CREATE LOGIN` được để dạng mẫu có chủ đích vì mật khẩu server phải do DBA đặt riêng, không đưa vào mã nguồn.
