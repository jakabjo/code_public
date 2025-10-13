# Azure Terraform Snippets – Mini Library

Small, composable Terraform modules and end‑to‑end examples for common Azure patterns.
Designed for clarity and security‑first defaults.

## Requirements
- Terraform >= 1.6
- `azurerm` provider >= 3.x
- Azure credentials available (CLI `az login`, env vars, or OIDC)

## Quickstart (example: VNet + Bastion VM)
```bash
cd examples/01-networking-vnet
terraform init && terraform apply

cd ../02-linux-bastion
terraform init && terraform apply
```
Adjust variables via `-var` or `terraform.tfvars`.

## Repository Layout
- `modules/` – Reusable building blocks
- `examples/` – End‑to‑end scenario compositions
- `terragrunt/` – Minimal structure showing how to layer environments

## Security Defaults
- Storage: TLS enforced, public access disabled, encryption on
- Key Vault: soft delete + purge protection, RBAC where possible
- NSG rules: minimal inbound surface
- SQL DB: TLS enforced, firewall constrained (sample opens to VNet)

## Modules
- `rg` – Resource group
- `vnet-basic` – Address space + subnets
- `nsg-basic` – Basic NSG (with optional association to subnet)
- `storage-private` – Storage account with private defaults
- `keyvault-basic` – RBAC-enabled vault with secure settings
- `linux-vm-bastion` – Small jump host with NSG + Public IP
- `lb` – Public Load Balancer, rule + probe
- `sql-database` – SQL server + single database (dev sizing)
- `function-http` – Consumption plan + Function App from zip
- `monitor-alerts-basic` – VM CPU metric alert + Action Group (email)

## Examples
- `00-bootstrap-state` – RG + Storage + Container for remote state
- `01-networking-vnet` – VNet via `vnet-basic`
- `02-linux-bastion` – Adds a bastion VM
- `03-sql-database` – SQL server + database in the VNet
- `04-function-http` – HTTP-trigger Function App (hello world zip)

## Remote State
See `examples/00-bootstrap-state`. After creating the storage + container,
configure your backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<rg-for-state>"
    storage_account_name = "<storageacct>"
    container_name       = "<container>"
    key                  = "env/dev/networking.tfstate"
  }
}
```

## License
MIT
