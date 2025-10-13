terraform {
  source = "../../../../modules/vpc-basic"
}

inputs = {
  name          = "dev"
  cidr          = "10.50.0.0/16"
  az_count      = 2
  create_nat_gw = true
  tags = { Env = "dev", Project = "aws-tf-snippets" }
}
