"""Contrôles d'intégrité et indicateurs de référence des données complémentaires, exportés en markdown."""
import os
import numpy as np
import pandas as pd
import aw_loader as aw

RAW = os.environ.get('OUT_DIR', './data/raw')
DOC = os.environ.get('DOC_DIR', './docs')
r = lambda p, **k: pd.read_csv(f'{RAW}/{p}.csv', **k)
I = r('ehs/incidents', parse_dates=['occurred_at', 'reported_at', 'closed_at'])
TR = r('ehs/training_records', parse_dates=['completed_on', 'valid_until'])
TS = r('hr/timesheet_monthly'); T = r('hr/temp_labor_monthly')
A = r('quality/audits', parse_dates=['audit_date'])
N = r('quality/nonconformities', parse_dates=['detected_on', 'closed_on'])
R = r('quality/customer_returns', parse_dates=['return_date'])
EN = r('environment/monthly_readings')

ids = lambda t, c: set(aw.load(t)[c].astype(int))
EMP, LOC = ids('Employee', 'BusinessEntityID'), ids('Location', 'LocationID')
WO, SO = ids('WorkOrder', 'WorkOrderID'), ids('SalesOrderHeader', 'SalesOrderID')
SOD = ids('SalesOrderDetail', 'SalesOrderDetailID')
PO, POD = ids('PurchaseOrderHeader', 'PurchaseOrderID'), ids('PurchaseOrderDetail', 'PurchaseOrderDetailID')
VEN, PROD, SCR = ids('Vendor', 'BusinessEntityID'), ids('Product', 'ProductID'), ids('ScrapReason', 'ScrapReasonID')

def fk(df, col, ref):
    v = df[col].dropna().astype(int)
    return int((~v.isin(ref)).sum()), len(v)

checks = [
    ('incidents.injured_business_entity_id → Employee', *fk(I, 'injured_business_entity_id', EMP)),
    ('incidents.reported_by_business_entity_id → Employee', *fk(I, 'reported_by_business_entity_id', EMP)),
    ('incidents.location_id → Location', *fk(I, 'location_id', LOC)),
    ('training_records.business_entity_id → Employee', *fk(TR, 'business_entity_id', EMP)),
    ('timesheet_monthly.business_entity_id → Employee', *fk(TS, 'business_entity_id', EMP)),
    ('audits.location_id → Location', *fk(A, 'location_id', LOC)),
    ('audits.auditor_business_entity_id → Employee', *fk(A, 'auditor_business_entity_id', EMP)),
    ('nonconformities.work_order_id → WorkOrder', *fk(N, 'work_order_id', WO)),
    ('nonconformities.purchase_order_id → PurchaseOrderHeader', *fk(N, 'purchase_order_id', PO)),
    ('nonconformities.purchase_order_detail_id → PurchaseOrderDetail', *fk(N, 'purchase_order_detail_id', POD)),
    ('nonconformities.vendor_id → Vendor', *fk(N, 'vendor_id', VEN)),
    ('nonconformities.sales_order_id → SalesOrderHeader', *fk(N, 'sales_order_id', SO)),
    ('nonconformities.product_id → Product', *fk(N, 'product_id', PROD)),
    ('nonconformities.scrap_reason_id → ScrapReason', *fk(N, 'scrap_reason_id', SCR)),
    ('customer_returns.sales_order_id → SalesOrderHeader', *fk(R, 'sales_order_id', SO)),
    ('customer_returns.sales_order_detail_id → SalesOrderDetail', *fk(R, 'sales_order_detail_id', SOD)),
    ('customer_returns.product_id → Product', *fk(R, 'product_id', PROD)),
    ('monthly_readings.location_id → Location', *fk(EN, 'location_id', LOC)),
]
internal = [
    ('Identifiants uniques (incidents, formations, audits, NC, retours)',
     sum(int(df[c].duplicated().sum()) for df, c in [(I, 'incident_id'), (TR, 'training_record_id'), (A, 'audit_id'), (N, 'nc_id'), (R, 'rma_id')])),
    ('Signalement antérieur à l\'événement', int((I.reported_at < I.occurred_at).sum())),
    ('Clôture antérieure au signalement', int((I.closed_at < I.reported_at).sum())),
    ('Accident avec arrêt sans jours perdus', int(((I.event_type == 'Lost time injury') & (I.days_lost <= 0)).sum())),
    ('Blessure sans nature renseignée', int((I.event_type.isin(['Lost time injury', 'Medical treatment', 'First aid']) & I.injury_nature.isna()).sum())),
    ('NC.audit_id absent des audits', int((~N.audit_id.dropna().isin(A.audit_id)).sum())),
    ('NC.rma_id absent des retours', int((~N.rma_id.dropna().isin(R.rma_id)).sum())),
    ('Heures travaillées négatives', int((TS.worked_hours < 0).sum())),
    ('Absences supérieures aux heures planifiées', int((TS[[c for c in TS if c.startswith('absence_')]].sum(axis=1) > TS.scheduled_hours).sum())),
]
lti_emp = I[(I.event_type == 'Lost time injury') & (I.worker_type == 'Employee')]
exp_hours = int((lti_emp.days_lost * 5 / 7).round().clip(lower=1).sum() * 8)

