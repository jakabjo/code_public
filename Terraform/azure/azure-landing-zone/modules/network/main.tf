variable "prefix"          { type = string }
variable "location"        { type = string }
variable "rg_hub_name"     { type = string }
variable "rg_spoke_name"   { type = string }
variable "address_spaces"  { type = object({ hub=string, spoke=string }) }
variable "subnets" {
  type = object({
    hub = object({ firewall=string, shared=string, azurebastion=string })
    spoke = object({ ingress=string, app=string, data=string, private=string })
  })
}
variable "tags"            { type = map(string) }

resource "azurerm_virtual_network" "hub" {
  name                = "${var.prefix}-hub-vnet"
  location            = var.location
  resource_group_name = var.rg_hub_name
  address_space       = [var.address_spaces.hub]
  tags                = var.tags
}

resource "azurerm_subnet" "fw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.rg_hub_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnets.hub.firewall]
}

resource "azurerm_subnet" "shared" {
  name                 = "shared"
  resource_group_name  = var.rg_hub_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnets.hub.shared]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.rg_hub_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnets.hub.azurebastion]
}

resource "azurerm_virtual_network" "spoke" {
  name                = "${var.prefix}-spoke-vnet"
  location            = var.location
  resource_group_name = var.rg_spoke_name
  address_space       = [var.address_spaces.spoke]
  tags                = var.tags
}

resource "azurerm_subnet" "ingress" {
  name                 = "ingress"
  resource_group_name  = var.rg_spoke_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnets.spoke.ingress]
}

resource "azurerm_subnet" "app" {
  name                 = "app"
  resource_group_name  = var.rg_spoke_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnets.spoke.app]
}

resource "azurerm_subnet" "data" {
  name                 = "data"
  resource_group_name  = var.rg_spoke_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnets.spoke.data]
}

resource "azurerm_subnet" "private" {
  name                 = "private"
  resource_group_name  = var.rg_spoke_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnets.spoke.private]
}

resource "azurerm_public_ip" "nat" {
  name                = "${var.prefix}-nat-pip"
  location            = var.location
  resource_group_name = var.rg_spoke_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "ng" {
  name                = "${var.prefix}-natgw"
  location            = var.location
  resource_group_name = var.rg_spoke_name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "ng_pip" {
  nat_gateway_id       = azurerm_nat_gateway.ng.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "ng_app" {
  subnet_id      = azurerm_subnet.app.id
  nat_gateway_id = azurerm_nat_gateway.ng.id
}
resource "azurerm_subnet_nat_gateway_association" "ng_private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.ng.id
}

output "hub_vnet_id"   { value = azurerm_virtual_network.hub.id }
output "spoke_vnet_id" { value = azurerm_virtual_network.spoke.id }
output "subnet_ids" {
  value = {
    hub = { firewall = azurerm_subnet.fw.id, shared = azurerm_subnet.shared.id, bastion = azurerm_subnet.bastion.id }
    spoke = { ingress = azurerm_subnet.ingress.id, app = azurerm_subnet.app.id, data = azurerm_subnet.data.id, private = azurerm_subnet.private.id }
  }
}
