"""Charge les CSV officiels AdventureWorks (sans en-tête) en DataFrames nommés,
en lisant les noms de colonnes et les délimiteurs dans instawdb.sql."""
import os, re
import pandas as pd

AW = os.environ.get('AW_DIR', './aw')
SQL = open(f'{AW}/instawdb.sql', encoding='utf-8-sig', errors='replace').read()

def _columns(table):
    m = re.search(r'CREATE TABLE \[\w+\]\.\[' + table + r'\]\s*\((.*?)\n\)\s*ON', SQL, re.S)
    if not m:
        raise KeyError(table)
    cols = []
    for line in m.group(1).splitlines():
        c = re.match(r'\s*\[(\w+)\]', line)
        if c:
            cols.append(c.group(1))
    return cols

def _options(table):
    m = re.search(r"BULK INSERT \[\w+\]\.\[" + table + r"\] FROM '[^']*'\s*WITH \((.*?)\);", SQL, re.S)
    o = m.group(1)
    ft = re.search(r"FIELDTERMINATOR\s*=\s*'([^']*)'", o).group(1)
    rt = re.search(r"ROWTERMINATOR\s*=\s*'([^']*)'", o).group(1)
    return ft.replace('\\t', '\t'), rt

def load(table):
    cols = _columns(table)
    ft, rt = _options(table)
    raw = open(f'{AW}/{table}.csv', encoding='utf-8-sig', errors='replace').read()
    if rt.startswith('&|'):
        rows = [r for r in raw.split('&|\n') if r.strip()]
        data = [r.split(ft) for r in rows]
    else:
        data = [r.split(ft) for r in raw.split('\n') if r != '']
    df = pd.DataFrame(data, columns=cols[:len(data[0])])
    return df.replace({'': None})
