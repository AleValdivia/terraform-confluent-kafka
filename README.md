<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=0.13 |
| <a name="requirement_confluent"></a> [confluent](#requirement\_confluent) | 1.55.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_confluent"></a> [confluent](#provider\_confluent) | 1.55.0 |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [confluent_api_key.service_account_kafka_api_key](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/resources/api_key) | resource |
| [confluent_kafka_acl.acl_consumer_groups](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/resources/kafka_acl) | resource |
| [confluent_kafka_acl.acl_external](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/resources/kafka_acl) | resource |
| [confluent_kafka_acl.acl_external_consumer_groups](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/resources/kafka_acl) | resource |
| [confluent_kafka_acl.acl_topics](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/resources/kafka_acl) | resource |
| [confluent_kafka_topic.topic](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/resources/kafka_topic) | resource |
| [confluent_role_binding.binding](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/resources/role_binding) | resource |
| [confluent_service_account.service_account](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/resources/service_account) | resource |
| [google_secret_manager_secret.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.key-version](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.secret-version](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [confluent_service_account.external_service_account](https://registry.terraform.io/providers/confluentinc/confluent/1.55.0/docs/data-sources/service_account) | data source |
| [google_secret_manager_secret_version.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version) | data source |
| [google_secret_manager_secret_version.secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_crn_pattern"></a> [crn\_pattern](#input\_crn\_pattern) | A Confluent Resource Name(CRN) that specifies the scope and resource patterns necessary for the role to bind. | `string` | `""` | no |
| <a name="input_environment_id"></a> [environment\_id](#input\_environment\_id) | The ID of the environment | `string` | n/a | yes |
| <a name="input_kafka_id"></a> [kafka\_id](#input\_kafka\_id) | The ID of the Cluster | `string` | n/a | yes |
| <a name="input_kafka_rest_endpoint"></a> [kafka\_rest\_endpoint](#input\_kafka\_rest\_endpoint) | REST endpoint of the Kafka cluster. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | labels to vault resources | `map(string)` | n/a | yes |
| <a name="input_managed_resource_api_version"></a> [managed\_resource\_api\_version](#input\_managed\_resource\_api\_version) | The API Version of the managed resource | `string` | `"cmk/v2"` | no |
| <a name="input_managed_resource_kind"></a> [managed\_resource\_kind](#input\_managed\_resource\_kind) | A kind of the managed resource | `string` | `"Cluster"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID | `string` | n/a | yes |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | The name of the secret | `string` | n/a | yes |
| <a name="input_service_accounts"></a> [service\_accounts](#input\_service\_accounts) | List of service account definitions to apply | <pre>list(object({<br>    service_account_name = optional(string),<br>    for_cluster          = optional(bool),<br>    role_name            = optional(string)<br>  }))</pre> | n/a | yes |
| <a name="input_topics"></a> [topics](#input\_topics) | list of topics to apply | `any` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_account_id"></a> [service\_account\_id](#output\_service\_account\_id) | The ID of the Service Account |
<!-- END_TF_DOCS -->