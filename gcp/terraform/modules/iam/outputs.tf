output "service_account_emails" {
  description = "Map of all service account emails"
  value = {
    for sa_name, sa in google_service_account.sa :
    sa_name => sa.email
  }
}