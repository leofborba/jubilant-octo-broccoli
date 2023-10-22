terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project = "ipnet-test-lb"
  region  = "US"
  zone    = "US"
}

resource "google_storage_bucket" "db_movies_raw2" {
  name          = "db_movies_raw"
  location      = "US"
  force_destroy = true

  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
        age = 7
        with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
      with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

}

resource "google_storage_bucket_object" "db_movies_file" {
  name         = "teste_lider_dados.csv"
  bucket       = google_storage_bucket.db_movies_raw2.name
  source       = "../teste_lider_dados.csv"
  content_type = "text/csv"

}

resource "google_bigquery_dataset" "db_movies_processed" {
  dataset_id = "db_movies_processed"
  project    = "ipnet-test-lb"
  location   = "US"

  labels = {
    "environment" = "ipnet-test",
    "owner"       = "leonardo_borba",
    "data_layer" = "processed"
  }

}

resource "google_bigquery_table" "tbl_movies" {
  deletion_protection = false
  dataset_id          = google_bigquery_dataset.db_movies_processed.dataset_id
  project             = google_bigquery_dataset.db_movies_processed.project

  table_id = "tbl_movies"

  schema = <<EOF
    [
      {
        "name"        : "column1",
        "type"       : "STRING",
        "mode"        : "NULLABLE",
        "description" : "Description for column1"
      },
      {
        "name"        : "column2",
        "type"        : "INTEGER",
        "mode"        : "NULLABLE",
        "description" : "Description for column2"
      },
      {
        "name"        : "sys_created_at",
        "type"       : "DATETIME",
        "mode"        : "NULLABLE",
        "description" : "Date time of row was inserted"
      }
    ]
    EOF

  time_partitioning {
    type  = "DAY"
    field = "sys_created_at" # Replace with your partitioning column
  }

  labels = {
    "data_source" = "gcs_bucket_db_movies",
    "environment" = "ipnet-test",
    "owner"       = "leonardo_borba",
    "data_layer" = "raw"
  }
}



resource "google_bigquery_job" "job" {
  job_id = "job_load4"

  labels = {
    "load_from" = "gcs_bucket_db_movies",
    "environment" = "ipnet-test",
    "owner"       = "leonardo_borba",    
  }

  load {
    source_uris = [
      "gs://${google_storage_bucket_object.db_movies_file.bucket}/${google_storage_bucket_object.db_movies_file.name}",
    ]

    destination_table {
      project_id = google_bigquery_table.tbl_movies.project
      dataset_id = google_bigquery_table.tbl_movies.dataset_id
      table_id   = google_bigquery_table.tbl_movies.table_id
    }

    skip_leading_rows     = 1
    schema_update_options = ["ALLOW_FIELD_RELAXATION", "ALLOW_FIELD_ADDITION"]

    write_disposition = "WRITE_APPEND"
    autodetect        = true
  }
}

resource "google_bigquery_dataset" "dataset_movies_curated" {
  dataset_id = "db_movies_curated"
  project    = "ipnet-test-lb"
  location   = "US"

  labels = {
    "environment" = "ipnet-test",
    "owner"       = "leonardo_borba",
    "data_layer" = "curated"
  }

}

resource "google_bigquery_job" "job_create_materialized_view" {
  job_id     = "job_create_materialized_view4"

  query {
    query = "CREATE MATERIALIZED VIEW  `ipnet-test-lb.db_movies_curated.action_movies_from_90s` AS (SELECT * FROM `ipnet-test-lb.db_movies_processed.tbl_movies` where Genre like '%Action%' and Year_of_Release between 1990 and 1999);"
  }
}