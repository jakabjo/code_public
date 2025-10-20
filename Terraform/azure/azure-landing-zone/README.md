# Azure Landing Zone - Reusable Terraform Platform - Everything Including the Kitchen Sink

This repository provides a **modular, production-ready Azure Landing Zone** that can be deployed across multiple tenants and subscriptions with minimal changes. It is designed for **enterprise platform engineering teams** to manage network, identity, security, policy, governance, and compute at scale - all via **Terraform + GitHub Actions**.

It is:

- **Reusable:** Fully parameterized and toggle-driven (`terraform.tfvars`)  
- **Governed:** Built-in Azure Policy, naming conventions, tagging, and initiatives  
- **Secure:** Conditional Access MFA, NSGs, NAT egress, and private DBs  
- **Extensible:** Easily add modules or policies without redesign  
- **Automated:** CI/CD pipeline with plan-only, approvals, and production apply

---

## 1. Prerequisites & Setup

### Tools Required

- Terraform ≥ **1.6.x**
- Providers:
  - `azurerm ~> 4.x`
  - `azuread ~> 3.x`
  - `random ~> 3.x`

### Azure Authentication

Set environment variables for Terraform authentication (recommended):

```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_TENANT_ID="<tenantGuid>"
export ARM_SUBSCRIPTION_ID="<subscriptionGuid>"
```

For the MFA policy module, the service principal must have **admin consent** for:

- `Policy.ReadWrite.ConditionalAccess`
- `Directory.ReadWrite.All`

### Remote State (Recommended)

Uncomment and configure the backend in `providers.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "tfstate-rg"
  storage_account_name = "tfstateacct"
  container_name       = "tfstate"
  key                  = "landingzone.tfstate"
}
```

---

## 2. Configuration & Variables

All critical configuration is centralized in `terraform.tfvars`. Here are key variables:

| Variable | Purpose |
|----------|---------|
| `location` | Azure region |
| `org_name` | Short org/project name |
| `env` | Environment (dev/test/prod) |
| `address_spaces` / `subnets` | CIDR configuration |
| `enable_management_groups` | Toggle MG deployment |
| `enable_security_policies` | Toggle policy enforcement |
| `enable_tenant_mfa` | Toggle Conditional Access MFA |
| `enable_nsgs` | Deploy NSGs with baseline rules |
| `create_app_gateway` | Enable Application Gateway |
| `db_engine` | `"pg"` for PostgreSQL Flexible or `"none"` |
| `enable_initiative_azure_monitor_vms` | Built-in Azure Monitor initiative |
| `enable_initiative_defender_plans` | Defender for Cloud plans |
| `naming_library` | Map of resource types → regex |
| `policy_required_tags` | Required tags enforced by policy |

---

## 3. Architecture Overview

This landing zone implements a **hub-and-spoke** model with governance and security baked in.

- **Networking:** Hub/Spoke VNets, NAT egress, private subnets  
- **Security:** NSGs, policy enforcement, conditional access  
- **Governance:** Management Groups, Azure Policy, tagging, naming  
- **Compute:** VMSS with cloud-init bootstrap  
- **Data:** PostgreSQL Flexible Server (private DNS + subnet delegation)  
- **Monitoring:** Log Analytics, diagnostic settings, Azure Monitor  
- **Ingress:** Application Gateway (WAF_v2)  
- **Storage:** Private Storage Accounts  
- **Identity:** Conditional Access MFA policy with exclusions

```
Internet ─▶ App Gateway ─▶ Ingress Subnet
                   │
                   ├─▶ App Subnet ─▶ NAT Gateway ─▶ Internet
                   │
                   ├─▶ Data Subnet ─▶ PostgreSQL (Private DNS)
                   │
                   └─▶ Private Subnet
```

---

## 4. Terraform Modules

| Module | Description |
|--------|------------|
| `core/` | Resource groups, Key Vault |
| `network/` | Hub/Spoke VNets, subnets, NAT GW |
| `ingress/` | Application Gateway (WAF_v2) |
| `compute/` | VM Scale Sets with cloud-init |
| `database/` | PostgreSQL Flexible Server |
| `storage/` | Storage Account + logging container |
| `monitor/` | Log Analytics + diagnostics |
| `management/` | Management Group hierarchy |
| `identity/` | Conditional Access MFA policy |
| `security/` | Policy enforcement, initiatives, naming |
| `nsg/` | NSG baseline + subnet associations |

---

## 5. Running Terraform

```bash
terraform init -reconfigure
terraform plan -var="org_name=acme" -var="env=dev" -var="location=eastus2"
terraform apply -auto-approve
```

### Reusing in a New Tenant

```bash
export ARM_TENANT_ID="<new-tenant-guid>"
export ARM_SUBSCRIPTION_ID="<new-sub-guid>"
terraform init -reconfigure
terraform apply -auto-approve
```

---

## 6. CI/CD Workflow — Engineer-Ops Guide

This repository includes a **two-stage GitHub Actions pipeline**:

- **Stage 1 – Plan-Only Environment (`plan-only`):**  
  Runs on pull requests, push events, and manual triggers.  
  No resources are deployed — only `fmt`, `validate`, and `plan` run.

- **Stage 2 – Production Environment (`production`):**  
  Runs only on `main` merges and requires **manual approval** via GitHub Environments.  
  After approval, `terraform apply` runs.

