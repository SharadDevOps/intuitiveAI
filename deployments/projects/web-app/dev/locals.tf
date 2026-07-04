############################################
# Naming Convention
############################################

locals {

  prefix = join("-", [
    var.brand_alias,
    var.project_name_alias,
    var.environment_alias,
    var.location_alias
  ])

  resource_group_name = "rg-${local.prefix}"
  vnet_name           = "vnet-${local.prefix}"
  key_vault_name      = "kv-${local.prefix}"
  vm_name             = "vm-${local.prefix}"



  tags = {
    brand       = var.brand
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }

}
