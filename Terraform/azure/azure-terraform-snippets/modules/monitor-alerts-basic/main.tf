resource "azurerm_monitor_action_group" "ag" {
  name                = "${var.name}-ag"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"
  email_receiver {
    name          = "ops"
    email_address = var.email
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "${var.name}-cpu-high"
  resource_group_name = var.resource_group_name
  scopes              = [var.target_vm_id]
  description         = "High CPU on VM"
  severity            = 2
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }
  action { action_group_id = azurerm_monitor_action_group.ag.id }
}
