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

resource "confluent_kafka_cluster" "cluster" {
  display_name = "borealis"
  availability = "SINGLE_ZONE"
  cloud        = "GCP"
  region       = "europe-west3"

  basic {}

  environment {
    id = confluent_environment.staging.id
  }
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cluster.rbac_crn
}

resource "confluent_api_key" "app-manager-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cluster.id
    api_version = confluent_kafka_cluster.cluster.api_version
    kind        = confluent_kafka_cluster.cluster.kind

    environment {
      id = confluent_environment.staging.id
    }
  }

  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]

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
}

resource "confluent_kafka_topic" "exercises" {

  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  topic_name       = "es.borealis.exercises.landing"
  partitions_count = 2
  rest_endpoint    = confluent_kafka_cluster.cluster.rest_endpoint
  config           = {
    "cleanup.policy"      = "compact"
    "delete.retention.ms" = "86400000"
    "retention.ms"        = "604800000"
  }

  credentials {
    key    = confluent_api_key.app-manager-api-key.id
    secret = confluent_api_key.app-manager-api-key.secret
  }
}
