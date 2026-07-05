terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  cloud {
    organization = "adcb-enterprise"
    workspaces {
      name = "intuitive-ai-dev"
    }
  }
}

provider "azurerm" {
  features {}
}


