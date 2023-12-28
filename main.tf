provider "confluent" {
}

locals {
  kafka_sa_environment = var.environment == "cert" ? "intg" : var.environment

  this = try(yamldecode(var.this_yaml), jsondecode(var.this_yaml))

  sa = [
    for name in local.this.service_accounts : {
      service_account_name = "${var.it_element}-${var.environment}-${name.service_account_name}"
    }
  ]

  topics = [
    for topic in local.this.topics : {
      topic_name = "${var.it_element}-${var.environment}-${topic.topic_name}"
      acls       = [
        for acl in topic.acls : {
          service_account_name = "${var.it_element}-${var.environment}-${acl.service_account_name}"
        }
      ]
      cgs        = [
        for cg in topic.cgs : {
          service_account_name = "${var.it_element}-${var.environment}-${cg.service_account_name}"
        }
      ]
    }
  ]
}

//service account module
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
      id = var.kafka_environment_id
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


//topic module

locals {
  default_config = {
    "retention.ms" : "21600000",
    "delete.retention.ms" : "21600000",
    "min.insync.replicas" : "1"
  }
}

resource "confluent_kafka_topic" "topic" {
  for_each         = { for topic in var.topics : topic["topic_name"] => topic }
  topic_name       = each.value.topic_name
  partitions_count = lookup(each.value, "partitions_count", 1)
  config = merge(
    local.default_config,
    lookup(each.value, "config", {})
  )
}

//Acls module
locals {
  acls          = flatten([for topic in var.topics : [for acl in topic.acls : [for op in acl.operations : merge(acl, { topic_name = topic.topic_name, operation = op })]]])
  cgs           = flatten([for topic in var.topics : [for cg in topic.cgs : [for op in cg.operations : merge(cg, { topic_name = topic.topic_name, operation = op })]]])
  external_acls = flatten([for topic in var.topics : [for acl in topic.external_acls : [for op in acl.operations : merge(acl, { topic_name = topic.topic_name, operation = op })]]])
  external_cgs  = flatten([for topic in var.topics : [for acl in topic.external_acls : [for op in acl.operations : merge(acl, { topic_name = topic.topic_name, operation = op })]]])
  external_sas = distinct(flatten(concat(
    [for topic in var.topics : [for acl in topic.external_acls : acl.service_account_name]],
    [for topic in var.topics : [for cg in topic.external_cgs : cg.service_account_name]],
  )))
}

data "confluent_service_account" "external_service_account" {
  for_each     = { for sa in local.external_sas : sa => sa }
  display_name = each.value
}

resource "confluent_kafka_acl" "acl_topics" {
  for_each      = { for acl in local.acls : lower("${acl.topic_name}-${acl.service_account_name}-${acl.operation}") => acl }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.topic[each.value.topic_name].topic_name
  pattern_type  = lookup(each.value, "pattern_type", "LITERAL")
  principal     = "User:${confluent_service_account.service_account[each.value.service_account_name].id}"
  host          = lookup(each.value, "host", "*")
  operation     = each.value.operation
  permission    = lookup(each.value, "permission", "ALLOW")
}

resource "confluent_kafka_acl" "acl_consumer_groups" {
  for_each      = { for cg in local.cgs : lower("${cg.topic_name}-${cg.service_account_name}-${cg.operation}") => cg }
  resource_type = "GROUP"
  resource_name = "${confluent_kafka_topic.topic[each.value.topic_name].topic_name}-cg"
  pattern_type  = lookup(each.value, "pattern_type", "LITERAL")
  principal     = "User:${confluent_service_account.service_account[each.value.service_account_name].id}"
  host          = lookup(each.value, "host", "*")
  operation     = each.value.operation
  permission    = lookup(each.value, "permission", "ALLOW")
}

resource "confluent_kafka_acl" "acl_external" {
  for_each      = { for acl in local.external_acls : lower("${acl.topic_name}-${acl.service_account_name}-${acl.operation}") => acl }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.topic[each.value.topic_name].topic_name
  pattern_type  = lookup(each.value, "pattern_type", "LITERAL")
  principal     = "User:${data.confluent_service_account.external_service_account[each.value.service_account_name].id}"
  host          = lookup(each.value, "host", "*")
  operation     = each.value.operation
  permission    = lookup(each.value, "permission", "ALLOW")
}

resource "confluent_kafka_acl" "acl_external_consumer_groups" {
  for_each      = { for cg in local.external_cgs : lower("${cg.topic_name}-${cg.service_account_name}-${cg.operation}") => cg }
  resource_type = "GROUP"
  resource_name = "${confluent_kafka_topic.topic[each.value.topic_name].topic_name}-cg"
  pattern_type  = lookup(each.value, "pattern_type", "LITERAL")
  principal     = "User:${data.confluent_service_account.external_service_account[each.value.service_account_name].id}"
  host          = lookup(each.value, "host", "*")
  operation     = each.value.operation
  permission    = lookup(each.value, "permission", "ALLOW")
}
