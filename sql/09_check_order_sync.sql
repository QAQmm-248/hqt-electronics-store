/* Kiểm tra đồng bộ sau khi đặt hàng trên web. Không sửa dữ liệu. */
USE PhoneStore;
GO

-- 1) Đơn mới nhất của user_demo
SELECT TOP (10)
    o.OrderId, o.OrderDate, o.Status, o.TotalAmount,
    u.Username, c.FullName, c.Phone
FROM dbo.Orders o
JOIN dbo.Users u ON u.UserId = o.CreatedBy
LEFT JOIN dbo.Customers c ON c.CustomerId = o.CustomerId
WHERE u.Username = N'user_demo'
ORDER BY o.OrderDate DESC, o.OrderId DESC;
GO

-- 2) Chi tiết sản phẩm của các đơn user_demo
SELECT TOP (50)
    o.OrderId, o.OrderDate, p.SKU, p.ProductName,
    oi.Quantity, oi.UnitPrice, oi.LineTotal, o.Status
FROM dbo.Orders o
JOIN dbo.Users u ON u.UserId = o.CreatedBy
JOIN dbo.OrderItems oi ON oi.OrderId = o.OrderId
JOIN dbo.Products p ON p.ProductId = oi.ProductId
WHERE u.Username = N'user_demo'
ORDER BY o.OrderDate DESC, o.OrderId DESC;
GO

-- 3) Kiểm tra tồn kho hiện tại và lịch sử nhập/bán của sản phẩm trong đơn gần nhất
;WITH LastOrder AS (
    SELECT TOP (1) o.OrderId
    FROM dbo.Orders o JOIN dbo.Users u ON u.UserId = o.CreatedBy
    WHERE u.Username = N'user_demo'
    ORDER BY o.OrderDate DESC, o.OrderId DESC
)
SELECT oi.OrderId, p.SKU, p.ProductName,
       oi.Quantity AS SoldQuantity, p.StockQuantity AS CurrentStock,
       p.SalePrice, oi.UnitPrice, oi.LineTotal
FROM LastOrder lo
JOIN dbo.OrderItems oi ON oi.OrderId = lo.OrderId
JOIN dbo.Products p ON p.ProductId = oi.ProductId;
GO

SELECT * FROM dbo.vw_OrderDetails
ORDER BY OrderDate DESC;
