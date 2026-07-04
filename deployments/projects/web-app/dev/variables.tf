
variable "location" {
  type        = string
  description = "The location of the resource group to create."
}

variable "location_alias" {
  type        = string
  description = "The alias for the location of the resource group to create."
}

variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "project_name_alias" {
  type        = string
  description = "The alias for the project."
}

variable "environment" {
  type        = string
  description = "The environment for the resource group."
}

variable "environment_alias" {
  type        = string
  description = "The alias for the environment."
}

variable "brand" {
  type        = string
  description = "The brand for the resource group."
}

variable "brand_alias" {
  type        = string
  description = "The alias for the brand."
}

variable "client_id" {
  type        = string
  description = "The client ID of the Azure service principal."
}

variable "client_secret" {
  type        = string
  description = "The client secret of the Azure service principal."
}

variable "tenant_id" {
  type        = string
  description = "The tenant ID of the Azure service principal."
}

variable "subscription_id" {
  type        = string
  description = "The subscription ID of the Azure service principal."
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH to the VM. Your IP only — never 0.0.0.0/0."
}

variable "admin_username" {
  type        = string
  description = "Admin username for SSH."
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key for the admin user."
}

variable "vm_size" {
  type        = string
  description = "VM SKU."
}


