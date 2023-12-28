provider "confluent" {
}

locals {
  kafka_sa_environment = var.environment == "cert" ? "intg" : var.environment

  this = yamldecode(var.this_yaml)

  sa = [
    for name in local.this.service_accounts : {
      service_account_name = "${var.it_element}-${var.environment}-${name.service_account_name}"
    }
  ]

  topics = [
    for topic in local.this.topics : {
      topic_name = "${local.this.it_element}-${var.environment}-${topic.topic_name}"
      acls       = [
        for acl in topic.acls : {
          service_account_name = "${var.it_element}-${var.environment}-${acl.service_account_name}"
          # Add other ACL properties here
        }
      ]
      cgs        = [
        for cg in topic.cgs : {
          service_account_name = "${var.it_element}-${var.environment}-${cg.service_account_name}"
          # Add other CG properties here
        }
      ]
    }
  ]
}
