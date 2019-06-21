locals {
  aks_dns_prefix   = "toolchain-${var.cluster}"
  aks_cluster_name = "cluster-${var.cluster}"
}

resource "random_id" "workspace" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = data.azurerm_resource_group.toolchain.name
  }
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "client_toolchain" {
  name                = "k8s-workspace-${var.cluster}-${random_id.workspace.hex}"
  location            = data.azurerm_resource_group.toolchain.location
  resource_group_name = data.azurerm_resource_group.toolchain.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "client_toolchain" {
  solution_name         = "ContainerInsights"
  location              = data.azurerm_resource_group.toolchain.location
  resource_group_name   = data.azurerm_resource_group.toolchain.name
  workspace_resource_id = azurerm_log_analytics_workspace.client_toolchain.id
  workspace_name        = azurerm_log_analytics_workspace.client_toolchain.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

#Cluster creation
resource "azurerm_kubernetes_cluster" "toolchain" {
  name                = local.aks_cluster_name
  location            = data.azurerm_resource_group.toolchain.location
  resource_group_name = data.azurerm_resource_group.toolchain.name
  dns_prefix          = local.aks_dns_prefix

  role_based_access_control {
    enabled = true
  }
  agent_pool_profile {
    name            = "agentpool"
    count           = var.aks_agent_count
    vm_size         = var.aks_agent_vm_size
    os_type         = "Linux"
    os_disk_size_gb = var.aks_agent_disk_size
    vnet_subnet_id  = azurerm_subnet.kubesubnet.id
  }
  service_principal {
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
  }
  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = local.aks_dns_service_ip
    docker_bridge_cidr = local.aks_docker_bridge_cidr
    service_cidr       = local.aks_service_cidr
  }
  addon_profile {
    http_application_routing {
      enabled = false
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.client_toolchain.id
    }
  }
  tags = local.tags
}




