# Dictionnaire des données complémentaires

Jeu de données complémentaire à AdventureWorks (Microsoft, licence MIT), couvrant la santé-sécurité, la qualité, l'environnement et le temps de travail. Toutes les valeurs sont fictives, mais rattachées aux référentiels réels d'AdventureWorks par leurs identifiants.

**Conventions**
- Fenêtre couverte : juin 2022 à mai 2025, soit les 36 mois complets de production présents dans AdventureWorks.
- Fichiers CSV en UTF-8 avec en-tête, séparateur virgule. Dates au format ISO (`AAAA-MM-JJ`, horodatages `AAAA-MM-JJTHH:MM:SS`), mois au format `AAAA-MM`.
- Les noms de colonnes et les valeurs sont en anglais, comme les systèmes sources d'une entreprise américaine. Les libellés français seront posés dans la couche gold.
- Montants en dollars américains (USD). Unités physiques métriques (kWh, m³, kg).
- Codes d'atelier (`work_center`) : `WC10` à `WC60` correspondent aux ateliers de production d'AdventureWorks (`Production.Location`, identifiants 10 à 60). Les autres codes sont `LOG` (logistique), `MNT` (maintenance), `QA` (qualité), `OFF` (fonctions support).

**Clés vers AdventureWorks**

| Colonne | Table AdventureWorks |
|---|---|
| `*_business_entity_id` | `HumanResources.Employee.BusinessEntityID` |
| `location_id` | `Production.Location.LocationID` |
| `shift_id` | `HumanResources.Shift.ShiftID` (1 jour, 2 soir, 3 nuit) |
| `department_id` | `HumanResources.Department.DepartmentID` |
| `work_order_id` | `Production.WorkOrder.WorkOrderID` |
| `scrap_reason_id` | `Production.ScrapReason.ScrapReasonID` |
| `product_id` | `Production.Product.ProductID` |
| `sales_order_id`, `sales_order_detail_id` | `Sales.SalesOrderHeader` / `Sales.SalesOrderDetail` |
| `purchase_order_id`, `purchase_order_detail_id` | `Purchasing.PurchaseOrderHeader` / `Purchasing.PurchaseOrderDetail` |
| `vendor_id` | `Purchasing.Vendor.BusinessEntityID` |

---

## ehs/incidents.csv

Registre des événements santé-sécurité, exporté de l'application EHS. **Grain : un événement.**

