terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.38.0"
    }
  }

  cloud {
    organization = "borealis-infra"

    workspaces {
      name = "borealis-data-platform"
    }
  }
}

provider "google" {
  project = "borealis-363518"
  region  = "europe-southwest1"
  zone    = "europe-southwest1-a"
}

resource "google_storage_bucket" "data-lake" {
  name                        = "data-lake"
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

  depends_on = [google_kms_crypto_key_iam_binding.bucket-binding]
}

resource "google_kms_key_ring" "data-lake" {
  name     = "data-lake"
  location = "europe-southwest1"
}

resource "google_kms_crypto_key" "data-lake" {
  name            = "data-lake-key"
  key_ring        = google_kms_key_ring.data-lake.id
  rotation_period = "7776000s" # 90 days
}

data "google_storage_project_service_account" "data-lake-account" {
}

data "google_service_account" "terraform-account" {
  account_id = "113139545036935849851"
}

resource "google_kms_crypto_key_iam_binding" "bucket-binding" {
  crypto_key_id = google_kms_crypto_key.data-lake.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${data.google_storage_project_service_account.data-lake-account.email_address}"]
}

resource "google_kms_key_ring_iam_binding" "terraform-binding" {
  key_ring_id = google_kms_key_ring.data-lake.id
  role        = "roles/cloudkms.admin"
  members     = ["serviceAccount:${data.google_service_account.terraform-account.email}"]
}

data "google_storage_bucket" "default" {
  name = google_storage_bucket.data-lake.id
}

output "bucket_metadata" {
  value = data.google_storage_bucket.default
}
