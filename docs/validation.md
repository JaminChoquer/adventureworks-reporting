# Rapport de validation des données complémentaires

Généré automatiquement par `validate.py` à partir des fichiers produits. Tous les chiffres ci-dessous sont recalculés sur les données, rien n'est saisi à la main.

## 1. Intégrité référentielle avec AdventureWorks

| Contrôle | Orphelins | Valeurs non nulles |
|---|---|---|
| incidents.injured_business_entity_id → Employee | 0 | 268 |
| incidents.reported_by_business_entity_id → Employee | 0 | 1274 |
| incidents.location_id → Location | 0 | 1281 |
| training_records.business_entity_id → Employee | 0 | 2915 |
| timesheet_monthly.business_entity_id → Employee | 0 | 10440 |
| audits.location_id → Location | 0 | 386 |
| audits.auditor_business_entity_id → Employee | 0 | 358 |
| nonconformities.work_order_id → WorkOrder | 0 | 193 |
| nonconformities.purchase_order_id → PurchaseOrderHeader | 0 | 442 |
| nonconformities.purchase_order_detail_id → PurchaseOrderDetail | 0 | 442 |
| nonconformities.vendor_id → Vendor | 0 | 442 |
| nonconformities.sales_order_id → SalesOrderHeader | 0 | 133 |
| nonconformities.product_id → Product | 0 | 768 |
| nonconformities.scrap_reason_id → ScrapReason | 0 | 193 |
| customer_returns.sales_order_id → SalesOrderHeader | 0 | 925 |
| customer_returns.sales_order_detail_id → SalesOrderDetail | 0 | 925 |
| customer_returns.product_id → Product | 0 | 925 |
| monthly_readings.location_id → Location | 0 | 1548 |

## 2. Cohérence interne

| Contrôle | Anomalies |
|---|---|
| Identifiants uniques (incidents, formations, audits, NC, retours) | 0 |
| Signalement antérieur à l'événement | 0 |
| Clôture antérieure au signalement | 0 |
| Accident avec arrêt sans jours perdus | 0 |
| Blessure sans nature renseignée | 0 |
| NC.audit_id absent des audits | 0 |
| NC.rma_id absent des retours | 0 |
| Heures travaillées négatives | 0 |
| Absences supérieures aux heures planifiées | 0 |
| Heures d'absence accident (feuilles de temps) contre jours perdus des accidents avec arrêt de salariés | 2968 h contre 3272 h attendues |

## 3. Sécurité par période

| | Heures travaillées | Accidents avec arrêt | Jours perdus | Recordables (OSHA) | Presqu'accidents |
|---|---|---|---|---|---|
| 1. Avant programme (juin 2022 à août 2023) | 590 707 | 12 | 253 | 39 | 131 |
| 2. Programme (sept. 2023 à mai 2024) | 389 754 | 6 | 125 | 19 | 207 |
| 3. Montée en charge (juin 2024 à mai 2025) | 585 890 | 11 | 269 | 36 | 318 |

| | TF | TG | TRIR |
|---|---|---|---|
| 1. Avant programme (juin 2022 à août 2023) | 20.31 | 0.43 | 13.20 |
| 2. Programme (sept. 2023 à mai 2024) | 15.39 | 0.32 | 9.75 |
| 3. Montée en charge (juin 2024 à mai 2025) | 18.77 | 0.46 | 12.29 |

TF = accidents avec arrêt × 1 000 000 / heures. TG = jours perdus × 1 000 / heures. TRIR = (accidents avec arrêt + soins médicaux) × 200 000 / heures. Heures = salariés + intérimaires.

### Pyramide des événements

| | First aid | Hazardous situation | Lost time injury | Medical treatment | Near miss |
|---|---|---|---|---|---|
| 1. Avant programme (juin 2022 à août 2023) | 87 | 71 | 12 | 27 | 131 |
| 2. Programme (sept. 2023 à mai 2024) | 36 | 112 | 6 | 13 | 207 |
| 3. Montée en charge (juin 2024 à mai 2025) | 82 | 167 | 11 | 25 | 318 |


Part des accidents avec arrêt touchant des intérimaires : 10%, pour 6% des heures travaillées.

