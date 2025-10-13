variable "prefix"            { type = string }
variable "location"          { type = string }
variable "rg_name"           { type = string }
variable "subnet_ingress_id" { type = string }
variable "tags"              { type = map(string) }

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-appgw-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.prefix}-appgw"
  location            = var.location
  resource_group_name = var.rg_name

  sku { name = "WAF_v2" tier = "WAF_v2" }

  gateway_ip_configuration { name = "gwip" subnet_id = var.subnet_ingress_id }

  frontend_port { name = "http" port = 80 }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool { name = "pool" }

  backend_http_settings {
    name                  = "bhs"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    cookie_based_affinity = "Disabled"
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "pool"
    backend_http_settings_name = "bhs"
  }

  tags = var.tags
}

output "public_ip" { value = azurerm_public_ip.pip.ip_address }
