variable "prefix"               { type = string }
variable "location"             { type = string }
variable "rg_name"              { type = string }
variable "subnet_id"            { type = string }
variable "instance_count"       { type = number }
variable "user_data_cloud_init" { type = string }
variable "tags"                 { type = map(string) }

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "${var.prefix}-vmss"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard_B2s"
  instances           = var.instance_count
  admin_username      = "azureuser"
  upgrade_mode        = "Automatic"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk { storage_account_type = "Standard_LRS" caching = "ReadWrite" }

  network_interface {
    name    = "vmssnic"
    primary = true
    ip_configuration { name = "internal" primary = true subnet_id = var.subnet_id }
  }

  custom_data = base64encode(var.user_data_cloud_init)

  identity { type = "SystemAssigned" }
  tags = var.tags
}

output "vmss_name" { value = azurerm_linux_virtual_machine_scale_set.vmss.name }
