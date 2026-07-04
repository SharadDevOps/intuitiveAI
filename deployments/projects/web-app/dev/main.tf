data "azurerm_client_config" "current" {}

module "resource_group" {
  source = "../../../modules/resource-group"

  name     = local.resource_group_name
  location = var.location

  tags = local.tags
}

module "virtual_network" {
  source              = "../../../modules/networking"
  vnet_name           = local.vnet_name
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    web = { address_prefixes = ["10.0.1.0/24"] }
  }

  nsg_rules = {
    allow-https = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"          # public web service
      destination_address_prefix = "*"
    }
    allow-ssh = {
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.allowed_ssh_cidr   # your IP only — NOT *
      destination_address_prefix = "*"
    }
  }

  tags = local.tags
}


module "key_vault" {
  source = "../../../modules/key-vault"

  key_vault_name      = local.key_vault_name
  location            = var.location
  resource_group_name = module.resource_group.name
  
  tags                = local.tags
}

# Deployer / operator grant — broad enough to manage secrets in the vault.
resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = module.key_vault.id
  tenant_id    = module.key_vault.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"
  ]
}


module "compute" {
  source              = "../../../modules/compute"
  vm_name             = local.vm_name
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.virtual_network.subnet_ids["web"]
  admin_username      = var.admin_username
  ssh_public_key      = file(var.ssh_public_key_path)
  vm_size            = var.vm_size
  custom_data         = base64encode(file("${path.module}/../../../../scripts/cloud-init.sh"))
  tags                = local.tags
}

# VM managed-identity grant — least privilege: read secrets only.
resource "azurerm_key_vault_access_policy" "vm" {
  key_vault_id = module.key_vault.id
  tenant_id    = module.key_vault.tenant_id
  object_id    = module.compute.principal_id

  secret_permissions = ["Get", "List"]
}


module "monitoring" {
  source              = "../../../modules/monitoring"
  name_prefix         = local.prefix
  resource_group_name = module.resource_group.name
  vm_id               = module.compute.vm_id
  tags                = local.tags
}