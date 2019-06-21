variable "azure_region" {
  description = "Location for Azure resources"
  default     = "eastus"
}

variable "contributor_group_name" {
  description = "Existing ActiveDirectory group that will be granted access Contributor access to the resource group"
  default     = "LEAD Toolchain Admins"
}

variable "cluster" {
  description = "Name of the cluster"
}

variable "dns_zone_name" {
  description = "DNS zone where aliases should be added"
  default     = "az.liatr.io"
}

variable "dns_zone_resource_group" {
  description = "Resource group containing the DNS zone"
  default     = "liatrio-core"
}

variable "system_namespace" {
  description = "Namespace for cluster administration tools"
  default     = "lead-system"
}
