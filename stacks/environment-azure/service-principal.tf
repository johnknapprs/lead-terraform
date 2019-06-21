resource "azuread_application" "toolchain" {
  name                       = "${local.cluster}-app"
  available_to_other_tenants = false
}

resource "azuread_service_principal" "toolchain" {
  application_id = azuread_application.toolchain.application_id
  tags           = ["client:${local.cluster}"]
}

resource "random_string" "toolchain_password" {
  length  = 32
  special = true

  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = azurerm_resource_group.toolchain.name
  }
}

resource "azuread_service_principal_password" "toolchain" {
  service_principal_id = azuread_service_principal.toolchain.id
  value                = random_string.toolchain_password.result
  end_date_relative    = "2160h"
}

