output "id" {
  description = "Key Vault resource ID — consumed by the access-policy resources in root."
  value       = azurerm_key_vault.this.id
}

output "uri" {
  description = "Key Vault URI — referenced by cloud-init and the runbook."
  value       = azurerm_key_vault.this.vault_uri
}

output "name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.this.name
}

output "tenant_id" {
  description = "Tenant ID — reused by the root when building access policies."
  value       = data.azurerm_client_config.current.tenant_id
}