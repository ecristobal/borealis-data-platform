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
}

resource "confluent_stream_governance_cluster" "essentials" {
  package = "ESSENTIALS"

  environment {
    id = confluent_environment.staging.id
  }

  region {
    id = "sgreg-5"
  }
}

resource "confluent_kafka_topic" "exercises" {

  kafka_cluster {
    id = confluent_kafka_cluster.staging.id
  }

  topic_name       = "es.borealis.exercises.landing"
  partitions_count = 2
  config = {
    "delete.retention.ms" = "86400000"
    "retention.ms"        = "604800000"
  }
}
