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

module "service-accounts" {
  source = "./service-accounts.tf"
}

module "topics" {
  source = "./topics.tf"
}


module "acl" {
  source = "./acl.tf"
}