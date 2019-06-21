//output "host" {
// value = data.azurerm_kubernetes_cluster.toolchain.kube_config[0].host
//}
//
//output "client_key" {
// value = base64decode(data.azurerm_kubernetes_cluster.toolchain.kube_config[0].client_key)
//}
//output "cluster_ca_certificate" {
// value = base64decode(data.azurerm_kubernetes_cluster.toolchain.kube_config[0].cluster_ca_certificate)
//}
//
//output "client_certificate" {
// value = base64decode(data.azurerm_kubernetes_cluster.toolchain.kube_config[0].client_certificate)
//}

//output "aks_config_raw" {
//  value = module.aks_cluster.aks_config_raw
//}
