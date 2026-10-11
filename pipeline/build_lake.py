"""
Construit le lac de données : chaque table source est écrite en Parquet, sans
transformation métier (valeurs conservées en texte, comme à l'export).

Sources :
  - AdventureWorks (export OLTP officiel de Microsoft), téléchargé si absent ;
  - données complémentaires générées (data/raw).

Sortie : lake/<source>/<domaine>__<table>.parquet et lake/manifest.csv.
"""
import hashlib, io, os, re, sys, zipfile, urllib.request
from datetime import datetime, timezone
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AW_DIR = os.environ.get('AW_DIR', os.path.join(ROOT, 'aw'))
RAW_DIR = os.path.join(ROOT, 'data', 'raw')
LAKE = os.path.join(ROOT, 'lake')
AW_URL = 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip'

# Tables AdventureWorks retenues, par domaine. Les colonnes techniques (rowguid),
# XML, géospatiales et les données personnelles inutiles au reporting sont écartées.
AW_TABLES = {
    'sales': ['SalesOrderHeader', 'SalesOrderDetail', 'Customer', 'SalesTerritory', 'SalesPerson',
              'SalesPersonQuotaHistory', 'Store', 'SpecialOffer', 'ShipMethod'],
    'production': ['Product', 'ProductSubcategory', 'ProductCategory', 'ProductModel', 'WorkOrder',
                   'WorkOrderRouting', 'ScrapReason', 'Location', 'ProductCostHistory',
                   'ProductListPriceHistory', 'ProductInventory'],
    'purchasing': ['PurchaseOrderHeader', 'PurchaseOrderDetail', 'Vendor', 'ProductVendor'],
    'hr': ['Employee', 'Department', 'EmployeeDepartmentHistory', 'EmployeePayHistory', 'Shift'],
    'person': ['Person', 'Address', 'BusinessEntityAddress', 'StateProvince', 'CountryRegion'],
}
DROP = {'rowguid', 'Demographics', 'AdditionalContactInfo', 'CatalogDescription', 'Instructions',
        'SpatialLocation', 'AddressLine1', 'AddressLine2', 'NationalIDNumber', 'LoginID',
        'CreditCardID', 'CreditCardApprovalCode'}


def snake(name):
    return re.sub(r'(?<=[a-z0-9])(?=[A-Z])', '_', name).lower()


def ensure_adventureworks():
    if os.path.exists(os.path.join(AW_DIR, 'instawdb.sql')):
        return
    print('Téléchargement de l\'export AdventureWorks...')
    os.makedirs(AW_DIR, exist_ok=True)
    with urllib.request.urlopen(AW_URL) as r:
        zipfile.ZipFile(io.BytesIO(r.read())).extractall(AW_DIR)


def write_parquet(df, path, source_label):
    df = df.astype('string')
    df['_source'] = source_label
    pq.write_table(pa.Table.from_pandas(df, preserve_index=False), path, compression='zstd')
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()[:16]


def main():
    ensure_adventureworks()
    os.environ['AW_DIR'] = AW_DIR
    sys.path.insert(0, os.path.join(ROOT, 'generator'))
    import aw_loader as aw

    rows = []
    os.makedirs(os.path.join(LAKE, 'adventureworks'), exist_ok=True)
    for domain, tables in AW_TABLES.items():
        for t in tables:
            df = aw.load(t)
            df = df[[c for c in df.columns if c not in DROP]]
            name = f'{domain}__{snake(t)}'
            path = os.path.join(LAKE, 'adventureworks', name + '.parquet')
            h = write_parquet(df, path, f'adventureworks/{t}.csv')
            rows.append(('adventureworks', name, f'aw_{name}', len(df), len(df.columns), h))
            print(f'  adventureworks/{name}: {len(df):,} lignes')

    os.makedirs(os.path.join(LAKE, 'complements'), exist_ok=True)
    for domain in sorted(os.listdir(RAW_DIR)):
        for f in sorted(os.listdir(os.path.join(RAW_DIR, domain))):
            if not f.endswith('.csv'):
                continue
            df = pd.read_csv(os.path.join(RAW_DIR, domain, f), dtype=str, keep_default_na=False).replace({'': None})
            name = f'{domain}__{f[:-4]}'
            path = os.path.join(LAKE, 'complements', name + '.parquet')
            h = write_parquet(df, path, f'data/raw/{domain}/{f}')
            rows.append(('complements', name, f'cx_{name}', len(df), len(df.columns), h))
            print(f'  complements/{name}: {len(df):,} lignes')

    m = pd.DataFrame(rows, columns=['source', 'name', 'bronze_table', 'row_count', 'column_count', 'sha256_16'])
    m.to_csv(os.path.join(LAKE, 'manifest.csv'), index=False)
    print(f'{len(m)} tables écrites dans lake/ le {datetime.now(timezone.utc):%Y-%m-%d %H:%M} UTC')


if __name__ == '__main__':
    main()
