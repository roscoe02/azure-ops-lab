resource "azurerm_monitor_action_group" "email" {
  name                = "ag-${var.prefix}-email"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "opslab"
  tags                = local.tags

  email_receiver {
    name          = "owner"
    email_address = var.alert_email
  }
}

# Email me if the VM stops being available
resource "azurerm_monitor_metric_alert" "vm_down" {
  name                = "alert-${var.prefix}-vm-unavailable"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "VM availability dropped below 100%"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.email.id
  }
}

# Email me if CPU stays pinned (runaway process or something worse)
resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "alert-${var.prefix}-cpu-high"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "CPU above 90% for 15 minutes"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.email.id
  }
}

# Budget: email at 50% and 90% of actual spend, and when the forecast passes 100%
data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "monthly" {
  count           = var.enable_budget ? 1 : 0
  name            = "budget-${var.prefix}-monthly"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.monthly_budget_usd
  time_grain      = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }

  lifecycle {
    ignore_changes = [time_period] # timestamp() would otherwise change on every plan
  }
}
