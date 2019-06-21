resource "azurerm_resource_group" "toolchain" {
  name     = "lead-toolchain-${local.cluster}"
  location = var.azure_region
  tags     = local.tags
}

data "azuread_group" "contributors" {
  name = var.contributor_group_name
}

data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

resource "azurerm_role_assignment" "toolchain" {
  scope                = azurerm_resource_group.toolchain.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_group.contributors.id
}
