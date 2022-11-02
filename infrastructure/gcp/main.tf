terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.38.0"
    }
  }

  cloud {}

}

provider "google" {
  region = "europe-west3"
  zone   = "europe-west3-a"
}

data "google_project" "project" {}

# Settings to enable NewRelic monitoring
resource "google_project_iam_member" "project" {
  project = data.google_project.project.id
  role    = "roles/viewer"
  member  = "serviceAccount:v73nzkydm3w@newrelic-gcp.iam.gserviceaccount.com"
}

resource "google_project_iam_binding" "project" {
  project = data.google_project.project.id
  role    = "roles/serviceusage.serviceUsageConsumer"

  members = [
    "serviceAccount:v73nzkydm3w@newrelic-gcp.iam.gserviceaccount.com"
  ]
}

# KMS definition
resource "google_kms_key_ring" "data-platform" {
  name     = "data-platform"
  location = "europe-west3"
}

# Buckets definition
module "bucket-landing" {
  source = "./storage"

  storage-name    = "landing"
  kms-key-ring-id = google_kms_key_ring.data-platform.id
}

module "bucket-landing-failed" {
  source = "./storage"

  storage-name    = "landing-failed"
  kms-key-ring-id = google_kms_key_ring.data-platform.id
}

module "bucket-staging" {
  source = "./storage"

  storage-name    = "staging"
  kms-key-ring-id = google_kms_key_ring.data-platform.id
}

module "bucket-staging-failed" {
  source = "./storage"

  storage-name    = "staging-failed"
  kms-key-ring-id = google_kms_key_ring.data-platform.id
}