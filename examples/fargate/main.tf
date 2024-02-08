provider "aws" {
  region = "us-east-2"
  profile = "inst"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.20.0"
    }
  }
}


module "ecs_cluster" {
  source      = "../../"
  name        = "institucional"
  environment = "PRD"

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 80
      }
    }
  }

  tags = {
    "Name"    = "fargate_example"
    "example" = "true"
  }

}