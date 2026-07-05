# Action group — where alert notifications go.
resource "azurerm_monitor_action_group" "this" {
  name                = "ag-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = "intaialert"
  tags                = var.tags

  # Add an email_receiver here to actually receive alerts, e.g.:
  # email_receiver {
  #   name          = "ops"
  #   email_address = "you@example.com"
  # }
}

# Alert when the VM stops being available (VM health).
resource "azurerm_monitor_metric_alert" "vm_availability" {
  name                = "alert-vm-availability-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.vm_id]
  description         = "Fires when the VM availability drops below 100%, indicating the VM is unhealthy or unreachable."
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}