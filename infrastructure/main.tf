terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.38.0"
    }
  }
  
}

provider "google" {
  region = "europe-southwest1"
  zone   = "europe-southwest1-a"
}

data "google_project" "project" {}

data "google_storage_project_service_account" "storage-account" {}

# Data lake storage definition
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

# Dataflow storage definition
resource "google_storage_bucket" "dataflow" {
  name                        = "borealis-dataflow"
  location                    = "EUROPE-SOUTHWEST1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  logging {
    log_bucket = "dataflow-logging"
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.dataflow.id
  }

  depends_on = [google_kms_crypto_key_iam_binding.dataflow-binding]

  labels = {
    "element" = "storage"
  }
}

resource "google_kms_crypto_key_iam_binding" "dataflow-binding" {
  crypto_key_id = google_kms_crypto_key.dataflow.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${data.google_storage_project_service_account.storage-account.email_address}"]
}

resource "google_kms_crypto_key" "dataflow" {
  name            = "dataflow"
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

resource "google_project_service_identity" "pubsub_service_account" {
  provider = google-beta
  project  = data.google_project.project.project_id
  service  = "pubsub.googleapis.com"
}

resource "google_kms_crypto_key_iam_binding" "exercises-topic-binding" {
  crypto_key_id = google_kms_crypto_key.exercises.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${google_project_service_identity.pubsub_service_account.email}"]
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
