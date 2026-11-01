# Module 05 - Transactions and Concurrency
## Database: PhoneStore

## 1. Muc tieu
Module nay minh hoa cach su dung transaction de dam bao mot nghiep vu nhieu buoc duoc thuc hien tron ven, dong thoi kiem thu cac hien tuong truy cap dong thoi trong SQL Server.

## 2. Transactions

### 2.1. Nghiep vu ban hang
Stored procedure: `dbo.usp_CreateOrderWithTransaction`.

Cac buoc trong cung mot transaction:
1. Kiem tra so luong, khach hang, nhan vien va san pham.
2. Doc va khoa dong san pham bang `UPDLOCK, HOLDLOCK`.
3. Tao ban ghi trong `Orders`.
4. Them chi tiet vao `OrderItems`.
5. Tru `Products.StockQuantity`.
6. Chuyen don hang sang `completed` va cap nhat `CompletedAt`.
7. `COMMIT` neu tat ca thanh cong; `ROLLBACK` neu co loi.

`OrderItems.LineTotal` la computed column, do do khong duoc truyen gia tri truc tiep khi INSERT. SQL Server tu tinh cot nay.

### 2.2. Nghiep vu nhap kho
Stored procedure: `dbo.usp_ProcessStockReceipt`.

Cac buoc trong cung mot transaction:
1. Kiem tra so luong va don gia nhap.
2. Kiem tra va khoa san pham.
3. Kiem tra nha cung cap va nhan vien.
4. Tao phieu nhap trong `StockReceipts`.
5. Them chi tiet vao `StockReceiptItems`.
6. Cong `Products.StockQuantity` va cap nhat `CostPrice`.
7. `COMMIT` neu thanh cong; `ROLLBACK` neu co loi.

### 2.3. Ket qua kiem thu transaction da thuc hien
| Nghiep vu | Truong hop | Ket qua |
|---|---|---|
| Ban hang | Du ton kho, ban 2 san pham | Tao don va chi tiet; ton kho tam thoi tu 100 xuong 98 |
| Ban hang | Rollback transaction kiem thu | Don hang va chi tiet duoc hoan nguyen; ton kho tro ve 100 |
| Ban hang | Yeu cau ban 200 khi ton kho 100 | Loi 50005 - so luong ton kho khong du; giao dich bi rollback |
| Nhap kho | Nhap 5 san pham | Ton kho tam thoi tu 100 len 105; tao phieu va chi tiet |
| Nhap kho | Rollback transaction kiem thu | Phieu nhap, chi tiet va ton kho duoc hoan nguyen |
| Nhap kho | ProductId = -999999 | Loi 52003 - khong tim thay san pham; giao dich bi rollback |

Sau cac kiem thu, du lieu duoc xac nhan tro ve:
- `Products.ProductId = 1`: `StockQuantity = 100`.
- `Orders`: 30 dong.
- `OrderItems`: 60 dong.
- `StockReceipts`: 10 dong.
- `StockReceiptItems`: 40 dong.

## 3. Concurrency

### 3.1. Blocking
Hai session cung cap nhat `Products.ProductId = 1`.
- Session A bat dau transaction, cap nhat dong san pham va giu transaction mo trong 15 giay.
- Session B cap nhat cung dong san pham nen phai cho A giai phong khoa.
- Khi A `COMMIT`, B tiep tuc va hoan tat.

Hien tuong quan sat: Session B bi cho trong khi Session A dang giu khoa. Day la blocking. Cac lenh UPDATE trong bai test gan `StockQuantity` bang chinh gia tri hien tai, nen khong thay doi ton kho.

### 3.2. Deadlock
Hai session cap nhat hai san pham theo thu tu nguoc nhau:
- Session A khoa Product 1, sau do yeu cau Product 2.
- Session B khoa Product 2, sau do yeu cau Product 1.

Moi session giu mot khoa ma session con lai can, tao thanh vong cho (circular wait). SQL Server phat hien deadlock, chon mot session lam deadlock victim va huy transaction do. Loi thuong gap: `1205`. Session con lai co the tiep tuc.

Ket qua kiem thu thuc te da ghi nhan loi:
`Msg 1205: Transaction ... was deadlocked on lock resources ... chosen as the deadlock victim.`

## 4. Co che bao ve du lieu
- `BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`: dam bao cac thao tac lien quan thanh cong hoac that bai cung nhau.
- `TRY...CATCH` va `XACT_STATE()`: xu ly loi va rollback transaction dang mo.
- `SET XACT_ABORT ON`: yeu cau SQL Server huy transaction khi gap mot so loi runtime.
- `UPDLOCK, HOLDLOCK`: giu khoa phu hop khi doc san pham de cap nhat, giam nguy co hai giao dich cung dua tren cung so ton kho cu.
- Deadlock victim: SQL Server tu huy mot giao dich de pha vong cho; ung dung co the can thu lai giao dich khi gap loi 1205.

## 5. Cach chay
1. Mo database `PhoneStore` trong SSMS.
2. Chay `10_transactions.sql` mot lan de tao/cap nhat hai stored procedure.
3. Cac khoi kiem thu trong file duoc comment. Bo comment va chay tung khoi rieng neu can lap lai.
4. Mo hai ket noi Query rieng trong SSMS.
5. Kiem thu Blocking: chay khoi BLOCKING trong `session_A.sql`, sau do ngay lap tuc chay khoi BLOCKING trong `session_B.sql`.
6. Kiem thu Deadlock: sau khi blocking ket thuc, bo comment khoi DEADLOCK trong ca hai file; chay A truoc va chay B trong vong 5 giay.
7. Chay phan kiem tra cuoi `11_concurrency_tests.sql`.

## 6. Ket luan
Hai nghiep vu ban hang va nhap kho duoc gom trong transaction de tranh tinh trang cap nhat mot phan. Kiem thu thanh cong va that bai cho thay `COMMIT` va `ROLLBACK` hoat dong theo muc tieu. Kiem thu hai session cho thay SQL Server su dung khoa de dieu phoi truy cap dong thoi, co the phat sinh blocking va phat hien deadlock.
