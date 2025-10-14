resource "azurerm_public_ip" "gw_pip" {
  name                = "${var.name_prefix}-gw-pip"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "vngw" {
  name                = "${var.name_prefix}-vngw"
  resource_group_name = var.rg_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.sku
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "gwipconfig1"
    subnet_id                     = var.gw_subnet_id
    public_ip_address_id          = azurerm_public_ip.gw_pip.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}
