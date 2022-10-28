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

data "google_storage_project_service_account" "storage-account" {}

# Data lake storage definition
resource "google_storage_bucket" "data-lake" {
  name                        = "borealis-data-lake"
  location                    = "EUROPE-WEST3"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  logging {
    log_bucket = "data-lake-logging"
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.data-lake.id
  }

  depends_on = [google_kms_crypto_key_iam_binding.data-lake-binding]

  labels = {
    "element" = "storage"
  }
}

resource "google_kms_crypto_key_iam_binding" "data-lake-binding" {
  crypto_key_id = google_kms_crypto_key.data-lake.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${data.google_storage_project_service_account.storage-account.email_address}"]
}

resource "google_kms_crypto_key" "data-lake" {
  name            = "data-lake"
  key_ring        = google_kms_key_ring.data-platform.id
  rotation_period = "7776000s" # 90 days

  labels = {
    "element" = "storage"
  }
}

# KMS definition
resource "google_kms_key_ring" "data-platform" {
  name     = "data-platform"
  location = "europe-west3"
}
