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


# Create a service account
resource "google_service_account" "airflow_sa" {
  account_id   = "airflow-service-account"
  display_name = "Airflow Service Account"
}

# Assign roles to the service account
resource "google_project_iam_member" "airflow_sa_roles" {
  project = "ipnet-test-lb"
  role    = "roles/storage.admin"  # Adjust the roles as needed
  member  = "serviceAccount:${google_service_account.airflow_sa.email}"
}

# Get the JSON key for the service account
resource "google_service_account_key" "airflow_sa_key" {   
  service_account_id = google_service_account.airflow_sa.name
}

resource "google_compute_instance" "airflow_instance" {
  name         = "airflow-instance"
  machine_type = "e2-standard-2"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3-pip
    pip3 install apache-airflow
    airflow initdb
    airflow webserver -p 8080 &
    airflow scheduler &
    
    # Use the service account key for authentication
    echo '${google_service_account_key.airflow_sa_key.private_key}' > /tmp/airflow-service-account-key.json
    export GOOGLE_APPLICATION_CREDENTIALS="/tmp/airflow-service-account-key.json"
    
    # Additional Terraform commands or provisioning steps
    # ...
    EOF
}

# Create a firewall rule to allow HTTP (port 80) and HTTPS (port 443) traffic
resource "google_compute_firewall" "allow-http-https-airflow" {
  name    = "allow-http-https-airflow"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]  # Allow port 8080 for Apache Airflow
  }

  source_ranges = ["0.0.0.0/0"]  # Allow traffic from any source (be cautious in production)
}
