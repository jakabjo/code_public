locals {
  name = "demo"
  tags = { Project = "aws-tf-snippets", Env = "dev" }
}

module "vpc" {
  source        = "../../modules/vpc-basic"
  name          = local.name
  cidr          = "10.100.0.0/16"
  az_count      = 2
  create_nat_gw = true
  tags          = local.tags
}

output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnets" { value = module.vpc.public_subnet_ids }
output "private_subnets" { value = module.vpc.private_subnet_ids }
