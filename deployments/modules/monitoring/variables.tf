variable "name_prefix" {
  type        = string
  description = "Prefix for naming monitoring resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for monitoring resources."
}

variable "vm_id" {
  type        = string
  description = "Resource ID of the VM to monitor."
}

variable "tags" {
  type    = map(string)
  default = {}
}