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

resource "google_storage_bucket" "db_movies_raw" {
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
  bucket       = google_storage_bucket.db_movies_raw.name
  source       = "../../teste_lider_dados.csv"
  content_type = "text/csv"

}