locals {
  prefix = "${var.org_name}-${var.env}"
}

# --- Management Groups ---
module "management" {
  count  = var.enable_management_groups ? 1 : 0
  source = "./modules/management"
  prefix = local.prefix
  tags   = var.tags
}

# --- Security (Policies & Initiatives at MG scope) ---
module "security" {
  count                               = var.enable_security_policies && var.enable_management_groups ? 1 : 0
  source                              = "./modules/security"
  management_group_id                 = try(module.management[0].root_mg_id, null)

  # custom policies
  allowed_locations                   = var.policy_allowed_locations
  required_tags                       = var.policy_required_tags

  # naming library: per-resource-type regex (map)
  naming_library                      = var.naming_library

  # built-in initiatives toggles
  enable_initiative_azure_monitor_vms = var.enable_initiative_azure_monitor_vms
  enable_initiative_defender_plans    = var.enable_initiative_defender_plans
}

# --- Core ---
module "core" {
  source   = "./modules/core"
  prefix   = local.prefix
  location = var.location
  tags     = var.tags
}

# --- Network ---
module "network" {
  source          = "./modules/network"
  prefix          = local.prefix
  location        = var.location
  rg_hub_name     = module.core.rg_hub_name
  rg_spoke_name   = module.core.rg_spoke_name
  address_spaces  = var.address_spaces
  subnets         = var.subnets
  tags            = var.tags
}

# --- Monitor ---
module "monitor" {
  source    = "./modules/monitor"
  prefix    = local.prefix
  location  = var.location
  rg_name   = module.core.rg_hub_name
  target_ids = [
    module.network.hub_vnet_id,
    module.network.spoke_vnet_id
  ]
  tags = var.tags
}

# --- Storage ---
module "storage" {
  source   = "./modules/storage"
  prefix   = local.prefix
  location = var.location
  rg_name  = module.core.rg_spoke_name
  tags     = var.tags
}

# --- Ingress (App Gateway) ---
module "ingress" {
  count              = var.create_app_gateway ? 1 : 0
  source             = "./modules/ingress"
  prefix             = local.prefix
  location           = var.location
  rg_name            = module.core.rg_spoke_name
  subnet_ingress_id  = module.network.subnet_ids.spoke.ingress
  tags               = var.tags
}

# --- Compute (VMSS) ---
module "compute" {
  source               = "./modules/compute"
  prefix               = local.prefix
  location             = var.location
  rg_name              = module.core.rg_spoke_name
  subnet_id            = module.network.subnet_ids.spoke.app
  instance_count       = var.vmss_instance_count
  user_data_cloud_init = <<-CLOUDINIT
    #cloud-config
    packages:
      - nginx
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
  CLOUDINIT
  tags                 = var.tags
}

# --- Database (PG Flexible) ---
module "database" {
  count     = var.db_engine == "pg" ? 1 : 0
  source    = "./modules/database"
  prefix    = local.prefix
  location  = var.location
  rg_name   = module.core.rg_spoke_name
  subnet_id = module.network.subnet_ids.spoke.data
  tags      = var.tags
}

# --- Identity (Conditional Access MFA) ---
module "identity" {
  count                        = var.enable_tenant_mfa ? 1 : 0
  source                       = "./modules/identity"
  mfa_excluded_user_object_ids = var.mfa_excluded_user_object_ids
  include_guests               = var.mfa_include_guest_users
}

# --- NSGs ---
module "nsg" {
  count                = var.enable_nsgs ? 1 : 0
  source               = "./modules/nsg"
  prefix               = local.prefix
  location             = var.location
  rg_name              = module.core.rg_spoke_name
  subnet_ids           = module.network.subnet_ids.spoke
  office_cidrs         = var.office_cidrs
  extra_rules_per_snet = var.nsg_extra_rules
  tags                 = var.tags
}
