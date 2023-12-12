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
