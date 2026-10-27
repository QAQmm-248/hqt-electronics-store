"""Tao bo du lieu nop bai: san pham dien tu, khong xuat URL nguon.
Nguon crawl: snapshot FPT Shop da co, CellphoneS va Dien May Xanh.
"""
from __future__ import annotations
import csv, hashlib, re, shutil, sys, time
from pathlib import Path
from urllib.parse import urljoin
import requests
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
INPUT = ROOT / "data" / "san_pham_dien_tu_300.csv"
OUT = ROOT / "data" / "du_lieu_nop_thiet_bi_dien_tu.csv"
IMG = ROOT / "data" / "anh_san_pham"
BAD = ROOT / "data" / "anh_loi.csv"
HEAD = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/130 Safari/537.36"}
S = requests.Session(); S.headers.update(HEAD)

def get(url):
    for attempt in range(3):
        try:
            r = S.get(url, timeout=30); r.raise_for_status(); return r
        except Exception:
            if attempt == 2: raise
            time.sleep(attempt + 1)

def money(text):
    vals = [int(x.replace('.', '')) for x in re.findall(r'(?<!\d)(\d{1,3}(?:\.\d{3})+)\s*đ', text, re.I)]
    return vals[0] if vals else 0

def brand(name):
    for b in ('Apple','Samsung','Xiaomi','Redmi','POCO','HONOR','OPPO','TECNO','Nubia','Lenovo','Acer','ASUS','HP','Dell','MSI','LG','ViewSonic','Logitech','JBL','Baseus','Belkin','Ugreen','Huawei','TCL','Sony'):
        if re.search(r'\b' + re.escape(b) + r'\b', name, re.I):
            return 'Xiaomi' if b.lower() in ('redmi','poco') else ('ASUS' if b.lower() == 'asus' else b)
    return 'Khác'

def specs(name):
    nums = re.findall(r'\b(\d{1,2})\s*GB\b', name, re.I)
    ram = int(nums[0]) if nums else ''
    storage = int(nums[-1]) if len(nums) > 1 else ''
    return ram, storage

def image_name(site, name, url):
    return f"{site}-{hashlib.sha256((name+url).encode()).hexdigest()[:16].upper()}.jpg"

def download(row):
    dest = IMG / row['image_file']
    try:
        if not dest.exists() or dest.stat().st_size < 1500:
            dest.write_bytes(get(row['_image_url']).content)
        if dest.stat().st_size < 1500: raise ValueError('anh qua nho')
        row['image_status'] = 'ok'; return True
    except Exception as e:
        row['image_status'] = 'failed'; row['_error'] = str(e)[:160]; return False

def parse_cellphones(limit=20):
    soup = BeautifulSoup(get('https://cellphones.com.vn/mobile.html').text, 'html.parser')
    rows=[]; seen=set()
    for a in soup.select('div.product-info a.product__link'):
        href=a.get('href',''); img=a.select_one('img'); name=' '.join(a.get_text(' ',strip=True).split())
        if not href or not img or not name or href in seen: continue
        seen.add(href); price=money(a.get_text(' ',strip=True))
        if price < 30000: continue
        ram,storage=specs(name); image=img.get('src') or img.get('data-src')
        rows.append({'source_site':'CellphoneS','name':name,'brand':brand(name),'category':'Điện thoại','ram_gb':ram,'storage_gb':storage,'sale_price':price,'cost_price':round(price*.85/1000)*1000,'stock_quantity':10,'image_file':image_name('CPS',name,image),'_image_url':image})
        if len(rows)>=limit: break
    return rows

