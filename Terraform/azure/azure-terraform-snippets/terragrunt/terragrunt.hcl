remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "replace-me-rg"
    storage_account_name = "replacemestorageacct"
    container_name       = "tfstate"
    key                  = "global/terragrunt.hcl.tfstate"
  }
}
