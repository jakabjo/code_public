variable "management_group_id" { type = string }

variable "allowed_locations" { type = list(string) }
variable "required_tags"     { type = map(string) }

# Naming library: map(resourceType => regex)
variable "naming_library"    { type = map(string) }

# Built-in initiatives toggles
variable "enable_initiative_azure_monitor_vms" { type = bool }
variable "enable_initiative_defender_plans"    { type = bool }

# ---------- Custom Policy: Allowed Locations ----------
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "custom-allowed-locations"
  display_name = "Allowed locations (custom)"
  mode         = "All"
  policy_rule  = jsonencode({
    if   = { not = { field = "location", in = "[parameters('listOfAllowedLocations')]" } }
    then = { effect = "Deny" }
  })
  parameters = jsonencode({
    listOfAllowedLocations = {
      type = "Array"
      metadata = { description = "Locations where resources can be deployed." }
      defaultValue = []
    }
  })
}

resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations-assignment"
  display_name         = "Allowed locations"
  scope                = var.management_group_id
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  parameters           = jsonencode({ listOfAllowedLocations = { value = var.allowed_locations } })
  identity { type = "SystemAssigned" }
}

# ---------- Custom Policy: Required Tags (Deny if missing) ----------
resource "azurerm_policy_definition" "required_tags" {
  name         = "custom-required-tags"
  display_name = "Required tags on resources (custom)"
  mode         = "Indexed"
  policy_rule  = jsonencode({
    if = {
      anyOf = [
        for tagKey in keys(parameters('tagDefaults').value) : {
          not = { field = "[concat('tags[', tagKey, ']')]", exists = true }
        }
      ]
    }
    then = { effect = "Deny" }
  })
  parameters = jsonencode({
    tagDefaults = {
      type = "Object"
      metadata = { description = "Map of required tag keys to default values." }
      defaultValue = {}
    }
  })
}

resource "azurerm_policy_assignment" "required_tags" {
  name                 = "required-tags-assignment"
  display_name         = "Required tags on resources"
  scope                = var.management_group_id
  policy_definition_id = azurerm_policy_definition.required_tags.id
  parameters           = jsonencode({ tagDefaults = { value = var.required_tags } })
  identity { type = "SystemAssigned" }
}

# ---------- Custom Policy: Append Default Tags (Modify) ----------
resource "azurerm_policy_definition" "append_tags" {
  name         = "custom-append-tags"
  display_name = "Append default tags (custom)"
  mode         = "Indexed"
  policy_rule  = jsonencode({
    if   = { field = "type", notEquals = "Microsoft.Resources/subscriptions/resourceGroups" }
    then = {
      effect = "modify"
      details = {
        roleDefinitionIds = [
          "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" # Contributor
        ]
        operations = [
          for tagKey in keys(parameters('tagDefaults').value) : {
            operation = "addOrReplace"
            field     = "[concat('tags[', tagKey, ']')]"
            value     = "[parameters('tagDefaults')[tagKey]]"
          }
        ]
      }
    }
  })
  parameters = jsonencode({
    tagDefaults = {
      type = "Object"
      metadata = { description = "Map of tag keys to default values." }
      defaultValue = {}
    }
  })
}

resource "azurerm_policy_assignment" "append_tags" {
  name                 = "append-tags-assignment"
  display_name         = "Append default tags"
  scope                = var.management_group_id
  policy_definition_id = azurerm_policy_definition.append_tags.id
  parameters           = jsonencode({ tagDefaults = { value = var.required_tags } })
  identity { type = "SystemAssigned" }
}

# ---------- Custom Policy Definition: Naming by Resource Type ----------
resource "azurerm_policy_definition" "naming_single" {
  name         = "custom-naming-convention-by-type"
  display_name = "Naming convention by resource type (regex)"
  mode         = "All"
  policy_rule  = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "[parameters('resourceType')]" },
        { field = "name", exists = true },
        { not = { value = "[parameters('nameRegex')]", matches = { field = "name" } } }
      ]
    }
    then = { effect = "Deny" }
  })
  parameters = jsonencode({
    resourceType = { type = "String", metadata = { description = "Target Azure resource type" } }
    nameRegex    = { type = "String", metadata = { description = "Regex to validate resource name" } }
  })
}

# Create one assignment per (resourceType, regex) entry
locals {
  naming_kv = var.naming_library
}

resource "azurerm_policy_assignment" "naming_each" {
  for_each            = local.naming_kv
  name                = "naming-${replace(each.key, '/', '-')}"  # safe name
  display_name        = "Naming convention: ${each.key}"
  scope               = var.management_group_id
  policy_definition_id= azurerm_policy_definition.naming_single.id
  parameters          = jsonencode({
    resourceType = { value = each.key }
    nameRegex    = { value = each.value }
  })
  identity { type = "SystemAssigned" }
}

# ---------- Built-in Initiatives (data lookups by display_name) ----------
# Note: display_name matching depends on provider capabilities; adjust to 'name' if needed.

# Azure Monitor for VMs
data "azurerm_policy_set_definition" "monitor_vms" {
  count        = var.enable_initiative_azure_monitor_vms ? 1 : 0
  display_name = "Enable Azure Monitor for VMs"
}

resource "azurerm_policy_assignment" "monitor_vms" {
  count                = var.enable_initiative_azure_monitor_vms ? 1 : 0
  name                 = "initiative-azure-monitor-vms"
  display_name         = "Initiative: Enable Azure Monitor for VMs"
  scope                = var.management_group_id
  policy_definition_id = data.azurerm_policy_set_definition.monitor_vms[0].id
  identity { type = "SystemAssigned" }
}

# Microsoft Defender for Cloud (built-in plans)
data "azurerm_policy_set_definition" "defender" {
  count        = var.enable_initiative_defender_plans ? 1 : 0
  display_name = "Configure Microsoft Defender for Cloud plans"
}

resource "azurerm_policy_assignment" "defender" {
  count                = var.enable_initiative_defender_plans ? 1 : 0
  name                 = "initiative-defender-plans"
  display_name         = "Initiative: Configure Defender for Cloud plans"
  scope                = var.management_group_id
  policy_definition_id = data.azurerm_policy_set_definition.defender[0].id
  identity { type = "SystemAssigned" }
}
