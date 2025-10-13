locals {
  name = "demo"
  tags = { Project = "aws-tf-snippets", Env = "dev" }
}

# Import from previous example by output, or re-run module here
module "vpc" {
  source        = "../../modules/vpc-basic"
  name          = local.name
  cidr          = "10.100.0.0/16"
  az_count      = 2
  create_nat_gw = true
  tags          = local.tags
}

module "bastion" {
  source      = "../../modules/ec2-bastion"
  name        = local.name
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnet_ids[0]
  ssh_cidr    = "0.0.0.0/0" # tighten for real use
  key_name    = "my-keypair"
  tags        = local.tags
}

output "bastion_ip" { value = module.bastion.public_ip }
