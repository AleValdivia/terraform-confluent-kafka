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
