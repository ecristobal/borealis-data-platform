data "google_storage_project_service_account" "storage-account" {}

resource "google_storage_bucket" "data-lake" {
  name                        = "borealis-${var.storage-name}"
  location                    = "EUROPE-WEST3"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age                   = 30
      matches_storage_class = [ "STANDARD" ]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 30
      matches_storage_class = [ "NEARLINE" ]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 30
      matches_storage_class = [ "COLDLINE" ]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  versioning {
    enabled = true
  }

  logging {
    log_bucket = "${var.storage-name}-logging"
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.data-lake.id
  }

  depends_on = [ google_kms_crypto_key_iam_binding.data-lake-binding ]

  labels = {
    "element" = "storage"
  }
}

resource "google_kms_crypto_key_iam_binding" "data-lake-binding" {
  crypto_key_id = google_kms_crypto_key.data-lake.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = [ "serviceAccount:${data.google_storage_project_service_account.storage-account.email_address}" ]
}

resource "google_kms_crypto_key" "data-lake" {
  name            = "${var.storage-name}-key"
  key_ring        = var.kms-key-ring-id
  rotation_period = "7776000s" # 90 days

  labels = {
    "element" = "storage"
  }
}