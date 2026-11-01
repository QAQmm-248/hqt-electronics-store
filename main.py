import base64, hashlib, hmac, json, os, secrets, time
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

import pyodbc
pyodbc.pooling = True
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

app = FastAPI(title="3K Store", version="2.0")
app.mount("/static", StaticFiles(directory="static"), name="static")
app.mount("/product-images", StaticFiles(directory="data/anh_san_pham"), name="product-images")
COOKIE = "hqt_session"


def db():
    server = os.getenv("DB_SERVER", "host.docker.internal,1433")
    name = os.getenv("DB_NAME", "PhoneStore")
    user = os.getenv("DB_USER", "phone_app")
    password = os.getenv("DB_PASSWORD", "")
    if not password:
        raise RuntimeError("Thiếu DB_PASSWORD trong admin.env")
    conn_str = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={name};"
        f"UID={user};PWD={password};Encrypt=no;TrustServerCertificate=yes;"
        "MARS_Connection=Yes;Connection Timeout=8"
    )
    last_error = None
    for attempt in range(3):
        try:
            cn = pyodbc.connect(conn_str, timeout=8, autocommit=False)
            cn.execute("SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; "
                       "SET ANSI_WARNINGS ON; SET ARITHABORT ON; "
                       "SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF")
            return cn
        except pyodbc.Error as exc:
            last_error = exc
            if attempt < 2:
                time.sleep(0.35 * (attempt + 1))
    raise RuntimeError(f"Không thể kết nối SQL Server sau 3 lần thử: {last_error}")


def serial(v):
    if isinstance(v, (datetime, date)):
        return v.isoformat()
    if isinstance(v, Decimal):
        return float(v)
    return v


def rows(cursor):
    keys = [x[0] for x in cursor.description]
    return [{k: serial(v) for k, v in zip(keys, row)} for row in cursor.fetchall()]


def one(cursor):
    result = rows(cursor)
    return result[0] if result else None


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 310000)
    return "pbkdf2_sha256$310000$%s$%s" % (
        base64.urlsafe_b64encode(salt).decode().rstrip("="),
        base64.urlsafe_b64encode(digest).decode().rstrip("="),
    )


def verify_password(password: str, encoded: str) -> bool:
    try:
        scheme, rounds, salt, expected = encoded.split("$")
        if scheme != "pbkdf2_sha256":
            return False
        salt_b = base64.urlsafe_b64decode(salt + "=" * (-len(salt) % 4))
        want = base64.urlsafe_b64decode(expected + "=" * (-len(expected) % 4))
        got = hashlib.pbkdf2_hmac("sha256", password.encode(), salt_b, int(rounds))
        return hmac.compare_digest(got, want)
    except Exception:
        return False


def session_token(user_id: int, username: str, role: str) -> str:
    payload = base64.urlsafe_b64encode(json.dumps(
        {"id": user_id, "username": username, "role": role, "exp": int(time.time()) + 43200},
        separators=(",", ":"),
    ).encode()).decode().rstrip("=")
    signature = hmac.new(os.environ["APP_SECRET"].encode(), payload.encode(), hashlib.sha256).digest()
    return payload + "." + base64.urlsafe_b64encode(signature).decode().rstrip("=")


def current_user(request: Request, admin=False):
    token = request.cookies.get(COOKIE, "")
    try:
        payload, sig = token.split(".", 1)
        expected = hmac.new(os.environ["APP_SECRET"].encode(), payload.encode(), hashlib.sha256).digest()
        actual = base64.urlsafe_b64decode(sig + "=" * (-len(sig) % 4))
        if not hmac.compare_digest(expected, actual):
            raise ValueError()
        data = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        if data["exp"] < time.time():
            raise ValueError()
    except Exception:
        raise HTTPException(401, "Vui lòng đăng nhập")
    # Recheck the account in SQL on every request so disabled users or changed roles
    # cannot continue using a stale cookie.
    cn = db()
    try:
        cur = cn.cursor()
        cur.execute("SELECT Username,RoleName,IsActive FROM dbo.Users WHERE UserId=?", data["id"])
        live = cur.fetchone()
        if not live or not live.IsActive:
            raise HTTPException(401, "Tài khoản đã bị khóa hoặc không còn tồn tại")
        data["username"], data["role"] = live.Username, live.RoleName
    finally:
        cn.close()
    if admin and data.get("role") != "admin":
        raise HTTPException(403, "Chỉ tài khoản quản trị được dùng chức năng này")
    return data


