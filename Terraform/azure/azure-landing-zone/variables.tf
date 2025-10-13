########################################
# SINGLE PLACE TO CUSTOMIZE PER DEPLOY #
########################################

variable "subscription_id" {
  description = "Optional override of ARM_SUBSCRIPTION_ID. Prefer env var."
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "Optional override of ARM_TENANT_ID. Prefer env var."
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region. ### EDIT ME per region"
  type        = string
  default     = "eastus2"
}

variable "org_name" {
  description = "Short org/project code. ### EDIT ME per customer"
  type        = string
  default     = "acme"
}

variable "env" {
  description = "Environment short name. ### EDIT ME (dev/test/prod)"
  type        = string
  default     = "dev"
}

variable "address_spaces" {
  description = "Hub/Spoke CIDRs. ### EDIT ME once per tenant"
  type = object({ hub=string, spoke=string })
  default = { hub="10.0.0.0/16", spoke="10.1.0.0/16" }
}

variable "subnets" {
  description = "Subnet CIDRs per VNet. ### EDIT ME once per tenant"
  type = object({
    hub = object({
      firewall     = string
      shared       = string
      azurebastion = string
    })
    spoke = object({
      ingress = string
      app     = string
      data    = string
      private = string
    })
  })
  default = {
    hub = {
      firewall     = "10.0.0.0/26"
      shared       = "10.0.1.0/24"
      azurebastion = "10.0.2.0/27"
    }
    spoke = {
      ingress = "10.1.0.0/24"
      app     = "10.1.16.0/20"
      data    = "10.1.32.0/20"
      private = "10.1.48.0/24"
    }
  }
}

# Feature toggles
variable "enable_management_groups" {
  description = "Deploy management group hierarchy."
  type        = bool
  default     = true
}

variable "enable_security_policies" {
  description = "Deploy Azure Policy at MG scope (naming, tagging, allowed locations, initiatives)."
  type        = bool
  default     = true
}

variable "enable_tenant_mfa" {
  description = "Create Entra Conditional Access policy to require MFA (with exclusions)."
  type        = bool
  default     = false
}

variable "create_app_gateway" {
  description = "Deploy Application Gateway (WAF_v2)."
  type        = bool
  default     = true
}

variable "db_engine" {
  description = "Database: 'pg' (PostgreSQL Flex) or 'none'."
  type        = string
  default     = "pg"
  validation {
    condition     = contains(["pg", "none"], var.db_engine)
    error_message = "db_engine must be 'pg' or 'none'."
  }
}

variable "vmss_instance_count" {
  description = "Initial VMSS capacity."
  type        = number
  default     = 2
}

# Security policy parameters (custom policies)
variable "policy_allowed_locations" {
  description = "Allowed Azure regions (MG policy)."
  type        = list(string)
  default     = ["eastus2", "centralus"]
}

variable "policy_required_tags" {
  description = "Required tag keys with default values (append policy)."
  type        = map(string)
  default     = { cost_center = "eng", owner = "platform", managed_by = "terraform" }
}

# Naming library: per-resource regex map (key = Azure resource type)
variable "naming_library" {
  description = "Per-resource-type naming regex library."
  type        = map(string)
  # Example defaults. Adjust to your standards.
  default     = {
    "Microsoft.Network/virtualNetworks"                 = "^[a-z0-9-]{3,50}$"
    "Microsoft.Network/virtualNetworks/subnets"         = "^[a-z0-9-]{3,50}$"
    "Microsoft.Network/networkSecurityGroups"           = "^[a-z0-9-]{3,64}$"
    "Microsoft.Compute/virtualMachineScaleSets"         = "^[a-z0-9-]{3,64}$"
    "Microsoft.OperationalInsights/workspaces"          = "^[a-z0-9-]{4,63}$"
    "Microsoft.DBforPostgreSQL/flexibleServers"         = "^[a-z0-9-]{3,63}$"
    "Microsoft.Network/applicationGateways"             = "^[a-z0-9-]{3,80}$"
    "Microsoft.Storage/storageAccounts"                 = "^[a-z0-9]{3,24}$"
    "Microsoft.Resources/resourceGroups"                = "^[a-zA-Z0-9._()-]{1,90}$"
    "Microsoft.KeyVault/vaults"                         = "^[a-z0-9-]{3,24}$"
    "Microsoft.Network/publicIPAddresses"               = "^[a-z0-9-]{3,80}$"
  }
}

# Built-in Initiatives toggles
variable "enable_initiative_azure_monitor_vms" {
  description = "Assign built-in initiative 'Enable Azure Monitor for VMs' at MG scope."
  type        = bool
  default     = true
}

variable "enable_initiative_defender_plans" {
  description = "Assign Microsoft Defender for Cloud built-in plans at MG scope."
  type        = bool
  default     = false
}

# Identity module inputs
variable "mfa_excluded_user_object_ids" {
  description = "Object IDs for break-glass/service accounts to exclude from MFA policy."
  type        = list(string)
  default     = []
}

variable "mfa_include_guest_users" {
  description = "Include B2B guest users in the MFA policy."
  type        = bool
  default     = true
}

# NSG inputs
variable "enable_nsgs" {
  description = "Create NSGs and associate to spoke subnets."
  type        = bool
  default     = true
}

variable "office_cidrs" {
  description = "Trusted office/source CIDRs for admin access (SSH)."
  type        = list(string)
  default     = ["203.0.113.0/24"]
}

variable "nsg_extra_rules" {
  description = "Optional extra NSG rules per subnet name."
  type = object({
    ingress = list(object({ name=string, priority=number, direction=string, access=string, protocol=string,
      source_port_range=string, destination_port_range=string, source_address_prefix=string, destination_address_prefix=string }))
    app     = list(object({ name=string, priority=number, direction=string, access=string, protocol=string,
      source_port_range=string, destination_port_range=string, source_address_prefix=string, destination_address_prefix=string }))
    data    = list(object({ name=string, priority=number, direction=string, access=string, protocol=string,
      source_port_range=string, destination_port_range=string, source_address_prefix=string, destination_address_prefix=string }))
    private = list(object({ name=string, priority=number, direction=string, access=string, protocol=string,
      source_port_range=string, destination_port_range=string, source_address_prefix=string, destination_address_prefix=string }))
  })
  default = { ingress=[], app=[], data=[], private=[] }
}

variable "tags" {
  description = "Common tags on all resources."
  type        = map(string)
  default     = { cost_center="eng", owner="platform", managed_by="terraform" }
}
