output "resource_group_names" { value = { hub = module.core.rg_hub_name, spoke = module.core.rg_spoke_name } }
output "vnet_ids"             { value = { hub = module.network.hub_vnet_id, spoke = module.network.spoke_vnet_id } }
output "subnet_ids"           { value = module.network.subnet_ids }
output "app_gateway_public_ip"{ value = try(module.ingress[0].public_ip, "") }
output "vmss_name"            { value = module.compute.vmss_name }
output "database_fqdn"        { value = try(module.database[0].fqdn, "") }
output "log_analytics_workspace_id" { value = module.monitor.law_id }
output "management_group_root_id"   { value = try(module.management[0].root_mg_id, "") }
