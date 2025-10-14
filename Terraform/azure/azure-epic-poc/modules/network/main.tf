# Optional DDOS plan, created only when enabled
resource "azurerm_network_ddos_protection_plan" "ddos" {
  for_each            = var.enable_ddos_std ? { plan = true } : {}
  name                = "${var.name_prefix}-ddos"
  resource_group_name = var.rg_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  resource_group_name = var.rg_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags

  # Attach DDOS plan only when one exists
  dynamic "ddos_protection_plan" {
    for_each = azurerm_network_ddos_protection_plan.ddos
    content {
      id = ddos_protection_plan.value.id
    }
  }
}

resource "azurerm_subnet" "sn" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_network_security_group" "nsg" {
  for_each            = var.subnets
  name                = "${var.name_prefix}-nsg-${each.key}"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.sn[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}
