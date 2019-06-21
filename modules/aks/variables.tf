variable "azure_region" {
  description = "Location for Azure resources"
  default = "eastus"
}

variable "contributor_group_name" {
  description = "Existing ActiveDirectory group that will be granted access Contributor access to the resource group"
  default = "LEAD Toolchain Admins"
}

variable "cluster" {
  description = "Name of the cluster"
}

variable "dns_zone_name" {
  description = "DNS zone where aliases should be added"
}

variable "dns_zone_resource_group" {
  description = "Resource group containing the DNS zone"
}

variable "tags" {
  description = "Tags inherited from parent module"
}

variable "aks_agent_count" {
  default = 3
}

variable "aks_agent_vm_size" {
  default = "Standard_DS1_v2"
}

variable "aks_agent_disk_size" {
  default = 30
}

variable "log_analytics_workspace_sku" {
  default = "PerGB2018"
}

variable "toolchain_resource_group" {
  description = "Destination resource group for the cluster"
}

variable "azure_client_id" {}

variable "azure_client_secret" {}

variable "toolchain_sp_id" {}

variable "toolchain_network_name" {}
