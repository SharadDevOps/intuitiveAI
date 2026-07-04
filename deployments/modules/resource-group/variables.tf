variable "name" {
    type        = string
    description = "The name of the resource group to create."
}

variable "location" {
    type        = string
    description = "The location of the resource group to create."
}


variable "tags" {
    type        = map(string)
    description = "A map of tags to assign to the resource group."
    default     = {}
}