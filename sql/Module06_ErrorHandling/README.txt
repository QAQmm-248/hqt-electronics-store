MODULE 06 - PHONESTORE
Error Handling and Data Testing

Cac tep trong goi:
1. 12_error_handling.sql
   Tao stored procedure dbo.usp_CreateOrder_Safe. Procedure su dung TRY...CATCH,
   THROW, XACT_ABORT, transaction va khoa UPDLOCK/HOLDLOCK khi doc ton kho.

2. 13_test_cases.sql
   Kiem thu PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, CHECK, DEFAULT,
   quy tac nghiep vu va ROLLBACK. Cac loi du kien duoc bat bang TRY...CATCH.

3. test_report.xlsx
   Bao cao 4 sheet: Tong quan, Chi tiet test, Doi chieu du lieu,
   Tong hop rang buoc.

Cach chay:
- Mo SQL Server Management Studio (SSMS), ket noi instance dang dung.
- Mo database PhoneStore.
- Chay 12_error_handling.sql truoc.
- Chay 13_test_cases.sql sau.
- Xem bang ket qua va tong ket PASS/FAIL o cuoi ket qua truy van.

Ket qua da xac nhan trong lan kiem thu truoc:
8 test PASS, 0 test FAIL.
So luong ban ghi sau kiem thu khong thay doi:
Users 33; Brands 6; Categories 4; Customers 35; Employees 2;
Products 40; Orders 30; OrderItems 60; StockReceipts 10;
StockReceiptItems 40.

Luu y:
- Chay tren database PhoneStore dung schema cua bai lam.
- Khong chay file nay tren database khac neu chua doi ten/cau truc bang.
- LineTotal la cot computed, khong chen gia tri truc tiep vao cot nay.