| Colonne | Type | Description |
|---|---|---|
| `incident_id` | texte | Identifiant `EHS-AAAA-NNNN`, numéroté par année. |
| `event_type` | texte | `Lost time injury` (accident avec arrêt), `Medical treatment` (soins médicaux sans arrêt), `First aid` (premiers soins), `Near miss` (presqu'accident), `Hazardous situation` (situation dangereuse). |
| `occurred_at` | horodatage | Date et heure de l'événement, toujours sur un jour ouvré et dans les horaires de l'équipe. |
| `reported_at` | horodatage | Date et heure de la déclaration dans l'application. |
| `location_id` | entier | Zone où l'événement s'est produit. Vide pour les fonctions support. |
| `work_center` | texte | Atelier ou service de rattachement. |
| `shift_id` | entier | Équipe concernée. |
| `worker_type` | texte | `Employee` ou `Temporary` (intérimaire, sans identifiant salarié). |
| `injured_business_entity_id` | entier | Salarié blessé. Vide pour les presqu'accidents, les situations dangereuses et les intérimaires. |
| `reported_by_business_entity_id` | entier | Salarié déclarant. Vide quand un intérimaire blessé fait lui-même la déclaration. |
| `injury_nature` | texte | Nature de la lésion (blessures uniquement). |
| `body_part` | texte | Siège de la lésion (blessures uniquement). |
| `activity` | texte | Activité en cours au moment de l'événement. |
| `root_cause_category` | texte | Cause racine selon les 5M : `Human factor`, `Equipment`, `Method`, `Work environment`, `Organization`. |
| `severity_potential` | texte | Gravité potentielle : `Low`, `Medium`, `High`, `Critical`. |
| `days_lost` | entier | Jours calendaires d'arrêt (accidents avec arrêt uniquement). |
| `days_restricted` | entier | Jours de poste aménagé. |
| `description` | texte | Description courte. |
| `status` | texte | `Closed`, `Open` ou `Under investigation`. |
| `closed_at` | horodatage | Clôture de l'analyse. Vide si non clôturé au 31 mai 2025. |

## ehs/training_catalog.csv

Catalogue des formations sécurité. **Grain : une formation.**

| Colonne | Type | Description |
|---|---|---|
| `course_code` | texte | Code de la formation. |
| `course_title` | texte | Intitulé. |
| `category` | texte | Famille de risque. |
| `duration_hours` | entier | Durée d'une session. |
| `validity_months` | entier | Durée de validité avant recyclage. |
| `required_for` | texte | Populations concernées : `ALL`, `VOLUNTEERS` (secouristes) ou liste de codes d'atelier séparés par `;`. |

## ehs/training_records.csv

Historique des sessions suivies. Contient aussi les sessions antérieures à juin 2022, nécessaires pour connaître la validité des habilitations en début de période. **Grain : une session suivie par un salarié.**

| Colonne | Type | Description |
|---|---|---|
| `training_record_id` | texte | Identifiant `TR-NNNNNN`. |
| `business_entity_id` | entier | Salarié formé. |
| `course_code` | texte | Formation suivie. |
| `completed_on` | date | Date de la session. |
| `duration_hours` | entier | Heures de formation. |
| `score` | entier | Note sur 100. |
| `result` | texte | `Pass` (note d'au moins 70) ou `Fail`. |
| `provider` | texte | Organisme formateur. |
| `valid_until` | date | Fin de validité. Vide en cas d'échec. |

## hr/timesheet_monthly.csv

Synthèse mensuelle du temps de travail, exportée de la gestion des temps. **Grain : un salarié et un mois** (290 salariés × 36 mois).

| Colonne | Type | Description |
|---|---|---|
| `month` | texte | Mois. |
| `business_entity_id` | entier | Salarié. |
| `department_id` | entier | Service actuel. |
| `shift_id` | entier | Équipe actuelle. |
| `work_center` | texte | Atelier ou service. |
| `scheduled_hours` | décimal | Heures planifiées : jours ouvrés × 8 h. |
| `overtime_hours` | décimal | Heures supplémentaires. |
| `absence_sickness_hours` | décimal | Absence maladie. |
| `absence_work_accident_hours` | décimal | Absence pour accident du travail, cohérente avec `ehs/incidents.days_lost`. |
| `absence_vacation_hours` | décimal | Congés. |
| `absence_other_hours` | décimal | Autres absences. |
| `worked_hours` | décimal | Heures travaillées = planifiées + supplémentaires − absences. |

## hr/temp_labor_monthly.csv

Recours à l'intérim, d'après les relevés des agences. **Grain : un mois, un atelier, une équipe, une agence.**

| Colonne | Type | Description |
|---|---|---|
| `month` | texte | Mois. |
| `work_center` | texte | Atelier. |
| `shift_id` | entier | Équipe. |
| `agency` | texte | Agence d'intérim (noms fictifs). |
| `temp_fte` | décimal | Équivalents temps plein. |
| `temp_hours` | décimal | Heures facturées. |
| `cost_usd` | décimal | Coût facturé. |

## quality/audits.csv

Audits qualité, environnement et 5S. **Grain : un audit d'une zone.**

| Colonne | Type | Description |
|---|---|---|
| `audit_id` | texte | Identifiant `AUD-NNNNN`. |
| `audit_date` | date | Date de l'audit. |
| `audit_type` | texte | `5S`, `ISO 9001 internal`, `ISO 9001 external`, `ISO 14001 internal`, `ISO 14001 external`. |
| `location_id` | entier | Zone auditée. |
| `work_center` | texte | Atelier audité. |
| `auditor_business_entity_id` | entier | Auditeur interne (service Qualité). Vide pour les audits externes. |
| `auditor_organization` | texte | `Internal QA` ou `External certification body`. |
| `score` | décimal | Score sur 100. |
| `findings_major` | entier | Écarts majeurs. |
| `findings_minor` | entier | Écarts mineurs. |
| `observations` | entier | Observations et pistes de progrès. |

## quality/nonconformities.csv

Registre des non-conformités. Les colonnes de rattachement renseignées dépendent de la source. **Grain : une non-conformité.**

| Colonne | Type | Description |
|---|---|---|
| `nc_id` | texte | Identifiant `NC-NNNNN`. |
| `detected_on` | date | Date de détection. |
| `source` | texte | `Production`, `Supplier`, `Internal audit`, `External audit`, `Customer`. |
| `severity` | texte | `Minor`, `Major`, `Critical`. |
| `description` | texte | Libellé générique de la source. |
| `work_center` | texte | Atelier concerné, si connu. |
| `location_id` | entier | Zone concernée, si connue. |
| `work_order_id` | entier | Ordre de fabrication (source `Production`). |
| `purchase_order_id` | entier | Commande fournisseur (source `Supplier`). |
| `purchase_order_detail_id` | entier | Ligne de commande fournisseur (source `Supplier`). |
| `vendor_id` | entier | Fournisseur (source `Supplier`). |
| `audit_id` | texte | Audit d'origine (sources d'audit). |
| `rma_id` | texte | Retour client d'origine (source `Customer`). |
| `sales_order_id` | entier | Commande client (source `Customer`). |
| `product_id` | entier | Produit concerné. |
| `scrap_reason_id` | entier | Motif de rebut (source `Production`). |
| `qty_affected` | entier | Quantité concernée. |
| `estimated_cost_usd` | décimal | Coût estimé de non-qualité. |
| `root_cause_category` | texte | Cause racine (5M, avec `Material` pour la qualité). |
| `status` | texte | `Closed` ou `Open`. |
| `closed_on` | date | Date de clôture. |

## quality/customer_returns.csv

Retours clients (RMA). **Grain : un retour sur une ligne de commande client.**

| Colonne | Type | Description |
|---|---|---|
| `rma_id` | texte | Identifiant `RMA-NNNNNN`. |
| `return_date` | date | Date de réception du retour. |
| `sales_order_id` | entier | Commande client. |
| `sales_order_detail_id` | entier | Ligne de commande. |
| `product_id` | entier | Produit retourné. |
| `qty_returned` | entier | Quantité retournée. |
| `return_reason` | texte | Motif du retour. |
| `defect_origin_work_center` | texte | Atelier à l'origine du défaut, pour les produits fabriqués et les défauts logistiques. |
| `disposition` | texte | `Repair`, `Replace`, `Credit`, `Scrap`, `Restock`, `Exchange`. |
| `refund_amount_usd` | décimal | Montant remboursé (nul en cas de réparation ou d'échange). |
| `handling_cost_usd` | décimal | Coût de traitement du retour. |

## environment/monthly_readings.csv

Relevés environnementaux mensuels, au format long. **Grain : un mois, une zone, un indicateur.** `location_id` vide = bâtiment et services généraux.

| Colonne | Type | Description |
|---|---|---|
| `month` | texte | Mois. |
| `location_id` | entier | Zone, vide pour le site. |
| `indicator` | texte | `electricity_kwh`, `natural_gas_kwh`, `water_m3`, `voc_kg` (composés organiques volatils), `waste_metal_kg`, `waste_hazardous_kg`, `waste_general_kg`, `waste_packaging_kg`, et pour chaque flux de déchets sa part recyclée (`*_recycled_kg`). |
| `value` | décimal | Valeur relevée. |
| `unit` | texte | Unité. |
| `source` | texte | Origine de la mesure (sous-compteur, registre peinture, bordereau du prestataire déchets). |

## reference/scenario_events.csv

Journal des événements de contexte (fictifs) qui expliquent les tendances, à utiliser pour annoter les visuels. **Grain : un événement.**

| Colonne | Type | Description |
|---|---|---|
| `event_date` | date | Date de l'événement. |
| `scope` | texte | Périmètre concerné. |
| `event` | texte | Intitulé. |
| `description` | texte | Description. |
