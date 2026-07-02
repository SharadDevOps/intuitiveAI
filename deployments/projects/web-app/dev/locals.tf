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

}
