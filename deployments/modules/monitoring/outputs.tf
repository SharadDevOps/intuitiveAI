output "action_group_id" {
  value = azurerm_monitor_action_group.this.id
}

output "metric_alert_id" {
  value = azurerm_monitor_metric_alert.vm_availability.id
}