@app.on_event("startup")
def bootstrap_admin():
    initial = os.getenv("ADMIN_INITIAL_PASSWORD", "")
    if not initial:
        return
    cn = db()
    try:
        cur = cn.cursor()
        cur.execute("SELECT UserId, PasswordHash FROM dbo.Users WHERE Username=N'admin' AND RoleName='admin'")
        row = cur.fetchone()
        if row and (row.PasswordHash == "CHANGE_TO_BCRYPT_HASH" or not str(row.PasswordHash).startswith("pbkdf2_sha256$")):
            cur.execute("UPDATE dbo.Users SET PasswordHash=? WHERE UserId=?", hash_password(initial), row.UserId)
            cn.commit()
    finally:
        cn.close()


@app.get("/health")
def health():
    try:
        cn = db(); cur = cn.cursor(); cur.execute("SELECT DB_NAME() AS DatabaseName"); data = one(cur); cn.close()
        return {"status": "healthy", "database": data["DatabaseName"]}
    except Exception as e:
        raise HTTPException(503, f"SQL Server chưa kết nối được: {e}")


@app.get("/api/products")
def products(q: str = "", category: str = "", brand: str = ""):
    cn = db()
    try:
        cur = cn.cursor()
        cur.execute("""SELECT ProductId,SKU,ProductName,BrandName,CategoryName,RAMGB,StorageGB,SalePrice,StockQuantity,ImagePath,IsDemoData,WarrantyMonths,Description,DataSource FROM dbo.vw_ProductInventory
                       WHERE IsActive=1
                         AND (?='' OR ProductName LIKE ? OR SKU LIKE ? OR BrandName LIKE ?)
                         AND (?='' OR CategoryName=?)
                         AND (?='' OR BrandName=?) ORDER BY ProductName""",
                    q, f"%{q}%", f"%{q}%", f"%{q}%", category, category, brand, brand)
        return rows(cur)
    except pyodbc.Error as e:
        raise HTTPException(503, f"Không đọc được view sản phẩm SQL: {e}")
    finally:
        cn.close()


@app.get("/api/categories")
def categories():
    cn = db()
    try:
        cur=cn.cursor(); cur.execute("SELECT CategoryId,CategoryName FROM dbo.Categories ORDER BY CategoryName"); return rows(cur)
    finally: cn.close()


class Account(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=7, max_length=128)

class Register(Account):
    full_name: str = Field(min_length=2, max_length=150)
    phone: str = Field(min_length=10, max_length=10, pattern=r"^[0-9]{10}$")
    email: Optional[str] = Field(default=None, max_length=150)
    address: Optional[str] = Field(default=None, max_length=250)

class Checkout(BaseModel):
    items: list[dict] = Field(min_length=1, max_length=30)
    full_name: str = Field(min_length=2, max_length=150)
    phone: str = Field(min_length=10, max_length=10, pattern=r"^[0-9]{10}$")
    email: Optional[str] = Field(default=None, max_length=150)
    address: Optional[str] = Field(default=None, max_length=250)

class ProductInput(BaseModel):
    sku: str = Field(min_length=2, max_length=30)
    product_name: str = Field(min_length=2, max_length=400)
    brand_id: int
    category_id: int
    ram_gb: Optional[int] = None
    storage_gb: Optional[int] = None
    sale_price: float = Field(ge=0)
    cost_price: float = Field(ge=0)
    stock_quantity: int = Field(ge=0)
    image_path: Optional[str] = Field(default=None, max_length=500)
    warranty_months: Optional[int] = Field(default=12, ge=0, le=120)
    description: Optional[str] = Field(default=None, max_length=1000)


