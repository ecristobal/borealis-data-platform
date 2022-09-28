terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
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

resource "google_storage_bucket" "static" {
  name                        = "borealis-data-lake"
  location                    = "EUROPE-SOUTHWEST1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

data "google_storage_bucket" "default" {
  name = google_storage_bucket.static.id
}

output "bucket_metadata" {
  value = data.google_storage_bucket.default
}
