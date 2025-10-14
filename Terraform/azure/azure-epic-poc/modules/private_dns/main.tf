resource "azurerm_private_dns_zone" "zone" {
  for_each            = toset(var.zones)
  name                = each.value
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  for_each              = azurerm_private_dns_zone.zone
  name                  = "${var.name_prefix}-link-${replace(each.value.name, ".", "-")}"
  resource_group_name   = var.rg_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}