@app.post("/api/register")
def register(data: Register):
    username=data.username.strip()
    cn=db()
    try:
        cur=cn.cursor()
        cur.execute("INSERT dbo.Users(Username,PasswordHash,RoleName) OUTPUT INSERTED.UserId VALUES(?,?,'user')", username, hash_password(data.password))
        user_id=cur.fetchone()[0]
        cur.execute("SELECT CustomerId,UserId FROM dbo.Customers WHERE Phone=?", data.phone)
        existing=cur.fetchone()
        if existing:
            if existing.UserId is not None:
                cn.rollback(); raise HTTPException(409,"Số điện thoại đã gắn với tài khoản khác")
            cur.execute("UPDATE dbo.Customers SET FullName=?,Email=?,Address=?,UserId=? WHERE CustomerId=?", data.full_name,data.email,data.address,user_id,existing.CustomerId)
        else:
            cur.execute("INSERT dbo.Customers(FullName,Phone,Email,Address,UserId) VALUES(?,?,?,?,?)", data.full_name, data.phone, data.email, data.address,user_id)
        cn.commit()
        return {"ok": True, "user_id": user_id}
    except pyodbc.IntegrityError:
        cn.rollback(); raise HTTPException(409, "Tên đăng nhập hoặc số điện thoại đã được sử dụng")
    except Exception:
        cn.rollback(); raise
    finally: cn.close()


@app.post("/api/login")
def login(data: Account, response: Response):
    cn=db()
    try:
        cur=cn.cursor(); cur.execute("SELECT UserId,Username,PasswordHash,RoleName,IsActive FROM dbo.Users WHERE Username=?", data.username.strip())
        row=cur.fetchone()
        if not row or not row.IsActive or not verify_password(data.password, row.PasswordHash):
            raise HTTPException(401, "Tên đăng nhập hoặc mật khẩu không đúng")
        response.set_cookie(COOKIE, session_token(row.UserId,row.Username,row.RoleName), httponly=True,
                            secure=os.getenv("COOKIE_SECURE","0")=="1", samesite="lax", max_age=43200, path="/")
        return {"ok":True,"username":row.Username,"role":row.RoleName}
    finally: cn.close()


@app.post("/api/logout")
def logout(response: Response):
    response.delete_cookie(COOKIE, path="/"); return {"ok":True}

@app.get("/api/me")
def me(request: Request):
    return current_user(request)


@app.get("/api/profile")
def profile(request: Request):
    user=current_user(request); cn=db()
    try:
        cur=cn.cursor(); cur.execute("SELECT FullName AS full_name,Phone AS phone,Email AS email,Address AS address FROM dbo.Customers WHERE UserId=?",user["id"])
        return one(cur) or {}
    finally: cn.close()

@app.post("/api/checkout")
def checkout(data: Checkout, request: Request):
    user = current_user(request)
    if len(data.items) > 30:
        raise HTTPException(400, "Giỏ hàng quá nhiều mặt hàng")
    normalized = []
    for item in data.items:
        try:
            pid, qty = int(item.get("product_id")), int(item.get("quantity"))
        except Exception:
            raise HTTPException(400, "Giỏ hàng không hợp lệ")
        if pid < 1 or qty < 1 or qty > 20:
            raise HTTPException(400, "Số lượng mỗi sản phẩm phải từ 1 đến 20")
        normalized.append({"product_id": pid, "quantity": qty})
    cn = db()
    try:
        cur = cn.cursor()
        cur.execute("EXEC dbo.usp_CreateOrder @UserId=?,@FullName=?,@Phone=?,@Email=?,@Address=?,@Items=?",
                    user["id"], data.full_name.strip(), data.phone.strip(), data.email,
                    data.address, json.dumps(normalized, ensure_ascii=False))
        result = cur.fetchone()
        if not result:
            cn.rollback()
            raise HTTPException(502, "SQL Server không trả về mã đơn hàng")
        cn.commit()
        return {"ok": True, "order_id": int(result.OrderId), "total": float(result.TotalAmount)}
    except HTTPException:
        cn.rollback(); raise
    except pyodbc.IntegrityError:
        cn.rollback(); raise HTTPException(409, "Số điện thoại đã được tài khoản khác sử dụng")
    except pyodbc.Error:
        cn.rollback(); raise HTTPException(409, "Không thể tạo đơn hàng. Vui lòng kiểm tra tồn kho và thông tin giao hàng.")
    finally:
        cn.close()

