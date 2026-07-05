output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Map of subnet name -> subnet ID. Compute picks the one it needs."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "nsg_id" {
  value = azurerm_network_security_group.this.id
}