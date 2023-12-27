 locals {
  kafka_sa_environment  = var.environment == "cert" ? "intg" : var.environment
  this = yamldecode(terragrunt.get_env("this_yaml"))

  sa = tolist([
    for name in lookup(local.this, "service_accounts", []) : {
      service_account_name = "${var.it_element}-${var.environment}-${name.service_account_name}"
    }
  ])

  topics = tolist([
    for topic in lookup(local.this, "topics", []) : merge(topic, {
      topic_name = "${local.this.it_element}-${var.environment}-${topic.topic_name}"
      acls       = [for acl in lookup(topic, "acls", []) : merge(acl, { service_account_name = "${var.it_element}-${var.environment}-${acl.service_account_name}" })]
      cgs        = [for cg in lookup(topic, "cgs", []) : merge(cg, { service_account_name = "${var.it_element}-${var.environment}-${cg.service_account_name}" })]
     })
  ])
}

inputs = merge(
  local.common_vars,
  local.this,
  {
    labels = {
      app      = "${lower(local.common_vars.bitbucket_key)}-${var.environment}"
      project  = local.common_vars.project_id
      platform = "confluent"
      resource = "service_acount"
    },
    project_id       = local.sm
    secret_name      = "${local.this.kafka_id}-${local.kafka_sa_environment}-sa"
    service_accounts = local.sa
    topics           = local.topics
  }
)