@app.get("/api/brands")
def brands(category: str = ""):
    cn = db()
    try:
        cur = cn.cursor()
        if category:
            cur.execute("""SELECT DISTINCT b.BrandId,b.BrandName FROM dbo.Brands b
                           JOIN dbo.Products p ON p.BrandId=b.BrandId
                           JOIN dbo.Categories c ON c.CategoryId=p.CategoryId
                           WHERE p.IsActive=1 AND c.CategoryName=? ORDER BY b.BrandName""", category)
        else:
            cur.execute("SELECT BrandId,BrandName FROM dbo.Brands ORDER BY BrandName")
        return rows(cur)
    finally:
        cn.close()

@app.get("/api/my-orders")
def my_orders(request: Request):
    user=current_user(request); cn=db()
    try:
        cur=cn.cursor(); cur.execute("""SELECT o.OrderId,o.OrderDate,o.Status,o.TotalAmount,oi.Quantity,
            p.ProductName,oi.UnitPrice,oi.Quantity * oi.UnitPrice AS LineTotal
            FROM dbo.Orders o
            JOIN dbo.OrderItems oi ON oi.OrderId=o.OrderId
            JOIN dbo.Products p ON p.ProductId=oi.ProductId
            WHERE o.CreatedBy=?
            ORDER BY o.OrderDate DESC""",user["id"]); return rows(cur)
    finally: cn.close()


@app.get("/api/admin/dashboard")
def dashboard(request: Request):
    current_user(request,admin=True); cn=db()
    try:
        cur=cn.cursor(); cur.execute("SELECT * FROM dbo.vw_AdminDashboard"); stats=one(cur)
        cur.execute("SELECT TOP 12 SaleYear,SaleMonth,OrderCount,Revenue FROM dbo.vw_MonthlyRevenue ORDER BY SaleYear DESC,SaleMonth DESC"); monthly=rows(cur)[::-1]
        cur.execute("SELECT TOP 8 ProductName,StockQuantity FROM dbo.vw_ProductInventory WHERE StockQuantity<=5 ORDER BY StockQuantity,ProductName"); low=rows(cur)
        cur.execute("SELECT TOP 200 OrderId,OrderDate,CustomerName,Username,ProductName,Quantity,UnitPrice,LineTotal,Status FROM dbo.vw_OrderDetails ORDER BY OrderDate DESC,OrderId DESC"); recent=rows(cur)
        return {"stats":stats,"monthly":monthly,"low_stock":low,"recent_orders":recent}
    finally: cn.close()

@app.get("/api/admin/products")
def admin_products(request: Request):
    current_user(request,admin=True); cn=db()
    try:
        cur=cn.cursor(); cur.execute("""SELECT p.ProductId,p.SKU,p.ProductName,p.BrandId,b.BrandName,p.CategoryId,c.CategoryName,p.RAMGB,p.StorageGB,p.SalePrice,p.CostPrice,p.StockQuantity,p.IsActive,p.ImagePath,p.IsDemoData,p.WarrantyMonths,p.Description,p.DataSource FROM dbo.Products p JOIN dbo.Brands b ON b.BrandId=p.BrandId JOIN dbo.Categories c ON c.CategoryId=p.CategoryId ORDER BY p.ProductId DESC"""); return rows(cur)
    finally: cn.close()

@app.get("/api/admin/lookups")
def admin_lookups(request: Request):
    current_user(request,admin=True); cn=db()
    try:
        cur=cn.cursor(); cur.execute("SELECT BrandId,BrandName FROM dbo.Brands ORDER BY BrandName"); brands=rows(cur)
        cur.execute("SELECT CategoryId,CategoryName FROM dbo.Categories ORDER BY CategoryName"); categories=rows(cur)
        return {"brands":brands,"categories":categories}
    finally: cn.close()

