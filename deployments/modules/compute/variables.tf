variable "vm_name" {
  type        = string
  description = "Name of the Linux VM."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the VM."
}

variable "subnet_id" {
  type        = string
  description = "Subnet the VM's NIC attaches to."
}

variable "vm_size" {
  type        = string
  description = "VM SKU."
}

variable "admin_username" {
  type        = string
  description = "Admin username for SSH."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for the admin user."
}

variable "custom_data" {
  type        = string
  description = "Base64-encoded cloud-init script."
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}