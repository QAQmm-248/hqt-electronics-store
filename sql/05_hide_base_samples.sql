/* An 40 san pham mau cua script nen khoi catalog web, giu lai ban ghi de doi chieu bai tap. */
USE PhoneStore;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE p SET IsActive=0
    FROM dbo.Products p
    WHERE p.SKU IN ('SKU-001', 'SKU-002', 'SKU-003', 'SKU-004', 'SKU-005', 'SKU-006', 'SKU-007', 'SKU-008', 'SKU-009', 'SKU-010', 'SKU-011', 'SKU-012', 'SKU-013', 'SKU-014', 'SKU-015', 'SKU-016', 'SKU-017', 'SKU-018', 'SKU-019', 'SKU-020', 'SKU-021', 'SKU-022', 'SKU-023', 'SKU-024', 'SKU-025', 'SKU-026', 'SKU-027', 'SKU-028', 'SKU-029', 'SKU-030', 'SKU-031', 'SKU-032', 'SKU-033', 'SKU-034', 'SKU-035', 'SKU-036', 'SKU-037', 'SKU-038', 'SKU-039', 'SKU-040')
      AND p.ProductName LIKE N'Sản phẩm mẫu %'
      AND p.IsActive=1
      AND NOT EXISTS (SELECT 1 FROM dbo.OrderItems i WHERE i.ProductId=p.ProductId);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
