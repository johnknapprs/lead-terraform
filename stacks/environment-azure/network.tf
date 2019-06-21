locals {
  virtual_network_name           = "${local.cluster}-virtual-network"
  virtual_network_address_prefix = "10.0.0.0/8"

  app_gateway_subnet_name           = "appgwsubnet-${local.cluster}"
  app_gateway_subnet_address_prefix = "10.0.0.0/16"
}

resource "azurerm_virtual_network" "toolchain" {
  name                = local.virtual_network_name
  location            = azurerm_resource_group.toolchain.location
  resource_group_name = azurerm_resource_group.toolchain.name
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  address_space       = [local.virtual_network_address_prefix]

  tags = local.tags
}

resource "azurerm_subnet" "appgwsubnet" {
  address_prefix       = local.app_gateway_subnet_address_prefix
  name                 = local.app_gateway_subnet_name
  resource_group_name  = azurerm_resource_group.toolchain.name
  virtual_network_name = azurerm_virtual_network.toolchain.name
}

