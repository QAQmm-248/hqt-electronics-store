# HQT Store — cửa hàng thiết bị điện tử

Bản web chạy cục bộ, kết nối SQL Server `PhoneStore` qua container Docker. Trang khách hàng đọc sản phẩm và thông số từ `dbo.vw_ProductInventory`; đặt hàng ghi `Orders`/`OrderItems` và giảm `Products.StockQuantity` trong cùng giao dịch SQL. Trang admin đọc KPI từ `dbo.vw_AdminDashboard`, doanh thu từ `dbo.vw_MonthlyRevenue`, chi tiết đơn hàng từ `dbo.vw_OrderDetails`.

## Chạy

Mở PowerShell tại `C:\Users\DELL\Dropbox\PC\Downloads\HQT`, sau đó:

```powershell
docker compose up -d --build web
```

Mở cửa hàng: http://localhost:8000  
Mở quản trị: http://localhost:8000/admin  
Kiểm tra kết nối SQL: http://localhost:8000/health

## Tài khoản admin

Tên đăng nhập: `admin`  
Mật khẩu khởi tạo nằm trong biến `ADMIN_INITIAL_PASSWORD` của `admin.env` trên máy này. Ứng dụng tự thay giá trị hash mẫu trong bảng `Users` khi container khởi động lần đầu. Hãy đổi mật khẩu sau khi đăng nhập và không đưa `admin.env` lên Git/Vercel.

## Cập nhật SQL

Các script SQL nằm trong thư mục `sql/`. `sql/upgrade_web.sql` là migration bổ sung cột `Customers.UserId`, liên kết tài khoản với hồ sơ khách hàng, mở rộng view sản phẩm và tạo view dashboard. Không chạy lại `sql/phone_store_assignment.sql` hoặc `sql/phone_store_assignment_full.sql` lên database đang dùng vì script bài tập lớn xóa và tạo lại bảng.

## Mô hình đề tài

CSDL có 7 bảng nghiệp vụ và ràng buộc PK/FK/UNIQUE/NOT NULL/DEFAULT/CHECK; các view sản phẩm, đơn hàng, doanh thu và dashboard; thủ tục tạo/hủy đơn và thêm sản phẩm; hàm tổng tiền đơn/lợi nhuận; truy vấn mẫu. Hệ thống web bổ sung tài khoản phân vai `admin`/`user`, tồn kho đồng bộ khi mua, quản lý sản phẩm, doanh thu, khách hàng và cảnh báo hàng sắp hết.

## Giới hạn triển khai

Địa chỉ `localhost:8000` chỉ dùng trên máy đang chạy Docker. Vercel không kết nối trực tiếp được đến SQL Server tại `localhost`/cổng nội bộ 1433. Muốn khách hàng truy cập internet, cần triển khai backend và SQL lên hạ tầng cloud có xác thực, TLS, backup và cập nhật `admin.env` bằng secret manager; không mở cổng SQL ra internet.

## Catalog ảnh và giá tham khảo CellphoneS

Ảnh sản phẩm đã được tải về máy vào `static/products/` và được serve cục bộ qua `/static/products/...`; trang bán hàng không phụ thuộc hotlink ảnh. Dữ liệu CSV nằm trong `data/`; đường dẫn trang nguồn và ngày kiểm tra giá được lưu trong cột `SourceURL` / `PriceCheckedAt` và view `vw_ProductInventory`.

Catalog mẫu được đối chiếu ngày 24/10/2026:

- iPhone 15 128GB — 21.990.000đ
- iPhone 15 Pro 256GB — 24.990.000đ
- Samsung Galaxy S24 8/256GB — 16.790.000đ
- Samsung Galaxy A55 8/128GB — 7.590.000đ
- Xiaomi 14 12/256GB — 18.990.000đ
- OPPO Reno12 12/256GB — 9.690.000đ

Giá có thể thay đổi theo thời điểm và chương trình của nhà bán lẻ; đây là dữ liệu tham khảo cho đồ án localhost. Nguồn ảnh và thông tin được lưu theo từng sản phẩm trong SQL. Chạy `sql/refresh_catalog.sql` để áp dụng lại metadata/giá mẫu nếu khôi phục database vào máy khác. File này không tự cào lại giá mới; cần chạy script trong `scripts/` khi muốn làm mới snapshot.
