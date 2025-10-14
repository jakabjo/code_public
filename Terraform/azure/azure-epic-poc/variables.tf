variable "subscription_id" { type = string }
variable "tenant_id"       { type = string }

variable "location" {
  type        = string
  description = "Azure region for the POC"
  default     = "eastus2"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "cc-epic-poc"
}

variable "tags" {
  type        = map(string)
  default     = {
    workload = "epic-poc"
    owner    = "cloud-team"
    env      = "dev"
  }
}

variable "address_space" {
  type        = list(string)
  default     = ["10.60.0.0/16"]
}

variable "subnets" {
  description = "Subnet map name => cidr"
  type = map(object({
    address_prefixes = list(string)
    nsg_rules        = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  default = {
    core      = { address_prefixes = ["10.60.1.0/24"] }
    app       = { address_prefixes = ["10.60.10.0/24"] }
    data      = { address_prefixes = ["10.60.20.0/24"] }
    mgmt      = { address_prefixes = ["10.60.250.0/24"] }
    gw        = { address_prefixes = ["10.60.254.0/27"] }
  }
}

variable "enable_vpn" {
  type        = bool
  default     = false
}

variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}

variable "vm_size" {
  type        = string
  description = "Windows VM size for IRIS testing"
  default     = "Standard_D8s_v5"
}

variable "vm_ultra_disk" {
  type        = bool
  default     = true
}

variable "vm_data_disks" {
  description = "Data disks for database or IO testing"
  type = list(object({
    size_gb = number
    sku     = string
    lun     = number
  }))
  default = [
    { size_gb = 512, sku = "Premium_LRS", lun = 0 },
    { size_gb = 512, sku = "Premium_LRS", lun = 1 }
  ]
}
