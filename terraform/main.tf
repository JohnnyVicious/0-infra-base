terraform {
  required_version = ">= 1.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # Uncomment to use remote state storage
  # backend "local" {
  #   path = "terraform.tfstate"
  # }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}
