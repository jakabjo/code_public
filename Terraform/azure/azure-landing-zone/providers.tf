terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  # Optional remote state (uncomment and configure)
  # backend "azurerm" {
  #   resource_group_name  = "### EDIT ME: tfstate-rg"
  #   storage_account_name = "### EDIT ME: tfstateacct123"
  #   container_name       = "tfstate"
  #   key                  = "landingzone.tfstate"
  # }
}

provider "azurerm" {
  features {}
  # subscription_id = var.subscription_id
  # tenant_id       = var.tenant_id
}

provider "azuread" {}
provider "random" {}