per = lambda m: np.where(m < '2023-09', '1. Avant programme (juin 2022 à août 2023)',
                         np.where(m < '2024-06', '2. Programme (sept. 2023 à mai 2024)', '3. Montée en charge (juin 2024 à mai 2025)'))
I['period'] = per(I.occurred_at.dt.strftime('%Y-%m')); TS['period'] = per(TS.month); T['period'] = per(T.month)
hours = TS.groupby('period').worked_hours.sum().add(T.groupby('period').temp_hours.sum(), fill_value=0)
lti = I[I.event_type == 'Lost time injury']
rec = I[I.event_type.isin(['Lost time injury', 'Medical treatment'])]
k = pd.DataFrame({'Heures travaillées': hours, 'Accidents avec arrêt': lti.groupby('period').size(),
                  'Jours perdus': lti.groupby('period').days_lost.sum(), 'Recordables (OSHA)': rec.groupby('period').size(),
                  'Presqu\'accidents': I[I.event_type == 'Near miss'].groupby('period').size()}).fillna(0)
k['TF'] = k['Accidents avec arrêt'] * 1e6 / k['Heures travaillées']
k['TG'] = k['Jours perdus'] * 1e3 / k['Heures travaillées']
k['TRIR'] = k['Recordables (OSHA)'] * 2e5 / k['Heures travaillées']

pyr = I.groupby(['period', 'event_type']).size().unstack().fillna(0).astype(int)
pairs = TR[['business_entity_id', 'course_code']].drop_duplicates()
ok = TR[TR.result == 'Pass']
comp = {}
for q in pd.date_range('2022-06-30', '2025-05-31', freq='QE'):
    v = ok[(ok.completed_on <= q) & (ok.valid_until >= q)][['business_entity_id', 'course_code']].drop_duplicates()
    comp[q.strftime('%Y-%m')] = len(v) / len(pairs)

# Lien formation / accidentologie
KEY = {'WC10': ['MACH', 'LOTO'], 'WC20': ['WELD', 'LOTO'], 'WC30': ['MACH', 'LOTO'], 'WC40': ['CHEM'], 'WC45': ['CHEM'],
       'WC50': ['ERGO'], 'WC60': ['ERGO'], 'LOG': ['FORK', 'ERGO'], 'MNT': ['LOTO']}
spans = {k: list(zip(g.completed_on, g.valid_until)) for k, g in ok.groupby(['business_entity_id', 'course_code'])}
def expired(e, wc, d):
    return any(not any(a <= d <= b for a, b in spans.get((e, c), [])) for c in KEY.get(wc, []))
inj = I[I.event_type.isin(['Lost time injury', 'Medical treatment', 'First aid']) & I.injured_business_entity_id.notna() & I.work_center.isin(list(KEY))]
inj_share = np.mean([expired(int(r.injured_business_entity_id), r.work_center, r.occurred_at.normalize()) for r in inj.itertuples()])
base = TS[TS.work_center.isin(list(KEY))]
base_share = np.average([expired(r.business_entity_id, r.work_center, pd.Timestamp(r.month + '-15')) for r in base.itertuples()], weights=base.worked_hours.clip(lower=0) + 1e-9)
TS['abs'] = TS[['absence_sickness_hours', 'absence_work_accident_hours', 'absence_other_hours']].sum(axis=1)
absy = TS.groupby('period').apply(lambda d: d['abs'].sum() / d.scheduled_hours.sum())
oty = TS.groupby('period').apply(lambda d: d.overtime_hours.sum() / d.scheduled_hours.sum())
tmp = T.groupby('period').temp_hours.sum() / hours
fives = A[A.audit_type == '5S'].assign(p=lambda d: per(d.audit_date.dt.strftime('%Y-%m'))).groupby('p').score.mean()
ncs = N.groupby(['source', 'severity']).size().unstack().fillna(0).astype(int)
ret = R.return_reason.value_counts()
paint = R[R.return_reason == 'Paint defect'].groupby(R.return_date.dt.to_period('Q').astype(str)).size()
voc = EN[(EN.indicator == 'voc_kg') & (EN.location_id == 40)].set_index('month').value
elec = EN[EN.indicator == 'electricity_kwh'].groupby('month').value.sum()

