from __future__ import annotations
import csv, hashlib, re, sys, time
from pathlib import Path
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup

ROOT=Path(__file__).resolve().parent
BASE='https://fptshop.com.vn'
SOURCES={
 'Điện thoại': ['/dien-thoai','/dien-thoai/dien-thoai-5g','/dien-thoai/ai','/dien-thoai/dien-thoai-gap','/dien-thoai/dien-thoai-gaming','/dien-thoai/pho-thong'],
 'Laptop': ['/may-tinh-xach-tay','/may-tinh-xach-tay/ai','/may-tinh-xach-tay/gaming-do-hoa','/may-tinh-xach-tay/sinh-vien-van-phong','/may-tinh-xach-tay/mong-nhe','/may-tinh-xach-tay/doanh-nhan'],
 'Máy tính bảng': ['/may-tinh-bang'],
 'Màn hình': ['/man-hinh','/man-hinh/van-phong','/man-hinh/gaming','/man-hinh/do-hoa','/man-hinh/di-dong'],
 'Phụ kiện': ['/phu-kien','/phu-kien/loa','/phu-kien/tai-nghe','/phu-kien/sac-cap','/phu-kien/bao-da-op-lung','/phu-kien/chuot','/phu-kien/ban-phim','/phu-kien/sac-du-phong','/phu-kien/gaming-gear','/phu-kien/ban-ghe','/phu-kien/but-cam-ung','/phu-kien/balo-tui-xach','/phu-kien/the-nho','/phu-kien/usb','/phu-kien/o-cung-di-dong','/phu-kien/mieng-lot-chuot','/phu-kien/gimbal','/phu-kien/gia-do','/phu-kien/thiet-bi-dinh-vi','/phu-kien/kinh-thong-minh','/phu-kien/webcam','/phu-kien/micro','/phu-kien/phu-kien-tv','/phu-kien/phu-kien-khac']}
HEAD={'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/130 Safari/537.36'}
S=requests.Session(); S.headers.update(HEAD)
def request(url):
 for i in range(3):
  try:
   r=S.get(url,timeout=30); r.raise_for_status(); return r
  except Exception:
   if i==2: raise
   time.sleep(1+i)
def parse_listing(path,category):
 soup=BeautifulSoup(request(BASE+path).text,'html.parser'); rows=[]
 for a in soup.select('a[aria-label][href]'):
  href=urljoin(BASE,a.get('href','')).split('?')[0]
  if not href.startswith(BASE+'/') or urlparse(href).path.count('/')<2: continue
  img=a.find('img'); image=(img.get('src') or img.get('srcset','').split(' ')[0]) if img else ''
  title=' '.join((a.get('aria-label') or a.get('title') or '').split())
  if not image.startswith('http') or not title or '/promotion/' in image: continue
  card=a.parent.parent
  text=' '.join(card.get_text(' ',strip=True).split())
  prices=[int(v.replace('.','')) for v in re.findall(r'(?<!\d)(\d{1,3}(?:\.\d{3})+)\s*đ',text,re.I)]
  # Current sale is the second price when list and discounted prices are shown.
  price=prices[1] if len(prices)>1 else prices[0] if prices else 0
  if price<30000: continue
  imsrc=image.split(' ')[0]
  m=re.search(r'\b(\d{1,2})\s*GB\b.*?\b(\d{2,4})\s*GB\b',title,re.I)
  ram,storage=(int(m.group(1)),int(m.group(2))) if m else (None,None)
  if storage is None:
   ms=re.search(r'\b(\d{2,4})\s*GB\b',title,re.I)
   if ms: storage=int(ms.group(1))
  brand='Khác'
  for b in ['Apple','Samsung','Xiaomi','Redmi','POCO','HONOR','Honor','OPPO','TECNO','Nubia','Lenovo','Acer','ASUS','Asus','HP','Dell','MSI','LG','ViewSonic','Logitech','JBL','Baseus','Belkin','Ugreen','Xiaomi','Huawei','TCL','Sony']:
   if re.search(r'\b'+re.escape(b)+r'\b',title,re.I): brand='Xiaomi' if b.lower() in ('redmi','poco') else ('ASUS' if b.lower()=='asus' else b); break
  rows.append({'name':title,'brand':brand,'category':category,'ram_gb':ram,'storage_gb':storage,'sale_price':price,'source_url':href,'image_url':imsrc})
 return rows
