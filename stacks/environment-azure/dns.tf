#Root zone
data "azurerm_dns_zone" "root_zone" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group
}

#DNS Zone for external-dns to manage
resource "azurerm_dns_zone" "cluster_zone" {
  name                = local.cluster_fqdn
  resource_group_name = local.resource_group
  zone_type           = "Public"
  tags                = local.tags
}

#NS record from root DNS zone
resource "azurerm_dns_ns_record" "ns_zone" {
  name                = local.cluster_domain
  resource_group_name = var.dns_zone_resource_group
  ttl                 = 300
  zone_name           = data.azurerm_dns_zone.root_zone.name
  records             = azurerm_dns_zone.cluster_zone.name_servers
}

