terraform {

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.10.0"
    }
  }

  cloud {}

}

resource "confluent_service_account" "app-manager" {
  display_name = "borealis-support"
  description  = "Service account to manage Kafka cluster"
}

resource "confluent_environment" "staging" {
  display_name = "Staging"

  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_kafka_cluster" "staging" {
  display_name = "borealis-staging"
  availability = "SINGLE_ZONE"
  cloud        = "GCP"
  region       = "europe-west3"

  basic {}

  environment {
    id = confluent_environment.staging.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_stream_governance_cluster" "essentials" {
  package = "ESSENTIALS"

  environment {
    id = confluent_environment.staging.id
  }

  region {
    id = "sgreg-5"
  }

  lifecycle {
    prevent_destroy = true
  }
}
