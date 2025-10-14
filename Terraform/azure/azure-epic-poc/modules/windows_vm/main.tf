resource "azurerm_public_ip" "pip" {
  name                = "${var.name_prefix}-win-pip"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.name_prefix}-win-nic"
  resource_group_name = var.rg_name
  location            = var.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${var.name_prefix}-win"
  resource_group_name = var.rg_name
  location            = var.location
  size                = var.size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]
  enable_automatic_updates = true
  patch_mode               = "AutomaticByOS"

  os_disk {
    name                 = "${var.name_prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  additional_capabilities {
    ultra_ssd_enabled = var.enable_ultra_disk
  }

  tags = var.tags
}

resource "azurerm_managed_disk" "data" {
  for_each            = { for d in var.data_disks : d.lun => d }
  name                = "${var.name_prefix}-datadisk-${each.key}"
  location            = var.location
  resource_group_name = var.rg_name
  storage_account_type = each.value.sku
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  for_each           = azurerm_managed_disk.data
  managed_disk_id    = each.value.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = tonumber(each.key)
  caching            = "ReadOnly"
}

resource "azurerm_monitor_diagnostic_setting" "vm_diag" {
  name                       = "${var.name_prefix}-vm-diag"
  target_resource_id         = azurerm_windows_virtual_machine.vm.id
  log_analytics_workspace_id = var.log_analytics_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
