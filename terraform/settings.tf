terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.20.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = var.state_store_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_contianer_name
    key                  = var.state_blob_name
  }
}

provider "cloudflare" { 
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "azurerm" {
  features {}
}