> The workflow file lives at: `.github/workflows/terraform.yml`.

### Workflow Summary

| Event | Environment | What Happens |
|-------|-------------|---------------|
| **Pull Request** | `plan-only` | `fmt`, `validate`, `plan` + PR comment |
| **Push to main** | `plan-only` → `production` | Plan → Approval → Apply |
| **Manual Trigger** | `plan-only` | Ad-hoc plan, no apply |

---

### PR Workflow (Default)

1. Developer opens a PR.  
2. Workflow runs `terraform init`, `fmt`, `validate`, and `plan`.  
3. Plan output is posted as a **PR comment**.  
4. Reviewers verify changes and approve the PR.

---

### Manual Plan-Only Execution

To manually run a plan (without apply):

1. Go to **Actions → Terraform CI/CD → Run workflow**.  
2. Choose the `plan-only` environment.  
3. Optionally add a note for the plan comment.  
4. Plan artifacts (`tfplan` + `plan.txt`) will be attached to the run.

---

### Production Apply Workflow

Triggered when code is merged into `main`:

1. **Plan:** Runs automatically in `plan-only`.  
2. **Approval:** GitHub requires manual approval before proceeding.  
3. **Apply:** Terraform runs `apply -auto-approve` in `production`.

**Recommended:** Require **at least two reviewers** in `production` environment settings.

---

## 7. Operational Runbook

### Pre-Deployment Checks

- [ ] `terraform fmt -recursive` passes  
- [ ] `terraform validate` passes  
- [ ] Plan reviewed and approved  
- [ ] CIDR ranges verified (no overlaps)  
- [ ] Policy changes reviewed (tagging, naming, initiatives)  
- [ ] State backend secured (RBAC + firewall)

---

### Post-Deployment Validation

- [ ] All resource groups and VNets deployed  
- [ ] NSGs attached and active  
- [ ] App Gateway online and reachable  
- [ ] VMSS nodes healthy and accessible  
- [ ] PostgreSQL private DNS resolves  
- [ ] Diagnostic logs flowing to Log Analytics  
- [ ] MFA policy active (if enabled)

---

## 8. Disaster Recovery & Rollback Guide

Even with IaC, rollback must be deliberate. Follow this procedure:

### 1. **Stop Further Changes**

- Lock the main branch immediately.
- Pause any CI/CD workflows to prevent further applies.

### 2. **Inspect Current State**

```bash
terraform state list
terraform show
```
Export the state for backup:
```bash
terraform state pull > backup-$(date +%F).tfstate
```

### 3. **Rollback to a Previous Commit**

- Checkout the last known-good commit:
```bash
git checkout <commit-hash>
terraform init -reconfigure
terraform plan
```
- Review the plan to confirm it reverts undesired changes.
- Run `terraform apply` to restore the previous configuration.

### 4. **Restore from Backup State (if needed)**

If state is corrupted or drifted:
```bash
terraform state push backup-YYYY-MM-DD.tfstate
terraform plan
terraform apply
```

### 5. **Manual Remediation**

For failed applies (e.g., stuck resources):
- Use `terraform destroy -target=<resource>` to remove problematic resources.
- Rerun `terraform plan` and `terraform apply`.

---

## 9. Safety Checklist

- [ ] Break-glass accounts excluded from MFA  
- [ ] Policy assignments verified before apply  
- [ ] Required tags enforced and append policies working  
- [ ] Naming regex validated against `naming_library`  
- [ ] Built-in initiatives enabled (`azure_monitor_vms`, `defender_plans`)  
- [ ] NSGs restrict ingress to expected CIDRs only  
- [ ] Remote state locked down (firewall + RBAC)  

---

## 10. Extending the Landing Zone

- Add new modules under `modules/` (e.g., Redis, ACR, AKS)  
- Add policy definitions or initiatives to `modules/security`  
- Add additional diagnostic settings to `modules/monitor`  
- Extend `naming_library` for new resource types  
- Add more Conditional Access policies in `modules/identity`

---

## Expected Terraform Outputs

```
resource_group_names = { hub = "acme-dev-hub-rg", spoke = "acme-dev-spoke-rg" }
vnet_ids             = { hub = ".../acme-dev-hub-vnet", spoke = ".../acme-dev-spoke-vnet" }
subnet_ids           = { ... }
app_gateway_public_ip      = "20.51.10.123"
vmss_name                  = "acme-dev-vmss"
database_fqdn              = "acme-dev-pgxyz.postgres.database.azure.com"
log_analytics_workspace_id = "/subscriptions/.../workspaces/acme-dev-law"
management_group_root_id   = "/providers/Microsoft.Management/managementGroups/acme-dev-platform"

---

```
## Testing

This configuration ships with **native Terraform tests** (Terraform ≥ 1.6). Tests are **plan-only** by default, so they run quickly and do not create cloud resources.

### Run locally

```bash
cd Terraform/azure/azure-landing-zone
terraform init
terraform test -compact-warnings

---
```
## Summary

This landing zone repository provides a **repeatable, secure, governed, and automated Azure foundation** for multi-tenant enterprise environments. With policy enforcement, security defaults, CI/CD automation, and rollback strategy built-in, it forms the backbone of a robust cloud platform.

Use it as-is or extend it as your platform maturity evolves — the toggles, modules, and pipelines are designed to scale with you.