## 4. RH

| Période | Absentéisme hors congés | Heures supplémentaires | Part d'intérim |
|---|---|---|---|
| 1. Avant programme (juin 2022 à août 2023) | 2.8% | 1.0% | 0.2% |
| 2. Programme (sept. 2023 à mai 2024) | 3.4% | 2.6% | 2.7% |
| 3. Montée en charge (juin 2024 à mai 2025) | 3.3% | 6.6% | 12.8% |

### Conformité des habilitations sécurité (fin de trimestre)

| Trimestre | Conformité |
|---|---|
| 2022-06 | 78.2% |
| 2022-09 | 76.7% |
| 2022-12 | 77.6% |
| 2023-03 | 78.8% |
| 2023-06 | 80.5% |
| 2023-09 | 86.3% |
| 2023-12 | 99.0% |
| 2024-03 | 97.6% |
| 2024-06 | 97.0% |
| 2024-09 | 94.8% |
| 2024-12 | 95.6% |
| 2025-03 | 96.2% |

Blessés (salariés des ateliers à habilitation clé) dont une habilitation clé était échue le jour de l'accident : 28%, contre 17% des heures travaillées par des salariés dans la même situation.

## 5. Qualité

### Score moyen des audits 5S

| Période | Score |
|---|---|
| 1. Avant programme (juin 2022 à août 2023) | 75.4 |
| 2. Programme (sept. 2023 à mai 2024) | 79.1 |
| 3. Montée en charge (juin 2024 à mai 2025) | 78.4 |

### Non-conformités par source et gravité

| | Critical | Major | Minor |
|---|---|---|---|
| Customer | 0 | 8 | 125 |
| External audit | 0 | 16 | 24 |
| Internal audit | 0 | 106 | 172 |
| Production | 11 | 44 | 138 |
| Supplier | 0 | 126 | 316 |


### Retours clients par motif

| Motif | Retours |
|---|---|
| Wrong size | 164 |
| Changed mind | 157 |
| Damaged in transit | 131 |
| Defective item | 101 |
| Paint defect | 76 |
| Defective stitching | 61 |
| Wheel misalignment | 59 |
| Defective part | 48 |
| Missing parts | 34 |
| Drivetrain noise | 34 |
| Weld crack on frame | 33 |
| Wrong part shipped | 27 |

### Retours pour défaut de peinture par trimestre

| Trimestre | Retours |
|---|---|
| 2022Q4 | 4 |
| 2023Q1 | 2 |
| 2023Q2 | 3 |
| 2023Q3 | 4 |
| 2023Q4 | 4 |
| 2024Q1 | 5 |
| 2024Q2 | 5 |
| 2024Q3 | 10 |
| 2024Q4 | 18 |
| 2025Q1 | 14 |
| 2025Q2 | 7 |

## 6. Environnement

| Mois | COV ligne Paint (kg) | Électricité totale (kWh) |
|---|---|---|
| 2022-06 | 788 | 251 308 |
| 2022-09 | 861 | 260 950 |
| 2022-12 | 1 089 | 273 599 |
| 2023-03 | 978 | 267 390 |
| 2023-06 | 1 285 | 312 728 |
| 2023-09 | 1 372 | 332 982 |
| 2023-12 | 1 468 | 346 976 |
| 2024-03 | 1 438 | 338 672 |
| 2024-06 | 2 109 | 433 886 |
| 2024-09 | 2 680 | 498 749 |
| 2024-12 | 1 690 | 525 177 |
| 2025-03 | 1 540 | 503 616 |

## 7. Volumétrie

| Fichier | Lignes |
|---|---|
| `ehs/incidents.csv` | 1 305 |
| `ehs/training_catalog.csv` | 10 |
| `ehs/training_records.csv` | 2 915 |
| `hr/timesheet_monthly.csv` | 10 440 |
| `hr/temp_labor_monthly.csv` | 407 |
| `quality/audits.csv` | 386 |
| `quality/nonconformities.csv` | 1 086 |
| `quality/customer_returns.csv` | 925 |
| `environment/monthly_readings.csv` | 1 728 |
| `reference/scenario_events.csv` | 5 |
