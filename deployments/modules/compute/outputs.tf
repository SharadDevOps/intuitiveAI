output "principal_id" {
  description = "System-assigned managed identity principal ID — consumed by the KV vm access policy."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "public_ip" {
  description = "Public IP — used by the runbook for health checks."
  value       = azurerm_public_ip.this.ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.this.name
}

# in modules/compute/outputs.tf, add:
output "vm_id" {
  value = azurerm_linux_virtual_machine.this.id
}