def q(s): return "N'"+str(s).replace("'","''")+"'"
def main():
 sys.stdout.reconfigure(encoding='utf-8',errors='replace')
 allrows=[]; seen=set()
 for category,paths in SOURCES.items():
  n0=len(allrows)
  for path in paths:
   try:
    for x in parse_listing(path,category):
     if x['source_url'] in seen: continue
     seen.add(x['source_url']);allrows.append(x)
   except Exception as e: print('SKIP',path,str(e)[:150])
  print(category, len(allrows)-n0, 'unique')
 allrows=allrows[:300]
 print('UNIQUE_PRODUCTS',len(allrows))
 IMAGE_ROOT=ROOT/'static'/'products'/'catalog'; IMAGE_ROOT.mkdir(parents=True,exist_ok=True)
 downloaded=[]
 for i,x in enumerate(allrows,1):
  sku='FPT-'+hashlib.sha256(x['source_url'].encode()).hexdigest()[:16].upper()
  ext=Path(urlparse(x['image_url']).path).suffix.lower(); ext=ext if ext in ('.png','.jpg','.jpeg','.webp') else '.jpg'
  dest=IMAGE_ROOT/(sku+ext)
  try:
   if not dest.exists() or dest.stat().st_size<1500:
    rr=request(x['image_url']);dest.write_bytes(rr.content)
   if dest.stat().st_size<1500: raise ValueError('image too small')
  except Exception as e:
   print('IMG_FAIL',sku,str(e)[:100]);continue
  x.update({'sku':sku,'image_path':'/static/products/catalog/'+dest.name,'cost_price':round(x['sale_price']*.85/1000)*1000,'stock_quantity':10,'is_demo_data':1})
  downloaded.append(x)
  if i%25==0: print('IMAGES',i,'/',len(allrows))
 fields=['sku','name','brand','category','ram_gb','storage_gb','sale_price','cost_price','stock_quantity','image_path','source_url','image_url','is_demo_data']
 with (ROOT/'data'/'san_pham_dien_tu_300.csv').open('w',encoding='utf-8-sig',newline='') as f:
  w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows([{k:x.get(k) for k in fields} for x in downloaded])
 lines=['SET ANSI_NULLS ON;','SET QUOTED_IDENTIFIER ON;','GO',"IF COL_LENGTH('dbo.Products','ImagePath') IS NULL ALTER TABLE dbo.Products ADD ImagePath NVARCHAR(500) NULL;","IF COL_LENGTH('dbo.Products','SourceURL') IS NULL ALTER TABLE dbo.Products ADD SourceURL NVARCHAR(500) NULL;","IF COL_LENGTH('dbo.Products','PriceCheckedAt') IS NULL ALTER TABLE dbo.Products ADD PriceCheckedAt DATETIME2 NULL;","IF COL_LENGTH('dbo.Products','IsDemoData') IS NULL ALTER TABLE dbo.Products ADD IsDemoData BIT NOT NULL CONSTRAINT DF_Products_IsDemoData DEFAULT 0;",'GO']
 brands=sorted({x['brand'] for x in downloaded});cats=sorted({x['category'] for x in downloaded})
 for b in brands: lines.append(f'IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE BrandName={q(b)}) INSERT dbo.Brands(BrandName) VALUES({q(b)});')
 for c in cats: lines.append(f'IF NOT EXISTS(SELECT 1 FROM dbo.Categories WHERE CategoryName={q(c)}) INSERT dbo.Categories(CategoryName) VALUES({q(c)});')
 lines.append('GO')
 for x in downloaded:
  lines.append(f"IF NOT EXISTS(SELECT 1 FROM dbo.Products WHERE SKU='{x['sku']}' OR SourceURL={q(x['source_url'])}) INSERT dbo.Products(SKU,ProductName,BrandId,CategoryId,RAMGB,StorageGB,SalePrice,CostPrice,StockQuantity,IsActive,ImagePath,SourceURL,PriceCheckedAt,IsDemoData) VALUES('{x['sku']}',{q(x['name'])},(SELECT BrandId FROM dbo.Brands WHERE BrandName={q(x['brand'])}),(SELECT CategoryId FROM dbo.Categories WHERE CategoryName={q(x['category'])}),{x['ram_gb'] or 'NULL'},{x['storage_gb'] or 'NULL'},{x['sale_price']},{x['cost_price']},10,1,{q(x['image_path'])},{q(x['source_url'])},SYSUTCDATETIME(),1);")
 lines += ['GO','CREATE OR ALTER VIEW dbo.vw_ProductInventory AS','SELECT p.ProductId,p.SKU,p.ProductName,b.BrandName,c.CategoryName,p.RAMGB,p.StorageGB,p.SalePrice,p.StockQuantity,p.ImagePath,p.SourceURL,p.PriceCheckedAt,p.IsDemoData','FROM dbo.Products p JOIN dbo.Brands b ON b.BrandId=p.BrandId JOIN dbo.Categories c ON c.CategoryId=p.CategoryId','WHERE p.IsActive=1;','GO']
(ROOT/'sql'/'nhap_san_pham_fptshop.sql').write_text('\n'.join(lines)+'\n',encoding='utf-8-sig')
print('CSV_ROWS',len(downloaded),'IMAGE_FILES',len(downloaded),'SQL_ROWS',len(downloaded))
if __name__=='__main__':main()
