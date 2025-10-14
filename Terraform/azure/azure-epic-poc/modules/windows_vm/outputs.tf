output "public_ip" { value = azurerm_public_ip.pip.ip_address }
output "vm_id"     { value = azurerm_windows_virtual_machine.vm.id }
