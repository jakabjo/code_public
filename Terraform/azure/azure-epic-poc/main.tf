locals {
  rg_core_name  = "${var.name_prefix}-rg-core"
  rg_data_name  = "${var.name_prefix}-rg-data"
  rg_sec_name   = "${var.name_prefix}-rg-sec"
  rg_net_name   = "${var.name_prefix}-rg-net"
  rg_logs_name  = "${var.name_prefix}-rg-logs"
}

module "rg_core" {
  source      = "./modules/resource_group"
  name        = local.rg_core_name
  location    = var.location
  tags        = var.tags
}

module "rg_net" {
  source      = "./modules/resource_group"
  name        = local.rg_net_name
  location    = var.location
  tags        = var.tags
}

module "rg_data" {
  source      = "./modules/resource_group"
  name        = local.rg_data_name
  location    = var.location
  tags        = var.tags
}

module "rg_sec" {
  source      = "./modules/resource_group"
  name        = local.rg_sec_name
  location    = var.location
  tags        = var.tags
}

module "rg_logs" {
  source      = "./modules/resource_group"
  name        = local.rg_logs_name
  location    = var.location
  tags        = var.tags
}

module "log_analytics" {
  source           = "./modules/log_analytics"
  rg_name          = module.rg_logs.name
  location         = var.location
  name_prefix      = var.name_prefix
  retention_in_days = 60
  tags             = var.tags
}

module "kv" {
  source      = "./modules/key_vault"
  rg_name     = module.rg_sec.name
  location    = var.location
  name_prefix = var.name_prefix
  tags        = var.tags
  # Optionally supply tenant or access policies here
}

module "network" {
  source          = "./modules/network"
  rg_name         = module.rg_net.name
  location        = var.location
  name_prefix     = var.name_prefix
  address_space   = var.address_space
  subnets         = var.subnets
  enable_ddos_std = false
  tags            = var.tags
}

module "private_dns" {
  source       = "./modules/private_dns"
  rg_name      = module.rg_net.name
  name_prefix  = var.name_prefix
  vnet_id      = module.network.vnet_id
  zones        = [
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.vaultcore.azure.net"
  ]
  tags         = var.tags
}

module "storage" {
  source                = "./modules/storage_account"
  rg_name               = module.rg_data.name
  location              = var.location
  name_prefix           = var.name_prefix
  vnet_subnet_id        = module.network.subnet_ids["data"]
  private_dns_zone_ids  = module.private_dns.zone_ids
  allow_blob_public     = false
  min_tls               = "TLS1_2"
  tags                  = var.tags
}

module "defender" {
  source         = "./modules/defender_baseline"
  rg_names       = [module.rg_core.name, module.rg_data.name, module.rg_net.name, module.rg_sec.name, module.rg_logs.name]
  enable_plan_vm = true
  enable_plan_sql = false
}

module "policy" {
  source         = "./modules/policy_baseline"
  assignment_scope_rg_ids = [
    module.rg_core.id,
    module.rg_data.id,
    module.rg_net.id,
    module.rg_sec.id,
    module.rg_logs.id
  ]
  tags_required = ["workload", "owner", "env"]
}

module "win_vm_iris" {
  source            = "./modules/windows_vm"
  rg_name           = module.rg_core.name
  location          = var.location
  name_prefix       = var.name_prefix
  subnet_id         = module.network.subnet_ids["app"]
  admin_username    = var.admin_username
  admin_password    = var.admin_password
  size              = var.vm_size
  enable_ultra_disk = var.vm_ultra_disk
  data_disks        = var.vm_data_disks
  log_analytics_id  = module.log_analytics.workspace_id
  tags              = merge(var.tags, { role = "iris-test" })
}

module "vpn" {
  source        = "./modules/vpn_gateway_optional"
  count         = var.enable_vpn ? 1 : 0
  rg_name       = module.rg_net.name
  location      = var.location
  name_prefix   = var.name_prefix
  vnet_id       = module.network.vnet_id
  gw_subnet_id  = module.network.subnet_ids["gw"]
  sku           = "VpnGw2"
  tags          = var.tags
}
