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

resource "google_bigquery_dataset" "db_movies_processed" {
  dataset_id = "db_movies_processed"
  project    = "ipnet-test-lb"
  location   = "US"

  labels = {
    "environment" = "ipnet-test",
    "owner"       = "leonardo_borba",
    "data_layer" = "processed"
  }

  access {
    dataset {
      dataset {
        project_id = google_bigquery_dataset.dataset_movies_curated.project
        dataset_id = google_bigquery_dataset.dataset_movies_curated.dataset_id
      }
      target_types = ["VIEWS"]
    }
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
            "name": "movie_name",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Movie name"
        },
        {
            "name": "year_of_release",
            "type": "INTEGER",
            "mode": "NULLABLE",
            "description": "Year of release"
        },
        {
            "name": "run_time_in_minutes",
            "type": "INTEGER",
            "mode": "NULLABLE",
            "description": "Duration"
        },
        {
            "name": "movie_rating",
            "type": "FLOAT",
            "mode": "NULLABLE",
            "description": "Movie rating"
        },
        {
            "name": "votes",
            "type": "INTEGER",
            "mode": "NULLABLE",
            "description": "Votes"
        },
        {
            "name": "metascore",
            "type": "FLOAT",
            "mode": "NULLABLE",
            "description": "Score"
        },
        {
            "name": "gross",
            "type": "FLOAT",
            "mode": "NULLABLE",
            "description": ""
        },
        {
            "name": "genre",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Genre of movie"
        },
        {
            "name": "certification",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": ""
        },
        {
            "name": "director",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Director"
        },
        {
            "name": "stars",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Cast of movies"
        },
        {
            "name": "description",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Movie description"
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
  job_id = "job_load29"
  
  labels = {
    "load_from" = "gcs_bucket_db_movies",
    "environment" = "ipnet-test",
    "owner"       = "leonardo_borba",    
  }

  load {
    source_uris = [
      "https://storage.cloud.google.com/db_movies_raw/teste_lider_dados.csv",      
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

  access {
    role = "roles/bigquery.dataViewer"
    user_by_email = "lb@leonardoborba.com.br"
  }

}

resource "google_bigquery_dataset_access" "access" {
  dataset_id    = google_bigquery_dataset.db_movies_processed.dataset_id
  view {
    project_id = google_bigquery_table.ninesview.project
    dataset_id = google_bigquery_dataset.dataset_movies_curated.dataset_id
    table_id   = google_bigquery_table.ninesview.table_id
  }
}

# Create a BigQuery view in the dataset
resource "google_bigquery_table" "ninesview" {
    depends_on = ["google_bigquery_table.tbl_movies"]
    deletion_protection = false
    
    dataset_id = google_bigquery_dataset.dataset_movies_curated.dataset_id
    project = google_bigquery_dataset.dataset_movies_curated.project
    table_id   = "action_movies_from_90s"
  
    view {
        query = "SELECT * FROM `ipnet-test-lb.db_movies_processed.tbl_movies` where `genre` like '%Action%' and `year_of_release` between 1990 and 1999"
        use_legacy_sql = false
    }
}