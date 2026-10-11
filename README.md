# AdventureWorks, reporting mensuel

Projet de portfolio : une chaîne data complète, du lac de données au dashboard, pour produire le reporting mensuel d'une entreprise industrielle sur quatre thématiques : **QHSE, Performance, Finance et RH**.

L'entreprise est AdventureWorks Cycles, fabricant de vélos fictif de la base d'exemple **AdventureWorks** (Microsoft, licence MIT) : formage et soudure des cadres, ébavurage, peinture, sous-assemblage et assemblage final.

## Sources

| Source | Contenu | Thématiques |
|---|---|---|
| AdventureWorks (OLTP officiel) | Ventes, production, achats, produits, salariés | Performance, Finance, RH |
| Données complémentaires générées | Santé-sécurité, formations, qualité, environnement, temps de travail, intérim | QHSE, RH |

AdventureWorks ne couvre ni la santé-sécurité, ni l'environnement, ni le temps de travail. Ces données sont donc générées par `generator/`, de façon déterministe et rattachées aux référentiels réels d'AdventureWorks (salariés, équipes, ateliers, ordres de fabrication, commandes clients et fournisseurs).

## Contenu actuel

```
.github/workflows/
  pipeline.yml              orchestration GitHub Actions (mensuelle et à la demande)
pipeline/
  build_lake.py             construction du lac de données en Parquet
  load_bronze.py            chargement du lac dans la couche bronze de BigQuery
  load_local.py             copie locale de la couche bronze dans DuckDB (développement)
dbt/                        transformations SQL et tests
  models/silver/            une vue typée et renommée par table bronze
  models/gold/              modèle en étoile du reporting (dimensions, faits par thématique, kpi_monthly)
  models/mart/              agrégats mensuels par axe de filtre, lus par le dashboard
  seeds/                    référentiels : ateliers, zones, plan de l'usine, géographie, jours fériés, postes financiers, indicateurs
  tests/                    tests de qualité génériques et métier
lake/                       lac de données : une table source = un fichier Parquet
  manifest.csv              inventaire (lignes, colonnes, empreinte de chaque fichier)
data/raw/                   données complémentaires (CSV bruts)
  ehs/                      incidents, training_catalog, training_records
  hr/                       timesheet_monthly, temp_labor_monthly
  quality/                  audits, nonconformities, customer_returns
  environment/              monthly_readings
  reference/                scenario_events
docs/
  dictionnaire_donnees.md   description de chaque fichier et colonne
  regles_generation.md      règles et paramètres de génération
  validation.md             contrôles d'intégrité et indicateurs de référence
generator/
  aw_loader.py              lecture des CSV officiels AdventureWorks
  generate_complements.py          générateur des données complémentaires (déterministe)
  validate.py               contrôles et rapport de validation
```

Fenêtre : juin 2022 à mai 2025 (36 mois), alignée sur les données de production d'AdventureWorks.

## Régénérer les données complémentaires

1. Télécharger l'export officiel AdventureWorks (OLTP) et le décompresser dans `aw/` :
   https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip
2. Installer les dépendances : `pip install -r generator/requirements.txt`
3. Lancer depuis la racine du dépôt :
   ```
   python generator/generate_complements.py
   python generator/validate.py
   ```

Les chemins se règlent par variables d'environnement : `AW_DIR` (défaut `./aw`), `OUT_DIR` (défaut `./data/raw`), `DOC_DIR` (défaut `./docs`).

## Architecture

```
AdventureWorks (CSV) ─┐                                   BigQuery (EU)
                      ├─> lake/ (Parquet) ─> bronze ─> silver ─> gold ─> mart ─> dashboard
Données générées ─────┘                            (dbt : SQL et tests)
```

Contraintes assumées du sandbox BigQuery, utilisé pour rester gratuit : pas d'instructions de modification (`INSERT`, `UPDATE`, `MERGE`), donc des tables reconstruites entièrement à chaque exécution ; expiration automatique des tables au bout de 60 jours, compensée par l'exécution mensuelle du pipeline ; pas de Cloud Storage, d'où un lac versionné dans le dépôt.

## Choix de modélisation

- Chiffre d'affaires rattaché au mois d'expédition, coût des ventes au coût standard en vigueur à cette date.
- Finance présentée en indicateurs de gestion juxtaposés (`fct_finance_monthly`), sans résultat global : AdventureWorks n'a pas de comptabilité générale et le coût standard inclut déjà la main-d'œuvre, un compte de résultat complet la compterait deux fois.
- `kpi_monthly` regroupe 31 indicateurs mensuels avec numérateur et dénominateur : les valeurs sur 12 mois glissants sont recalculées à partir des sommes, jamais en moyennant des taux. Les définitions sont dans `dbt/seeds/kpi_definitions.csv`.
- Masse salariale estimée : heures planifiées et heures supplémentaires majorées de 50 %, au taux horaire en vigueur.
- Constats issus des données sources, conservés tels quels : les expéditions partent toutes 7 ou 8 jours après la commande, et les coûts de gamme réels égalent les coûts prévus. Ni le retard de livraison ni l'écart de coût de production ne sont donc présentés.

## Développer en local, sans cloud

```
pip install -r requirements-dev.txt
python pipeline/load_local.py
cd dbt
dbt build --target local --profiles-dir .
```

La base `local.duckdb` reproduit la couche bronze : tout le projet dbt se construit et se teste en quelques secondes. Les macros de `dbt/macros` rendent le SQL identique sur DuckDB et BigQuery.

## Feuille de route

1. Données complémentaires générées et validées ✔
2. Lac de données en Parquet et chargement dans BigQuery (couche bronze) ✔
3. Transformations dbt : silver, dimensions, faits QHSE, Performance, Finance et RH, table d'indicateurs `kpi_monthly`, tests de qualité ✔
4. Orchestration mensuelle avec GitHub Actions ✔
5. Dashboard de reporting mensuel branché en direct sur la couche gold

## Sources de référence

- Coordonnées des pays, États et provinces : jeu public *countries-states-cities-database* (dr5hn, licence ODbL), dans `dbt/seeds/geo_*.csv`.
- Plan de l'usine : plan schématique illustratif des zones d'AdventureWorks (`dbt/seeds/plant_layout.csv`), sans valeur d'échelle.

## Avertissement

Les données complémentaires sont entièrement fictives et générées à des fins de démonstration. Elles ne décrivent aucune entreprise réelle.