def parse_dmx(limit=20):
    soup = BeautifulSoup(get('https://www.dienmayxanh.com/dien-thoai').text, 'html.parser')
    rows=[]; seen=set()
    for a in soup.select('a[href*="/dien-thoai/"]'):
        href=urljoin('https://www.dienmayxanh.com',a.get('href','')).split('?')[0]
        img=a.select_one('img'); name=' '.join(a.get_text(' ',strip=True).split())
        if not img or not name or href in seen or len(name)<4: continue
        seen.add(href); price=money(name)
        if price < 30000: continue
        ram,storage=specs(name); image=img.get('src') or img.get('data-src')
        rows.append({'source_site':'DienMayXanh','name':name,'brand':brand(name),'category':'Điện thoại','ram_gb':ram,'storage_gb':storage,'sale_price':price,'cost_price':round(price*.85/1000)*1000,'stock_quantity':10,'image_file':image_name('DMX',name,image),'_image_url':image})
        if len(rows)>=limit: break
    if rows:
        return rows[:limit]
    # Trang danh muc DMX tai mot so thoi diem render bang JavaScript; dung
    # metadata JSON-LD cua cac trang san pham de van co du lieu tu nguon nay.
    slugs=['iphone-17-pro-max','samsung-galaxy-s25-ultra','iphone-16','samsung-galaxy-a56','oppo-reno13']
    for slug in slugs:
        try:
            url='https://www.dienmayxanh.com/dien-thoai/'+slug
            soup=BeautifulSoup(get(url).text,'html.parser')
            title=soup.select_one('meta[property="og:title"]'); image=soup.select_one('meta[property="og:image"]')
            text=str(soup); pm=re.search(r'"price":(\d+)',text)
            name=' '.join((title.get('content','') if title else '').split())
            image_url=image.get('content') if image else ''
            if not name or not image_url or not pm: continue
            price=int(pm.group(1)); ram,storage=specs(name)
            rows.append({'source_site':'DienMayXanh','name':name,'brand':brand(name),'category':'Điện thoại','ram_gb':ram,'storage_gb':storage,'sale_price':price,'cost_price':round(price*.85/1000)*1000,'stock_quantity':10,'image_file':image_name('DMX',name,image_url),'_image_url':image_url})
            if len(rows)>=limit: break
        except Exception: continue
    return rows

def main():
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    IMG.mkdir(parents=True, exist_ok=True)
    rows=[]
    with INPUT.open(encoding='utf-8-sig', newline='') as f:
        for x in csv.DictReader(f):
            src=ROOT/'static'/x['image_path'].replace('/static/','').replace('/', '\\')
            dest=IMG/f"FPT-{x['sku'].replace('FPT-','')}.jpg"
            if src.exists() and not dest.exists(): shutil.copyfile(src,dest)
            rows.append({'source_site':'FPTShop','name':x['name'],'brand':x['brand'],'category':x['category'],'ram_gb':x['ram_gb'],'storage_gb':x['storage_gb'],'sale_price':x['sale_price'],'cost_price':x['cost_price'],'stock_quantity':x['stock_quantity'],'image_file':dest.name,'image_status':'ok' if dest.exists() else 'failed'})
    for fn in (parse_cellphones, parse_dmx):
        try: rows.extend(fn())
        except Exception as e: print('SOURCE_FAIL',fn.__name__,str(e)[:160])
    failed=[]
    for row in rows:
        if '_image_url' in row and not download(row): failed.append({'name':row['name'],'source_site':row['source_site'],'error':row.get('_error','')})
    fields=['product_code','name','brand','category','ram_gb','storage_gb','sale_price','cost_price','stock_quantity','image_file','image_status','source_site','warranty_months','description','is_demo_data']
    output=[]
    for i,row in enumerate(rows,1):
        output.append({'product_code':f'DT-{i:04d}',**{k:row.get(k,'') for k in fields if k!='product_code'},'warranty_months':12,'description':f"{row['name']} - sản phẩm thuộc nhóm {row['category']}",'is_demo_data':1})
    with OUT.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(output)
    with BAD.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['name','source_site','error']); w.writeheader(); w.writerows(failed)
    print('ROWS',len(output),'IMAGES_OK',sum(x['image_status']=='ok' for x in output),'IMAGE_FAILURES',len(failed),'OUTPUT',OUT)

if __name__ == '__main__': main()
