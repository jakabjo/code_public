variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "rules" {
  type = list(object({
    name                       : string
    priority                   : number
    direction                  : string # Inbound/Outbound
    access                     : string # Allow/Deny
    protocol                   : string # Tcp/Udp/Asterisk
    source_port_range          : string
    destination_port_range     : string
    source_address_prefix      : string
    destination_address_prefix : string
  }))
  default = []
}
variable "associate_subnet_id" {
  type        = string
  default     = null
  description = "Optional subnet ID to associate NSG"
}
variable "tags" { type = map(string) default = {} }
