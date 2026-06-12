terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    swa = {
      source  = "cyberark/swa"
      version = "0.1.0-c2081762-821"
    }
  }
}

provider "azurerm" {
  features {}
}
