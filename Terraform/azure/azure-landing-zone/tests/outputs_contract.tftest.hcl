// Validates that the module/root exposes a stable set of outputs expected by CI and consumers.
run "outputs_contract" {
  command = plan

  variables = {
    location       = "eastus2"
    org_name       = "ci"
    env            = "test"
    address_spaces = ["10.61.0.0/16"]
    subnets = [
      { name = "ingress", prefixes = ["10.61.0.0/24"] },
      { name = "app",     prefixes = ["10.61.10.0/24"] },
      { name = "data",    prefixes = ["10.61.20.0/24"] }
    ]
    enable_management_groups             = false
    enable_security_policies             = true
    enable_tenant_mfa                    = false
    enable_nsgs                          = true
    create_app_gateway                   = false
    db_engine                            = "none"
    enable_initiative_azure_monitor_vms  = true
    enable_initiative_defender_plans     = false
    policy_required_tags                 = { owner = "platform", env = "test" }
    naming_library                       = { rg = "^[a-z0-9-]{3,64}$", vnet = "^[a-z0-9-]{3,64}$" }
  }

  // Outputs should exist even in plan (types/keys known, values may be unknown)
  assert {
    condition     = can(output.resource_group_names) && can(output.vnet_ids) && can(output.subnet_ids) && can(output.log_analytics_workspace_id)
    error_message = "Expected outputs are missing: resource_group_names, vnet_ids, subnet_ids, log_analytics_workspace_id."
  }
}
