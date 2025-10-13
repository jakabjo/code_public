provider "azurerm" {
  features {}
}
variable "location" {
  type        = string
  description = "Azure location"
  default     = "westus2"
}
