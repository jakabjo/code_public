variable "prefix" { type = string }
variable "tags"   { type = map(string) }

resource "azurerm_management_group" "platform"   { display_name = "${var.prefix}-platform" }
resource "azurerm_management_group" "landingzones"{ display_name = "${var.prefix}-landingzones" }
resource "azurerm_management_group" "sandbox"    { display_name = "${var.prefix}-sandbox" }

output "root_mg_id" { value = azurerm_management_group.platform.id }
