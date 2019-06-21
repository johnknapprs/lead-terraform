module "cluster-autoscaler" {
  source = "../../modules/cluster-autoscaler"

  cluster               = local.cluster
  system_namespace      = local.system_namespace
  helm_repo_name        = data.helm_repository.stable.name
  azure_client_id       = local.client_id
  azure_client_secret   = local.client_secret
  azure_cluster_name    = module.aks_cluster.aks_cluster_name
  azure_region          = var.azure_region
  azure_subscription_id = local.subscription_id
  azure_tenant_id       = local.tenant_id
  azure_resource_group  = local.resource_group

}

module "external_dns" {
  source                = "../../modules/external-dns"
  cluster               = local.cluster
  system_namespace      = local.system_namespace
  helm_repo_name        = data.helm_repository.stable.name
  azure_client_id       = local.client_id
  azure_client_secret   = local.client_secret
  azure_subscription_id = local.subscription_id
  azure_tenant_id       = local.tenant_id
  azure_resource_group  = local.resource_group
  cluster_fqdn          = local.cluster_fqdn
}

module "cert_manager" {
  source                = "../../modules/cert-manager"
  cluster               = local.cluster
  system_namespace      = local.system_namespace
  helm_repo_name        = data.helm_repository.cert_manager.name
  azure_client_id       = local.client_id
  azure_client_secret   = local.client_secret
  azure_subscription_id = local.subscription_id
  azure_tenant_id       = local.tenant_id
  azure_resource_group  = local.resource_group
  cluster_fqdn          = local.cluster_fqdn
}

#Identity k8s components
resource "helm_release" "aad-pod-identity" {
  name         = "aad-pod-identity"
  chart        = "aad-pod-identity"
  version      = "0.1.1"
  repository   = data.helm_repository.liatrio.name
  force_update = true
  namespace    = var.system_namespace

  set {
    name  = "rbac.enabled"
    value = "true"
  }
  set {
    name  = "azureIdentity.enabled"
    value = "false"
  }

  depends_on = [
    kubernetes_role_binding.lead_tiller,
    azurerm_role_assignment.identity_as_rg_reader,
    kubernetes_cluster_role_binding.lead_tiller]
}

# Kubernetes namespace for cluster-wide system components
resource "kubernetes_namespace" "lead_system" {
  metadata {
    annotations = {
      name      = var.system_namespace
      api_group = "rbac.authorization.k8s.io"
    }

    name = var.system_namespace
  }
}

# Make a service account for tiller in system namespace
resource "kubernetes_service_account" "lead_tiller" {
  metadata {
    name      = "lead-tiller"
    namespace = kubernetes_namespace.lead_system.metadata[0].name
  }
  automount_service_account_token = true
}

# Make a role for tiller to use
resource "kubernetes_role" "lead_tiller" {
  metadata {
    name = "lead-tiller"
  }
  rule {
    api_groups = ["", "batch", "extensions", "apps"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

# Make a cluster role that lets tiller manage CRDs
resource "kubernetes_cluster_role" "lead_tiller" {
  metadata {
    name = "lead-tiller"
  }
  rule {
    api_groups = ["*"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["*"]
  }
}

# Give tiller access to manage CRDs
resource "kubernetes_cluster_role_binding" "lead_tiller" {
  metadata {
    name = "tiller-crd-manager-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
    # TODO: reduce access
    # name = kubernetes_cluster_role.lead_tiller.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.lead_tiller.metadata[0].name
    namespace = kubernetes_namespace.lead_system.metadata[0].name
  }
}

# Give tiller access to manage its namespace
resource "kubernetes_role_binding" "lead_tiller" {
  metadata {
    name      = "tiller-binding"
    namespace = kubernetes_namespace.lead_system.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.lead_tiller.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.lead_tiller.metadata[0].name
    namespace = kubernetes_namespace.lead_system.metadata[0].name
  }
}

