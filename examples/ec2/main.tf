provider "aws" {
  region = "us-east-1"
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
  source = "../../"

  name        = "EC2_ASG_EXAMPLE"
  environment = "PRD"

  # Cluster
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    ex = {
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 15
        minimum_scaling_step_size = 5
        status                    = "ENABLED"
        target_capacity           = 90
      }

      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  #Launch Template
  ami_id                  = "ami-01fd3e4ee4a97f6e8"
  key_name                = "bigdata"
  vpc_security_group_ids  = ["sg-084c0a4b99998c3fe"]
  ebs_optimized           = true
  instance_type           = "t3a.micro"
  disable_api_termination = false #enables EC2 instance termination protection
  enable_monitoring       = false
  placement = {
    availability_zone = "us-east-1a"
  }

  iam_instance_profile = {
    name = "ec2_role_ecs_ready"
  }
  #  instance_market_options = {
  #    market_type = "spot"
  #    spot_options = {
  #      spot_instance_type = "one-time"
  #    }
  #  }
  #   user_data                              = var.user_data
  #  network_interfaces = [{ associate_public_ip_address = true }]
  #  block_device_mappings = [
  #    {
  #    device_name = "/dev/xvda"
  #    no_device   = true
  #    ebs = {
  #      volume_size = 30
  #      volume_type = "gp3"
  #    }
  #    },
  #    {
  #      device_name = "/dev/sdb"
  #      ebs = {
  #        volume_size = 30
  #        volume_type = "gp3"
  #      }
  #    }
  #  ]


  # Autoscaling group

  vpc_zone_identifier = ["subnet-00c3c2e98b243711d ", "subnet-0042f66d164ef3afc"]
  min_size            = 0
  max_size            = 3
  desired_capacity    = 2

  capacity_rebalance    = true
  protect_from_scale_in = true

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  # Mixed instances
  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 10
      spot_allocation_strategy                 = "capacity-optimized"
    }

    override = [
      {
        instance_type     = "t3.nano"
        weighted_capacity = "1"
      },
      {
        instance_type     = "t3.medium"
        weighted_capacity = "2"
      },
    ]
  }


  tags = {
    "Name"    = "ecs_ec2_asg_example"
    "example" = "true"
  }
}