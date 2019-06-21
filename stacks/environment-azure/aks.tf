module "aks_cluster" {
  source = "../../modules/aks"

  # Set variables for module:
  cluster                  = local.cluster
  dns_zone_name            = var.dns_zone_name
  tags                     = local.tags
  dns_zone_resource_group  = var.dns_zone_resource_group
  toolchain_resource_group = azurerm_resource_group.toolchain.name
  azure_client_id          = azuread_application.toolchain.application_id
  azure_client_secret      = azuread_service_principal_password.toolchain.value
  toolchain_network_name   = azurerm_virtual_network.toolchain.name
  toolchain_sp_id          = azuread_service_principal.toolchain.id
}


data "azurerm_kubernetes_cluster" "toolchain" {
  name                = module.aks_cluster.aks_cluster_name
  resource_group_name = local.resource_group
}
