"""
Crée une base DuckDB locale (local.duckdb) qui reproduit la couche bronze à partir
du lac de données. Elle permet de développer et tester les modèles dbt sur son
poste, sans compte cloud : `dbt build --target local`.
"""
import os
import duckdb
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAKE = os.path.join(ROOT, 'lake')
DB = os.environ.get('LOCAL_DUCKDB', os.path.join(ROOT, 'local.duckdb'))


def main():
    manifest = pd.read_csv(os.path.join(LAKE, 'manifest.csv'))
    con = duckdb.connect(DB)
    con.execute('create schema if not exists bronze')
    for r in manifest.itertuples():
        path = os.path.join(LAKE, r.source, r.name + '.parquet')
        con.execute(f"create or replace table bronze.{r.bronze_table} as select * from read_parquet('{path}')")
        n = con.execute(f'select count(*) from bronze.{r.bronze_table}').fetchone()[0]
        assert n == r.row_count, (r.bronze_table, n, r.row_count)
    con.close()
    print(f'{len(manifest)} tables bronze créées dans {DB}')


if __name__ == '__main__':
    main()
