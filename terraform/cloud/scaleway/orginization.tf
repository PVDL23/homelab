# Projects
resource "scaleway_account_project" "homelab" {
  name        = var.homelab_project_name
  description = var.homelab_project_description
}

# Budget
resource "scaleway_billing_budget" "main" {
  consumption_limit = var.budget_limit
  enabled           = true
}

resource "scaleway_billing_budget_alert" "main" {
  budget_id = scaleway_billing_budget.main.id
  threshold = var.budget_alert_threshold
}


resource "scaleway_billing_budget_alert_notification" "email" {
  budget_alert_id = scaleway_billing_budget_alert.main.id
  email_addresses = var.budget_alert_email_addresses
}
