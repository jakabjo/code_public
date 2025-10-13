variable "prefix" {}
variable "location" {}
variable "rg_name" {}
variable "tags" {}
variable "subnet_ids" {}
variable "office_cidrs" {}
variable "extra_rules_per_snet" {}

locals {
  ingress_name = "${var.prefix}-ingress-nsg"
  app_name     = "${var.prefix}-app-nsg"
  data_name    = "${var.prefix}-data-nsg"
  private_name = "${var.prefix}-private-nsg"
}

resource "azurerm_network_security_group" "ingress" {
  name                = local.ingress_name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  security_rule {
    name                       = "allow-http-from-internet"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https-from-internet"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.extra_rules_per_snet.ingress
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "ingress_assoc" {
  subnet_id                 = var.subnet_ids.ingress
  network_security_group_id = azurerm_network_security_group.ingress.id
}

resource "azurerm_network_security_group" "app" {
  name                = local.app_name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  security_rule {
    name                       = "allow-80-from-virtualnetwork"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-443-from-virtualnetwork"
    priority                   = 1110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = toset(var.office_cidrs)
    content {
      name                       = "allow-ssh-from-office-${replace(security_rule.value, "/", "_")}"
      priority                   = 1200 + index(tolist(toset(var.office_cidrs)), security_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.extra_rules_per_snet.app
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = var.subnet_ids.app
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_network_security_group" "data" {
  name                = local.data_name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  security_rule {
    name                       = "allow-pg-from-virtualnetwork"
    priority                   = 1300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.extra_rules_per_snet.data
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "data_assoc" {
  subnet_id                 = var.subnet_ids.data
  network_security_group_id = azurerm_network_security_group.data.id
}

resource "azurerm_network_security_group" "private" {
  name                = local.private_name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  # No inbound rules by default

  dynamic "security_rule" {
    for_each = var.extra_rules_per_snet.private
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "private_assoc" {
  subnet_id                 = var.subnet_ids.private
  network_security_group_id = azurerm_network_security_group.private.id
}
