/* Product catalog filters for PhoneStore / Module 1-2 */
USE PhoneStore;
GO

CREATE OR ALTER PROCEDURE dbo.usp_FilterProducts
    @CategoryName NVARCHAR(100) = NULL,
    @BrandName NVARCHAR(100) = NULL,
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, SKU, ProductName, BrandName, CategoryName,
           RAMGB, StorageGB, SalePrice, StockQuantity, ImagePath,
           WarrantyMonths, Description, DataSource
    FROM dbo.vw_ProductInventory
    WHERE IsActive = 1
      AND (NULLIF(@CategoryName,N'') IS NULL OR CategoryName=@CategoryName)
      AND (NULLIF(@BrandName,N'') IS NULL OR BrandName=@BrandName)
      AND (NULLIF(@Search,N'') IS NULL OR ProductName LIKE N'%'+@Search+N'%'
           OR SKU LIKE N'%'+@Search+N'%' OR BrandName LIKE N'%'+@Search+N'%')
    ORDER BY CategoryName, BrandName, ProductName;
END;
GO

-- Catalog summary by category and brand for Module 2 reports.
SELECT CategoryName, BrandName, COUNT(*) AS ProductCount,
       SUM(StockQuantity) AS UnitsInStock,
       MIN(SalePrice) AS MinPrice, MAX(SalePrice) AS MaxPrice
FROM dbo.vw_ProductInventory
WHERE IsActive=1
GROUP BY CategoryName, BrandName
ORDER BY CategoryName, BrandName;
GO
