"""
Charge le lac de données dans la couche bronze de BigQuery.

Chaque fichier Parquet listé dans lake/manifest.csv devient une table bronze,
remplacée entièrement à chaque exécution (le sandbox BigQuery n'accepte pas les
INSERT, UPDATE ou MERGE, mais autorise les chargements de fichiers).

Variables d'environnement :
  GCP_PROJECT_ID                  identifiant du projet (obligatoire)
  BQ_LOCATION                     région des jeux de données (défaut : EU)
  GOOGLE_APPLICATION_CREDENTIALS  chemin de la clé JSON (fourni par GitHub Actions)
Option : --dry-run affiche le plan de chargement sans contacter BigQuery.
"""
import os, sys
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAKE = os.path.join(ROOT, 'lake')
DATASET = 'bronze'


def main(dry_run=False):
    project = os.environ.get('GCP_PROJECT_ID')
    location = os.environ.get('BQ_LOCATION', 'EU')
    manifest = pd.read_csv(os.path.join(LAKE, 'manifest.csv'))
    if dry_run:
        for r in manifest.itertuples():
            print(f'{r.source}/{r.name}.parquet -> {project}.{DATASET}.{r.bronze_table} ({r.row_count} lignes)')
        return
    if not project:
        sys.exit('GCP_PROJECT_ID manquant.')

    from google.cloud import bigquery
    client = bigquery.Client(project=project, location=location)
    ds = bigquery.Dataset(f'{project}.{DATASET}')
    ds.location = location
    ds.description = 'Couche bronze : tables sources brutes, rechargées entièrement à chaque exécution.'
    client.create_dataset(ds, exists_ok=True)

    cfg = bigquery.LoadJobConfig(source_format=bigquery.SourceFormat.PARQUET,
                                 write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE)
    errors = []
    for r in manifest.itertuples():
        table_id = f'{project}.{DATASET}.{r.bronze_table}'
        with open(os.path.join(LAKE, r.source, r.name + '.parquet'), 'rb') as f:
            job = client.load_table_from_file(f, table_id, job_config=cfg)
        try:
            job.result()
            loaded = client.get_table(table_id).num_rows
            status = 'OK' if loaded == r.row_count else f'ÉCART ({loaded} chargées)'
            if loaded != r.row_count:
                errors.append(r.bronze_table)
        except Exception as e:
            status = f'ERREUR : {e}'
            errors.append(r.bronze_table)
        print(f'{r.bronze_table:<55} {r.row_count:>8} lignes  {status}')
    if errors:
        sys.exit(f'{len(errors)} table(s) en échec : {", ".join(errors)}')
    print(f'{len(manifest)} tables chargées dans {project}.{DATASET} ({location}).')


if __name__ == '__main__':
    main(dry_run='--dry-run' in sys.argv)
