output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.toolchain.name
}

output "aks_subnet_id" {
  value = azurerm_subnet.kubesubnet.id
}

output "aks_config_raw" {
  value = azurerm_kubernetes_cluster.toolchain.kube_config_raw
}
