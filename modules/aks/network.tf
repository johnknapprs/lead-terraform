locals {
  aks_subnet_address_prefix = "10.1.0.0/16"
  aks_subnet_name           = "kubesubnet"

  aks_service_cidr       = "10.2.0.0/16"
  aks_dns_service_ip     = "10.2.0.10"
  aks_docker_bridge_cidr = "172.17.0.1/16"
}

data "azurerm_virtual_network" "toolchain" {
  name = var.toolchain_network_name
  resource_group_name = var.toolchain_resource_group
}

resource "azurerm_subnet" "kubesubnet" {
  address_prefix       = local.aks_subnet_address_prefix
  name                 = local.aks_subnet_name
  resource_group_name  = data.azurerm_resource_group.toolchain.name
  virtual_network_name = data.azurerm_virtual_network.toolchain.name
}

