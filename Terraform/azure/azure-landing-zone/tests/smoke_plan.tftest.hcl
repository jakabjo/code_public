// Terraform >= 1.6
// Plan-only “smoke” test that validates core invariants without applying.
run "smoke_plan" {
  command = plan

  // Fast, self-contained inputs for CI. Adjust to match your module/root vars.
  variables = {
    location                           = "eastus2"
    org_name                           = "ci"
    env                                = "test"
    address_spaces                     = ["10.60.0.0/16"]
    subnets = [
      { name = "ingress", prefixes = ["10.60.0.0/24"] },
      { name = "app",     prefixes = ["10.60.10.0/24"] },
      { name = "data",    prefixes = ["10.60.20.0/24"] }
    ]

    // Keep heavy/slow bits off in CI unless your config requires them
    enable_management_groups             = false
    enable_security_policies             = true
    enable_tenant_mfa                    = false
    enable_nsgs                          = true
    create_app_gateway                   = false
    db_engine                            = "none"
    enable_initiative_azure_monitor_vms  = true
    enable_initiative_defender_plans     = false

    policy_required_tags = { owner = "platform", env = "test" }
    naming_library       = { rg = "^[a-z0-9-]{3,64}$", vnet = "^[a-z0-9-]{3,64}$" }
  }

  // ---------- Assertions ----------
  // Note: In plan-mode, any value that is computed at apply-time will be unknown.
  // These checks focus on structural presence and constant expressions.

  // Resource Group must exist and meet naming rules (lowercase, no spaces)
  assert {
    condition     = can(azurerm_resource_group.core.name) && !regex("[A-Z]|\\s", azurerm_resource_group.core.name)
    error_message = "Core resource group must exist and be lowercase with no spaces."
  }

  // Hub VNet must be declared
  assert {
    condition     = can(azurerm_virtual_network.hub.id)
    error_message = "Hub virtual network is not planned."
  }

  // Expect at least three subnets (ingress/app/data)
  assert {
    condition     = length(azurerm_subnet.s) >= 3
    error_message = "Expected >= 3 subnets (ingress/app/data)."
  }

  // Log Analytics workspace should be present for monitoring
  assert {
    condition     = can(azurerm_log_analytics_workspace.law.id)
    error_message = "Log Analytics workspace not found in plan."
  }

  // If NSGs are enabled, baseline NSG must exist
  assert {
    condition     = var.enable_nsgs ? can(azurerm_network_security_group.baseline.id) : true
    error_message = "NSG baseline expected but not planned."
  }
}
