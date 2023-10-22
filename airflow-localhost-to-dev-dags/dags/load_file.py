from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.utils.dates import days_ago

# DAG parameters
dag_id = 'gcs_to_bq'
gcs_bucket = 'https://storage.cloud.google.com/db_movies_raw/'
gcs_object = 'teste_lider_dados.csv'
destination_project_dataset_table = 'ipnet-test-lb:db_movies_processed.tbl_movies'

# Define default_args and schedule_interval
default_args = {
    'start_date': days_ago(1),
    'retries': 1,
}

# Create the DAG
dag = DAG(
    dag_id=dag_id,
    default_args=default_args,
    schedule_interval=None,  
    catchup=False,
)

# Task to load data from GCS to BigQuery
load_gcs_to_bq = GCSToBigQueryOperator(
    task_id='load_gcs_to_bq',
    bucket_name=gcs_bucket,
    source_objects=[gcs_object],
    destination_project_dataset_table=destination_project_dataset_table,
    schema_fields=None, 
    create_disposition='CREATE_IF_NEEDED',
    skip_leading_rows=1,
    autodetect=True,  
    write_disposition='WRITE_APPEND',  
    field_delimiter=',',  
    bigquery_conn_id='google_cloud_default',
    google_cloud_storage_conn_id='google_cloud_default',
    dag=dag,
)

# Set the task dependencies
load_gcs_to_bq