@app.post("/api/admin/products")
def add_product(data: ProductInput, request: Request):
    current_user(request,admin=True); cn=db()
    try:
        cur=cn.cursor(); cur.execute("""INSERT dbo.Products(SKU,ProductName,BrandId,CategoryId,RAMGB,StorageGB,SalePrice,CostPrice,StockQuantity,ImagePath,WarrantyMonths,Description,IsDemoData,IsActive) OUTPUT INSERTED.ProductId VALUES(?,?,?,?,?,?,?,?,?,?,?,?,0,1)""",data.sku,data.product_name,data.brand_id,data.category_id,data.ram_gb,data.storage_gb,data.sale_price,data.cost_price,data.stock_quantity,data.image_path,data.warranty_months,data.description)
        pid=cur.fetchone()[0]; cn.commit(); return {"ok":True,"product_id":pid}
    except pyodbc.IntegrityError as e:
        cn.rollback(); raise HTTPException(409,f"SKU trùng hoặc dữ liệu danh mục không hợp lệ: {e}")
    finally: cn.close()

@app.patch("/api/admin/products/{product_id}")
def update_product(product_id: int, data: ProductInput, request: Request):
    current_user(request,admin=True); cn=db()
    try:
        cur=cn.cursor(); cur.execute("""UPDATE dbo.Products SET SKU=?,ProductName=?,BrandId=?,CategoryId=?,RAMGB=?,StorageGB=?,SalePrice=?,CostPrice=?,StockQuantity=?,ImagePath=?,WarrantyMonths=?,Description=?,DataSource=N'Quản trị',IsDemoData=0 WHERE ProductId=?""",
        data.sku,data.product_name,data.brand_id,data.category_id,data.ram_gb,data.storage_gb,data.sale_price,data.cost_price,data.stock_quantity,data.image_path,data.warranty_months,data.description,product_id)
        if cur.rowcount==0: raise HTTPException(404,"Không tìm thấy sản phẩm")
        cn.commit(); return {"ok":True}
    except Exception:
        cn.rollback(); raise
    finally: cn.close()

@app.patch("/api/admin/products/{product_id}/active")
def set_active(product_id: int, body: dict, request: Request):
    current_user(request,admin=True); cn=db()
    try:
        cur=cn.cursor(); cur.execute("UPDATE dbo.Products SET IsActive=? WHERE ProductId=?",1 if body.get("active") else 0,product_id)
        if cur.rowcount==0: raise HTTPException(404,"Không tìm thấy sản phẩm")
        cn.commit(); return {"ok":True}
    except Exception:
        cn.rollback(); raise
    finally: cn.close()

@app.delete("/api/admin/products/{product_id}")
def delete_product(product_id: int, request: Request):
    current_user(request, admin=True)
    cn = db()
    try:
        cur = cn.cursor()
        cur.execute("""SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.OrderItems WHERE ProductId=?)
                                   OR EXISTS(SELECT 1 FROM dbo.StockReceiptItems WHERE ProductId=?)
                          THEN 1 ELSE 0 END""", product_id, product_id)
        has_history = bool(cur.fetchone()[0])
        if has_history:
            cur.execute("UPDATE dbo.Products SET IsActive=0 WHERE ProductId=?", product_id)
            if cur.rowcount == 0:
                cn.rollback(); raise HTTPException(404, "Không tìm thấy sản phẩm")
            cn.commit()
            return {"ok": True, "archived": True}
        cur.execute("DELETE dbo.Products WHERE ProductId=?", product_id)
        if cur.rowcount == 0:
            cn.rollback(); raise HTTPException(404, "Không tìm thấy sản phẩm")
        cn.commit()
        return {"ok": True, "archived": False}
    except HTTPException:
        cn.rollback(); raise
    except pyodbc.IntegrityError:
        cn.rollback(); raise HTTPException(409, "Không thể xóa vì dữ liệu khác đang tham chiếu sản phẩm")
    finally:
        cn.close()

@app.get("/", response_class=HTMLResponse)
def store():
    with open("store.html",encoding="utf-8") as f: return f.read()

@app.get("/admin", response_class=HTMLResponse)
def admin_page():
    with open("admin.html",encoding="utf-8") as f: return f.read()






