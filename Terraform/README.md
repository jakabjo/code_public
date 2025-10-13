# Terraform – Multi-Cloud Infrastructure as Code

This folder contains **multi-cloud Terraform** for Azure and AWS. It is organized for reuse across environments (dev, stage, prod) and teams.

## Highlights
- **Modular**: networking, security, identity, compute, storage as composable modules.
- **Clouds**: Azure & AWS (+ room for hybrid patterns).
- **Governance**: policy/naming/tagging baselines.
- **CI/CD-ready**: designed for automated plan/apply via GitHub Actions.

## Structure (example)
```
terraform/
├─ azure/                 # Azure-specific stacks (e.g., landing zone)
│  ├─ main.tf
│  ├─ modules/
│  └─ README.md
├─ aws/                   # AWS-specific stacks (e.g., VPC baseline)
│  ├─ main.tf
│  ├─ modules/
│  └─ README.md
└─ shared/                # reusable cross-cloud modules (if any)
```

## Getting Started
1. Install Terraform ≥ 1.6 and the cloud CLIs you need (`az`, `aws`).
2. Authenticate:
   - Azure: `az login` or service principal env vars.
   - AWS: `aws configure` or environment credentials/SSO.
3. Initialize:
   ```bash
   terraform init
   terraform plan -var-file=terraform.tfvars
   terraform apply
   ```

## Environments
Use separate workspaces, variable files, or folders for `dev`, `stage`, and `prod`. Example:
```
terraform/
  envs/
    dev/
    stage/
    prod/
```

## Governance
- **Tagging**: enforce with policy and modules.
- **Naming**: consistent, regex-based rules (per resource type).
- **Policies**: Azure Policy / AWS Config where applicable.

## CI/CD
Integrate with `.github/workflows/terraform.yml` for:
- `fmt` + `validate` + `plan` on PRs
- gated `apply` on `main` with environment approvals

## Documentation
- Azure landing zone details live in `terraform/azure/README.md`
- AWS VPC baseline details live in `terraform/aws/README.md`
