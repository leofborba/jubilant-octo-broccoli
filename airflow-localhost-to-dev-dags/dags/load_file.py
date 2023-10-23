from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.utils.dates import days_ago
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta

# DAG parameters
dag_id = 'gcs_to_bq'
gcs_bucket = 'https://storage.cloud.google.com/db_movies_raw/'
gcs_object = 'teste_lider_dados.csv'
destination_project_dataset_table = 'ipnet-test-lb:db_movies_processed.tbl_movies'

# Parametros basicos
default_args = {
   'owner': 'leonardo_borba',
   'depends_on_past': False,
   'start_date': datetime(2023, 10, 15)
   }
# DAG
with DAG(
    'db_movies_data_ingestion',
    schedule_interval='3 0 * * *',
    catchup=True,
    default_args=default_args
    ) as dag:

  # Task to treat the data
  data_processing = BashOperator(
      task_id='data_processing',
      bash_command="""processing some data..."""
  )

  # Task to load data from GCS to BigQuery
  load_gcs_to_bq = GCSToBigQueryOperator(
      task_id='load_gcs_to_bq',
      bucket=gcs_bucket,
      source_objects=[gcs_object],
      destination_project_dataset_table=destination_project_dataset_table,
      schema_fields=None, 
      create_disposition='CREATE_IF_NEEDED',
      skip_leading_rows=1,
      autodetect=True,  
      write_disposition='WRITE_APPEND',  
      field_delimiter=',',  
      dag=dag,
  )

# Set the task dependencies
data_processing >> load_gcs_to_bq