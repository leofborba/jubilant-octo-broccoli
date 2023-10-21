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

resource "google_storage_bucket" "ipnet_test_leonardo_borba" {
  name          = "ipnet_leonardo_borba"
  location      = "US"
  force_destroy = true

  versioning {
    enabled = true
  }

}

resource "google_storage_bucket_object" "bd_movies" {
  name         = "teste_lider_dados.csv"
  bucket       = google_storage_bucket.ipnet_test_leonardo_borba.name
  source       = "./teste_lider_dados.csv"
  content_type = "text/csv"
}

resource "google_bigquery_dataset" "dataset_movies" {
  dataset_id = "bd_movies_processed"
  project    = "ipnet-test-lb"
  location   = "US"

  labels = {
    "environment" = "ipnet-test",
    "owner"       = "leonardo_borba"
  }

}

resource "google_bigquery_table" "tbl_movies" {
  deletion_protection = false
  dataset_id          = google_bigquery_dataset.dataset_movies.dataset_id
  project             = google_bigquery_dataset.dataset_movies.project

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
  }
}



resource "google_bigquery_job" "job" {
  job_id = "job_load2"

  labels = {
    "my_job" = "load"
  }

  load {
    source_uris = [
      "gs://${google_storage_bucket_object.bd_movies.bucket}/${google_storage_bucket_object.bd_movies.name}",
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