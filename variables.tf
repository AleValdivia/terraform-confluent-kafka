variable "environment_id" {
  description = "The ID of the environment"
  type        = string
}

variable "project_id" {
  description = "The project ID"
  type        = string
}

variable "service_accounts" {
  description = "List of service account definitions to apply"
  type = list(object({
    service_account_name = optional(string),
    for_cluster          = optional(bool),
    role_name            = optional(string)
  }))
}

variable "crn_pattern" {
  description = "A Confluent Resource Name(CRN) that specifies the scope and resource patterns necessary for the role to bind."
  type        = string
  default     = ""
}

variable "managed_resource_api_version" {
  description = "The API Version of the managed resource"
  type        = string
  default     = "cmk/v2"
}

variable "managed_resource_kind" {
  description = "A kind of the managed resource"
  type        = string
  default     = "Cluster"
}

variable "labels" {
  description = "labels to vault resources"
  type        = map(string)
}

variable "topics" {
  description = "list of topics to apply"
  default     = []
  type        = any
}

variable "kafka_id" {
  type        = string
  default = ""
}
