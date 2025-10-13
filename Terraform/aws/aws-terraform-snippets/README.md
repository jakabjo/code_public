# AWS Terraform Snippets – Mini Library

Small, composable Terraform modules and end‑to‑end examples for common AWS patterns.
Designed for clarity and security‑first defaults.

## Requirements
- Terraform >= 1.6
- AWS Provider >= 5.x
- AWS credentials via environment or profile

## Quickstart (example: VPC + Bastion)
```bash
cd examples/01-networking-vpc
terraform init && terraform apply

cd ../02-ec2-bastion
terraform init && terraform apply
```
Adjust variables as needed (`-var` or a `terraform.tfvars` file).

## Repository Layout
- `modules/` – Reusable building blocks
- `examples/` – End‑to‑end scenario compositions
- `terragrunt/` – Minimal structure showing how to layer environments

## Security Defaults
- Private subnets for workloads
- S3 buckets block public access and enforce encryption
- Least‑privilege IAM roles for Lambda
- Minimal inbound rules (restrict SSH by CIDR)

## Modules
- `vpc-basic` – 2‑AZ VPC with public/private subnets, IGW, optional NAT
- `s3-private-bucket` – Private S3 with SSE, versioning, lifecycle
- `iam-role-for-lambda` – Execution role with basic CloudWatch Logs permissions
- `ec2-bastion` – Small SSH bastion host in public subnet
- `alb` – Application Load Balancer with listener + target group
- `rds-postgres` – Postgres in private subnets (for dev/test sizes)
- `lambda-api` – Lambda + HTTP API Gateway wiring
- `cloudwatch-alarms-basic` – CPU/SNS alarm example

## Examples
- `00-bootstrap-state` – Creates S3 + DynamoDB for remote state/locking
- `01-networking-vpc` – Provisions VPC via `vpc-basic`
- `02-ec2-bastion` – Adds a bastion host to the VPC
- `03-rds-postgres` – Adds an RDS instance in private subnets
- `04-lambda-apigw` – Serverless API (Lambda + HTTP API)

> Tip: Use the modules independently or copy from `examples/` and adapt.

## Remote State
See `examples/00-bootstrap-state`. After creating the bucket/table, you can
enable a backend block like:

```hcl
terraform {
  backend "s3" {
    bucket         = "<your-state-bucket>"
    key            = "env/dev/networking.tfstate"
    region         = "us-west-2"
    dynamodb_table = "<your-lock-table>"
    encrypt        = true
  }
}
```

## License
MIT
