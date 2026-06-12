# provider.tf

terraform {
  required_providers {
    swa = {
      source = "registry.terraform.io/cyberark/swa"
      version = "0.1.0-c2081762-821"
    }
  }
}

provider "swa" {}
