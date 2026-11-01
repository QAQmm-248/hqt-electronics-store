USE PhoneStore;
GO
-- 1. Danh muc san pham dang ban
SELECT SKU,ProductName,BrandName,CategoryName,SalePrice,StockQuantity FROM dbo.vw_ProductInventory WHERE IsActive=1 ORDER BY CategoryName,ProductName;
GO
-- 2. San pham sap het hang
SELECT SKU,ProductName,BrandName,StockQuantity FROM dbo.vw_ProductInventory WHERE IsActive=1 AND StockQuantity BETWEEN 0 AND 5 ORDER BY StockQuantity,ProductName;
GO
-- 3. Doanh thu theo thang
SELECT SaleYear,SaleMonth,OrderCount,Revenue FROM dbo.vw_MonthlyRevenue ORDER BY SaleYear DESC,SaleMonth DESC;
GO
-- 4. San pham co doanh thu don hoan tat cao nhat
SELECT TOP 10 p.ProductName,SUM(oi.Quantity) UnitsSold,SUM(oi.LineTotal) Revenue FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.OrderId=oi.OrderId JOIN dbo.Products p ON p.ProductId=oi.ProductId WHERE o.Status='completed' GROUP BY p.ProductName ORDER BY Revenue DESC;
GO
-- 5. Don hang cua tai khoan duoc chon
SELECT * FROM dbo.vw_OrderDetails WHERE Username='user_demo' ORDER BY OrderDate DESC;
GO
-- 6. Loi nhuan gop theo san pham
SELECT p.SKU,p.ProductName,SUM(oi.LineTotal) Revenue,SUM(oi.Quantity*oi.UnitCost) Cost,SUM(oi.LineTotal-oi.Quantity*oi.UnitCost) GrossProfit FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.OrderId=oi.OrderId JOIN dbo.Products p ON p.ProductId=oi.ProductId WHERE o.Status='completed' GROUP BY p.SKU,p.ProductName ORDER BY GrossProfit DESC;
GO
-- 7. Gia von ton kho theo thuong hieu
SELECT b.BrandName,SUM(p.StockQuantity) Units,SUM(p.StockQuantity*p.CostPrice) InventoryCost FROM dbo.Products p JOIN dbo.Brands b ON b.BrandId=p.BrandId WHERE p.IsActive=1 GROUP BY b.BrandName HAVING SUM(p.StockQuantity)>0 ORDER BY InventoryCost DESC;
GO
-- 8. Tong chi tieu don hoan tat theo khach hang
SELECT c.CustomerId,c.FullName,COUNT(DISTINCT o.OrderId) Orders,SUM(o.TotalAmount) Spend FROM dbo.Customers c JOIN dbo.Orders o ON o.CustomerId=c.CustomerId WHERE o.Status='completed' GROUP BY c.CustomerId,c.FullName ORDER BY Spend DESC;
GO
-- 9. Lich su nhap kho
SELECT r.ReceiptId,r.ReceivedAt,s.SupplierName,SUM(i.Quantity) UnitsReceived,SUM(i.Quantity*i.UnitCost) ReceiptCost FROM dbo.StockReceipts r JOIN dbo.Suppliers s ON s.SupplierId=r.SupplierId JOIN dbo.StockReceiptItems i ON i.ReceiptId=r.ReceiptId GROUP BY r.ReceiptId,r.ReceivedAt,s.SupplierName ORDER BY r.ReceivedAt DESC;
GO
-- 10. Vai tro tai khoan, khong hien ma bam mat khau
SELECT UserId,Username,RoleName,IsActive,CreatedAt FROM dbo.Users WHERE UserId IN (SELECT UserId FROM dbo.Customers WHERE UserId IS NOT NULL) UNION SELECT UserId,Username,RoleName,IsActive,CreatedAt FROM dbo.Users WHERE RoleName='admin' ORDER BY RoleName,Username;
GO
-- 11. Tim san pham theo ten bang LIKE (vi du iPhone)
SELECT SKU,ProductName,BrandName,CategoryName,SalePrice
FROM dbo.vw_ProductInventory
WHERE IsActive=1 AND ProductName LIKE N'%iPhone%'
ORDER BY SalePrice,ProductName;
GO
