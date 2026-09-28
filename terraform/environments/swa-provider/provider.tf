# provider.tf

# https://registry.terraform.io/providers/cyberark/conjur/latest/docs

terraform {
  required_version = ">= 1.5"
  required_providers {
    conjur = {
      source  = "cyberark/conjur"
      version = "~> 0.9.12"
    }
  }
}

# Configuration is read from the credentials cached by `conjur init` / `conjur login`
# (~/.conjurrc + netrc), so the block can stay empty. See the `conjur:init` and
# `conjur:login` tasks in Taskfile.yml.
provider "conjur" {}
