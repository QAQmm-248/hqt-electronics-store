import csv
import sys
from pathlib import Path
sys.path.insert(0, '/workspace')
from main import db
with Path('/workspace/data/products_master.csv').open(encoding='utf-8-sig',newline='') as f:
    rows=list(csv.DictReader(f))
cn=db(); cur=cn.cursor()
for row in rows:
    cur.execute('UPDATE dbo.Products SET ImagePath=? WHERE SKU=?', '/product-images/'+row['image_file'], row['sku'])
cn.commit(); cn.close(); print('sql_image_paths_updated',len(rows))