def tbl(df, fmt='{:,.0f}'):
    cols = list(df.columns)
    out = '| | ' + ' | '.join(map(str, cols)) + ' |\n|---|' + '---|' * len(cols) + '\n'
    for i, row in df.iterrows():
        out += f'| {i} | ' + ' | '.join(fmt.format(v) if isinstance(v, (int, float, np.integer, np.floating)) else str(v) for v in row) + ' |\n'
    return out.replace(',', ' ')

md = ['# Rapport de validation des données complémentaires', '',
      'Généré automatiquement par `validate.py` à partir des fichiers produits. Tous les chiffres ci-dessous sont recalculés sur les données, rien n\'est saisi à la main.', '',
      '## 1. Intégrité référentielle avec AdventureWorks', '', '| Contrôle | Orphelins | Valeurs non nulles |', '|---|---|---|']
md += [f'| {n} | {o} | {t} |' for n, o, t in checks]
md += ['', '## 2. Cohérence interne', '', '| Contrôle | Anomalies |', '|---|---|']
md += [f'| {n} | {v} |' for n, v in internal]
md += [f'| Heures d\'absence accident (feuilles de temps) contre jours perdus des accidents avec arrêt de salariés | {int(TS.absence_work_accident_hours.sum())} h contre {exp_hours} h attendues |', '',
       '## 3. Sécurité par période', '', tbl(k[['Heures travaillées', 'Accidents avec arrêt', 'Jours perdus', 'Recordables (OSHA)', 'Presqu\'accidents']]),
       tbl(k[['TF', 'TG', 'TRIR']], '{:.2f}').replace(' ', ' '),
       'TF = accidents avec arrêt × 1 000 000 / heures. TG = jours perdus × 1 000 / heures. TRIR = (accidents avec arrêt + soins médicaux) × 200 000 / heures. Heures = salariés + intérimaires.', '',
       '### Pyramide des événements', '', tbl(pyr), '',
       f'Part des accidents avec arrêt touchant des intérimaires : {(lti.worker_type == "Temporary").mean():.0%}, pour {T.temp_hours.sum() / hours.sum():.0%} des heures travaillées.', '',
       '## 4. RH', '', '| Période | Absentéisme hors congés | Heures supplémentaires | Part d\'intérim |', '|---|---|---|---|']
md += [f'| {p} | {absy[p]:.1%} | {oty[p]:.1%} | {tmp.get(p, 0):.1%} |' for p in absy.index]
md += ['', '### Conformité des habilitations sécurité (fin de trimestre)', '', '| Trimestre | Conformité |', '|---|---|']
md += [f'| {q} | {v:.1%} |' for q, v in comp.items()]
md += ['', f'Blessés (salariés des ateliers à habilitation clé) dont une habilitation clé était échue le jour de l\'accident : {inj_share:.0%}, contre {base_share:.0%} des heures travaillées par des salariés dans la même situation.']
md += ['', '## 5. Qualité', '', '### Score moyen des audits 5S', '', '| Période | Score |', '|---|---|']
md += [f'| {p} | {v:.1f} |' for p, v in fives.items()]
md += ['', '### Non-conformités par source et gravité', '', tbl(ncs), '', '### Retours clients par motif', '', '| Motif | Retours |', '|---|---|']
md += [f'| {m} | {v} |' for m, v in ret.items()]
md += ['', '### Retours pour défaut de peinture par trimestre', '', '| Trimestre | Retours |', '|---|---|']
md += [f'| {q} | {v} |' for q, v in paint.items()]
md += ['', '## 6. Environnement', '', '| Mois | COV ligne Paint (kg) | Électricité totale (kWh) |', '|---|---|---|']
md += [f'| {m} | {voc[m]:,.0f} | {elec[m]:,.0f} |'.replace(',', ' ') for m in voc.index[::3]]
md += ['', '## 7. Volumétrie', '', '| Fichier | Lignes |', '|---|---|']
for f in ['ehs/incidents', 'ehs/training_catalog', 'ehs/training_records', 'hr/timesheet_monthly', 'hr/temp_labor_monthly',
          'quality/audits', 'quality/nonconformities', 'quality/customer_returns', 'environment/monthly_readings', 'reference/scenario_events']:
    md.append(f'| `{f}.csv` | {len(r(f)):,} |'.replace(',', ' '))
os.makedirs(DOC, exist_ok=True)
open(f'{DOC}/validation.md', 'w').write('\n'.join(md) + '\n')
print('\n'.join(md))
