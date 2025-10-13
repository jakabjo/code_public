locals {
  name = "demo"
  tags = { Project = "azure-tf-snippets", Env = "dev" }
}

variable "location" { type = string default = "westus2" }
variable "admin_username" { type = string default = "azureuser" }
variable "ssh_public_key" { type = string description = "Your SSH public key" }

module "rg" {
  source   = "../../modules/rg"
  name     = "rg-${local.name}"
  location = var.location
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

module "bastion" {
  source              = "../../modules/linux-vm-bastion"
  name                = local.name
  resource_group_name = module.rg.name
  location            = module.rg.location
  subnet_id           = module.vnet.subnet_ids["public"]
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  tags                = local.tags
}

output "bastion_public_ip" { value = module.bastion.public_ip }
