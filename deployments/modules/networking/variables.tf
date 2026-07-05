variable "vnet_name" {
  type        = string
  description = "Name of the virtual network."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the network resources."
}

variable "address_space" {
  type        = list(string)
  description = "VNet address space, e.g. [\"10.0.0.0/16\"]."
}

variable "subnets" {
  description = "Map of subnets keyed by name. Each has an address prefix."
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "nsg_rules" {
  description = "Map of NSG security rules keyed by name."
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {}
}


variable "tags" {
  type    = map(string)
  default = {}
}