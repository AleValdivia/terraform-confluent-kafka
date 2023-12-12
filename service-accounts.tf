resource "confluent_service_account" "service_account" {
  for_each     = { for sa in var.service_accounts : sa["service_account_name"] => sa }
  display_name = each.value.service_account_name
  description  = "Service Account ${each.value.service_account_name}"
}

resource "confluent_role_binding" "binding" {
  for_each = {
    for sa in var.service_accounts : sa["service_account_name"] => sa
    if sa.for_cluster == true
  }
  principal   = "User:${confluent_service_account.service_account[each.key].id}"
  role_name   = each.value.role_name
  crn_pattern = var.crn_pattern

  depends_on = [
    confluent_service_account.service_account
  ]
}

resource "confluent_api_key" "service_account_kafka_api_key" {
  for_each     = confluent_service_account.service_account
  display_name = "api-key-${each.key}"
  description  = "API Key of service account ${each.key}"

  owner {
    id          = each.value.id
    api_version = each.value.api_version
    kind        = each.value.kind
  }

  managed_resource {
    id          = var.kafka_id
    api_version = var.managed_resource_api_version
    kind        = var.managed_resource_kind

    environment {
      id = var.environment_id
    }
  }

  depends_on = [
    confluent_role_binding.binding
  ]
}

resource "google_secret_manager_secret" "key" {
  for_each  = confluent_service_account.service_account
  project   = var.project_id
  secret_id = "${each.key}-key"
  labels    = merge(var.labels, { id = each.value.id })
  replication {
    user_managed {
      replicas {
        location = "us-east1"
      }
      replicas {
        location = "us-central1"
      }
    }
  }
  lifecycle {
    replace_triggered_by = [
      confluent_api_key.service_account_kafka_api_key
    ]
  }

  depends_on = [
    confluent_api_key.service_account_kafka_api_key
  ]
}

resource "google_secret_manager_secret_version" "key-version" {
  for_each    = confluent_service_account.service_account
  secret      = google_secret_manager_secret.key[each.key].id
  secret_data = confluent_api_key.service_account_kafka_api_key[each.key].id

  lifecycle {
    replace_triggered_by = [
      confluent_api_key.service_account_kafka_api_key
    ]
  }

  depends_on = [
    google_secret_manager_secret.key
  ]
}

resource "google_secret_manager_secret" "secret" {
  for_each  = confluent_service_account.service_account
  project   = var.project_id
  secret_id = "${each.key}-secret"
  labels    = merge(var.labels, { id = each.value.id })
  replication {
    user_managed {
      replicas {
        location = "us-east1"
      }
      replicas {
        location = "us-central1"
      }
    }
  }

  lifecycle {
    replace_triggered_by = [
      confluent_api_key.service_account_kafka_api_key
    ]
  }

  depends_on = [
    confluent_api_key.service_account_kafka_api_key
  ]
}

resource "google_secret_manager_secret_version" "secret-version" {
  for_each    = confluent_service_account.service_account
  secret      = google_secret_manager_secret.secret[each.key].id
  secret_data = confluent_api_key.service_account_kafka_api_key[each.key].secret

  lifecycle {
    replace_triggered_by = [
      confluent_api_key.service_account_kafka_api_key
    ]
  }

  depends_on = [
    google_secret_manager_secret.secret
  ]
}
