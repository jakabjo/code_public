terraform {
  source = "../../../../modules/vnet-basic"
}

inputs = {
  name                = "vnet-dev"
  resource_group_name = "rg-dev"
  location            = "westus2"
  address_space       = ["10.70.0.0/16"]
  subnets = [
    { name = "public",  address_prefix = "10.70.0.0/24" },
    { name = "private", address_prefix = "10.70.1.0/24" }
  ]
  tags = { Env = "dev", Project = "azure-tf-snippets" }
}
