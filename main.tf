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
  name                        = "borealis-data-lake"
  location                    = "EUROPE-SOUTHWEST1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  logging {
    log_bucket = "borealis-data-lake-logging"
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.data-lake-sign-key.name
  }
}

resource "google_kms_key_ring" "borealis-data-platform-keyring" {
  name     = "borealis-data-platform"
  location = "europe-southwest1"
}

resource "google_kms_crypto_key" "data-lake-sign-key" {
  name            = "data-lake-sign"
  key_ring        = google_kms_key_ring.borealis-data-platform-keyring.id
  purpose         = "ASYMMETRIC_SIGN"
  rotation_period = "7776000s" # 90 days

  version_template {
    algorithm = "EC_SIGN_P384_SHA384"
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "google_storage_bucket" "default" {
  name = google_storage_bucket.data-lake.id
}

output "bucket_metadata" {
  value = data.google_storage_bucket.default
}
