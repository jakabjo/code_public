locals {
  name = "demo"
  location = var.location
  tags = { Project = "azure-tf-snippets", Env = "dev" }
}

variable "location" { type = string default = "westus2" }

module "rg" {
  source   = "../../modules/rg"
  name     = "rg-${local.name}"
  location = local.location
  tags     = local.tags
}

module "vnet" {
  source              = "../../modules/vnet-basic"
  name                = "vnet-${local.name}"
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = ["10.60.0.0/16"]
  subnets = [
    { name = "public",  address_prefix = "10.60.0.0/24" },
    { name = "private", address_prefix = "10.60.1.0/24" }
  ]
  tags = local.tags
}

output "vnet_id" { value = module.vnet.vnet_id }
output "subnet_ids" { value = module.vnet.subnet_ids }
