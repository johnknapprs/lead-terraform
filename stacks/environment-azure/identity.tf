# Managed identity for Kubernetes
resource "azurerm_user_assigned_identity" "cluster_identity" {
  resource_group_name = azurerm_resource_group.toolchain.name
  location            = azurerm_resource_group.toolchain.location
  name                = "${local.cluster}-cluster-identity"
  tags                = local.tags
}

# Allow k8s service principle to manage the agentpool
resource "azurerm_role_assignment" "sp_as_agentpool_contributor" {
  scope                = azurerm_resource_group.toolchain.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.toolchain.id
  depends_on           = [azurerm_user_assigned_identity.cluster_identity]
}

# Allow k8s service principle to use the managed identity
resource "azurerm_role_assignment" "sp_as_identity_operator" {
  scope                = azurerm_user_assigned_identity.cluster_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azuread_service_principal.toolchain.id
  depends_on           = [azurerm_user_assigned_identity.cluster_identity]
}

# Allow managed identity to read the resource group
resource "azurerm_role_assignment" "identity_as_rg_reader" {
  scope                = azurerm_resource_group.toolchain.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.cluster_identity.principal_id
  depends_on           = [
    azurerm_user_assigned_identity.cluster_identity,
    azurerm_resource_group.toolchain,
    azurerm_virtual_network.toolchain,
  ]
}

# Allow principal to modify DNS zone
resource "azurerm_role_assignment" "sp_as_dnszone_contributor" {
  scope                = azurerm_dns_zone.cluster_zone.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.toolchain.id
  depends_on           = [azuread_service_principal.toolchain, azurerm_dns_zone.cluster_zone]
}

