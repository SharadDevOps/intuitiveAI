data "azurerm_client_config" "current" {}


resource "azurerm_key_vault" "this" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  enable_rbac_authorization  = false
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags
}

