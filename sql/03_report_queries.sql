USE PhoneStore;
GO
-- 1. Active catalog
SELECT SKU,ProductName,BrandName,CategoryName,SalePrice,StockQuantity FROM dbo.vw_ProductInventory WHERE IsActive=1 ORDER BY CategoryName,ProductName;
GO
-- 2. Low-stock items
SELECT SKU,ProductName,BrandName,StockQuantity FROM dbo.vw_ProductInventory WHERE IsActive=1 AND StockQuantity<=5 ORDER BY StockQuantity,ProductName;
GO
-- 3. Monthly revenue
SELECT SaleYear,SaleMonth,OrderCount,Revenue FROM dbo.vw_MonthlyRevenue ORDER BY SaleYear DESC,SaleMonth DESC;
GO
-- 4. Top products by completed revenue
SELECT TOP 10 p.ProductName,SUM(oi.Quantity) UnitsSold,SUM(oi.LineTotal) Revenue FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.OrderId=oi.OrderId JOIN dbo.Products p ON p.ProductId=oi.ProductId WHERE o.Status='completed' GROUP BY p.ProductName ORDER BY Revenue DESC;
GO
-- 5. Orders for a selected account
SELECT * FROM dbo.vw_OrderDetails WHERE Username='user_demo' ORDER BY OrderDate DESC;
GO
-- 6. Gross profit by product
SELECT p.SKU,p.ProductName,SUM(oi.LineTotal) Revenue,SUM(oi.Quantity*oi.UnitCost) Cost,SUM(oi.LineTotal-oi.Quantity*oi.UnitCost) GrossProfit FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.OrderId=oi.OrderId JOIN dbo.Products p ON p.ProductId=oi.ProductId WHERE o.Status='completed' GROUP BY p.SKU,p.ProductName ORDER BY GrossProfit DESC;
GO
-- 7. Inventory cost by brand
SELECT b.BrandName,SUM(p.StockQuantity) Units,SUM(p.StockQuantity*p.CostPrice) InventoryCost FROM dbo.Products p JOIN dbo.Brands b ON b.BrandId=p.BrandId WHERE p.IsActive=1 GROUP BY b.BrandName ORDER BY InventoryCost DESC;
GO
-- 8. Completed spend by customer
SELECT c.CustomerId,c.FullName,COUNT(DISTINCT o.OrderId) Orders,SUM(o.TotalAmount) Spend FROM dbo.Customers c JOIN dbo.Orders o ON o.CustomerId=c.CustomerId WHERE o.Status='completed' GROUP BY c.CustomerId,c.FullName ORDER BY Spend DESC;
GO
-- 9. Stock receipt history
SELECT r.ReceiptId,r.ReceivedAt,s.SupplierName,SUM(i.Quantity) UnitsReceived,SUM(i.Quantity*i.UnitCost) ReceiptCost FROM dbo.StockReceipts r JOIN dbo.Suppliers s ON s.SupplierId=r.SupplierId JOIN dbo.StockReceiptItems i ON i.ReceiptId=r.ReceiptId GROUP BY r.ReceiptId,r.ReceivedAt,s.SupplierName ORDER BY r.ReceivedAt DESC;
GO
-- 10. Account roles without credential hashes
SELECT UserId,Username,RoleName,IsActive,CreatedAt FROM dbo.Users ORDER BY RoleName,Username;
GO
