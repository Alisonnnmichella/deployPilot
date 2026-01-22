terraform {
  backend "azurerm" {
    resource_group_name  = "azurepilotdeploy"
    storage_account_name = "pilotstateaccount"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

