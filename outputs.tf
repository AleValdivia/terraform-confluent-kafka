output "service_account_id" {
  description = "The ID of the Service Account"
  value       = values(confluent_service_account.service_account).*.id
}
