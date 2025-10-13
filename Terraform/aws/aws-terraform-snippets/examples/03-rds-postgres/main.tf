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

resource "aws_security_group" "db" {
  name   = "${local.name}-db-sg"
  vpc_id = module.vpc.vpc_id
  ingress { from_port = 5432 to_port = 5432 protocol = "tcp" cidr_blocks = ["10.100.0.0/16"] }
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = local.tags
}

module "db" {
  source                 = "../../modules/rds-postgres"
  name                   = "${local.name}-pg"
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]
  username               = "appuser"
  password               = "ChangeMe123!"
  instance_class         = "db.t4g.micro"
  tags                   = local.tags
}

output "db_endpoint" { value = module.db.endpoint }
