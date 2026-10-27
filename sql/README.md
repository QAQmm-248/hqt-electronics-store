# SQL chuẩn cho 3K Store

Chạy bằng Windows Authentication trên máy có SQL Server:

1. `01_schema.sql`: nâng cấp PhoneStore không xóa database hoặc tài khoản/đơn hàng; đồng bộ bảng Module 1–2, view, function, stored procedure và role `admin`/`user`.
2. `02_catalog_seed.sql` và `06_catalog_expand.sql`: nhập/cập nhật danh mục hiện tại; không ghi URL nguồn hoặc tắt sản phẩm admin thêm.
3. `03_report_queries.sql`: 10 truy vấn báo cáo tham khảo.
4. `04_cleanup_legacy.sql`: chỉ dọn 30 SKU cũ đã xác định; nếu có giao dịch thì lưu lịch sử và ngừng bán. Đồng thời chuyển ảnh sang `/product-images/`.

5. `07_checkout.sql`: cài `dbo.usp_CreateOrder` và cấp quyền chạy cho tài khoản `phone_app`. Đây là phần bắt buộc để web ghi đơn, dòng đơn và trừ tồn kho trong một giao dịch.

Chạy file cần thiết trong SSMS sau khi chọn đúng database PhoneStore, hoặc dùng sqlcmd Windows Authentication. `sql/module1,2.sql` được giữ làm tài liệu bài tập; không chạy lại trên PhoneStore đang có dữ liệu vì file này tạo lại bảng và dữ liệu mẫu.

## Phân quyền

`dbo.Users.RoleName` chỉ nhận `admin` hoặc `user`. API đăng ký luôn tạo `user`; API quản trị kiểm tra `admin` và đọc lại role/trạng thái từ SQL cho mỗi request. Không tạo tài khoản admin qua form công khai. Mật khẩu ứng dụng lưu dạng PBKDF2; không lưu mật khẩu mẫu trong SQL.

## Nguồn dữ liệu

`data/du_lieu_nop_thiet_bi_dien_tu.csv` là bộ dữ liệu nộp không có URL. `data/products_master.csv` là bản chuẩn hóa dùng để đồng bộ website và SQL; `image_path` trỏ tới `data/anh_san_pham/`, được FastAPI phục vụ tại `/product-images/`. Đây là một bản ảnh dùng chung, không nhân đôi trong thư mục static. Giá/tồn là dữ liệu mô phỏng học tập, không phải số liệu tồn kho trực tiếp từ nhà bán lẻ.
