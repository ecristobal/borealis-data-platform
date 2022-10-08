terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.38.0"
    }
  }

  cloud {
    organization = "borealis-infrastructure"

    workspaces {
      name = "borealis-gcp-data-platform"
    }
  }
}

provider "google" {
  project = "borealis-364020"
  region  = "europe-southwest1"
  zone    = "europe-southwest1-a"
}

# Storage definition
resource "google_storage_bucket" "data-lake" {
  name                        = "borealis-data-lake"
  location                    = "EUROPE-SOUTHWEST1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  logging {
    log_bucket = "data-lake-logging"
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage.id
  }

  depends_on = [google_kms_crypto_key_iam_binding.bucket-binding]

  labels = {
    "element" = "storage"
  }
}

data "google_storage_project_service_account" "data-lake-account" {
}

resource "google_kms_crypto_key_iam_binding" "bucket-binding" {
  crypto_key_id = google_kms_crypto_key.storage.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${data.google_storage_project_service_account.data-lake-account.email_address}"]
}

resource "google_kms_crypto_key" "storage" {
  name            = "storage"
  key_ring        = google_kms_key_ring.data-platform.id
  rotation_period = "7776000s" # 90 days
  labels = {
    "element" = "storage"
  }
}

# Topics definition
resource "google_pubsub_topic" "exercises" {
  name         = "borealis.data.input.exercises"
  kms_key_name = google_kms_crypto_key.exercises.id
  labels = {
    "element" = "topic"
  }
}

resource "google_kms_crypto_key" "exercises" {
  name            = "exercises"
  key_ring        = google_kms_key_ring.data-platform.id
  rotation_period = "7776000s" # 90 days
  labels = {
    "element" = "topic"
  }
}

# KMS definition
resource "google_kms_key_ring" "data-platform" {
  name     = "data-platform"
  location = "europe-southwest1"
}
