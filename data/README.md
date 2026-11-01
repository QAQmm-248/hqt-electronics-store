# Dữ liệu mẫu 3K Store

`products_master.csv` và `du_lieu_nop_thiet_bi_dien_tu.csv` hiện có 500 dòng và 500 SKU không trùng. Nhóm hàng gồm điện thoại, laptop, máy tính bảng, màn hình và phụ kiện. `image_file` trỏ đến tệp ở `anh_san_pham/`; `image_path` là đường dẫn web `/product-images/<tên-tệp>`.

Có 500 tệp ảnh mở được, nhưng 206 tệp trùng nội dung ảnh với tệp khác. Có 200 sản phẩm mang nhãn `Phiên bản tham khảo` là biến thể dữ liệu mẫu, chưa được xác minh là sản phẩm thu thập độc lập. Trường `source_site` chỉ ghi tên website nguồn, không ghi URL. Giá vốn và tồn kho là số liệu mô phỏng.

CSV chỉ là dữ liệu nạp ban đầu. Đơn hàng và tồn kho thực tế nằm trong SQL Server; mua hàng trên web không tự sửa CSV.
