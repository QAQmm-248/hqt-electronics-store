USE PhoneStore;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @LegacySku TABLE(SKU VARCHAR(30) PRIMARY KEY);
INSERT @LegacySku(SKU) VALUES
('APL15-128'),('APL15P-256'),('APL16-128'),('SAM-S24-256'),('SAM-A55-128'),('SAM-S24U-512'),('XIA-14-256'),('XIA-RN12-256'),('OP-R12-256'),('OP-A79-256'),('LEN-IDEA5'),('LEN-LOQ15'),('ASU-VIVO15'),('ASU-TUF15'),('APL-MBA13'),('SAM-BOOK4'),('ASU-VG249'),('SAM-ODYSSEY'),('XIA-MON27'),('LEN-L24E'),('APL-IPAD10'),('SAM-TABS9'),('XIA-PAD6'),('OP-PADNEO'),('ACC-ANKER20'),('ACC-CABLEC'),('ACC-AIRPODS'),('ACC-BUDS2'),('ACC-MOUSE'),('ACC-BAG'),('DT-0278'),('DT-0279'),('DT-0280'),('DT-0281'),('DT-0282'),('DT-0283'),('DT-0284'),('DT-0285'),('DT-0286'),('DT-0287'),('DT-0288'),('DT-0289'),('DT-0290'),('DT-0291'),('DT-0292'),('DT-0293'),('DT-0294'),('DT-0295'),('DT-0296'),('DT-0297'),('DT-0298'),('DT-0299');
/* Giu lich su neu phat sinh tham chieu; neu khong, chi xoa cac SKU mau cu da biet va chua duoc tham chieu. */
UPDATE p SET IsActive=0 FROM dbo.Products p JOIN @LegacySku l ON l.SKU=p.SKU
WHERE EXISTS(SELECT 1 FROM dbo.OrderItems i WHERE i.ProductId=p.ProductId)
   OR EXISTS(SELECT 1 FROM dbo.StockReceiptItems s WHERE s.ProductId=p.ProductId);
DELETE p FROM dbo.Products p JOIN @LegacySku l ON l.SKU=p.SKU
WHERE NOT EXISTS(SELECT 1 FROM dbo.OrderItems i WHERE i.ProductId=p.ProductId)
  AND NOT EXISTS(SELECT 1 FROM dbo.StockReceiptItems s WHERE s.ProductId=p.ProductId);
/* Phuc vu anh truc tiep tu data/anh_san_pham de tranh tao them ban sao anh. */
UPDATE dbo.Products SET ImagePath=REPLACE(ImagePath,N'/static/products/scraped/',N'/product-images/')
WHERE ImagePath LIKE N'/static/products/scraped/%';
COMMIT;
GO

