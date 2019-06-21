data "azurerm_resource_group" "toolchain" {
  name = var.toolchain_resource_group
}

# Allow k8s service principle to modify the Kubernetes subnet
resource "azurerm_role_assignment" "sp_as_subnet_contrib" {
  scope                = azurerm_kubernetes_cluster.toolchain.id
  role_definition_name = "Network Contributor"
  principal_id         = var.toolchain_sp_id
}
