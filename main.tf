resource "aws_ecs_cluster" "this" {
  name = var.name

  dynamic "setting" {
    for_each = var.setting == true ? [var.setting] : []
    content {
      name  = "containerInsights"
      value = var.setting
    }
  }

  tags = var.tags
}


################################################################################
# Cluster Capacity Providers
################################################################################

locals {
  default_capacity_providers = merge(
    { for k, v in var.fargate_capacity_providers : k => v if var.default_capacity_provider_use_fargate },
    { for k, v in var.autoscaling_capacity_providers : k => v if !var.default_capacity_provider_use_fargate }
  )
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = length(merge(var.fargate_capacity_providers, var.autoscaling_capacity_providers)) > 0 ? 1 : 0

  cluster_name = aws_ecs_cluster.this.name
  capacity_providers = distinct(concat(
    [for k, v in var.fargate_capacity_providers : try(v.name, k)],
    [for k, v in var.autoscaling_capacity_providers : try(v.name, k)]
  ))

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html#capacity-providers-considerations
  dynamic "default_capacity_provider_strategy" {
    for_each = local.default_capacity_providers
    iterator = strategy

    content {
      capacity_provider = try(strategy.value.name, strategy.key)
      base              = try(strategy.value.default_capacity_provider_strategy.base, null)
      weight            = try(strategy.value.default_capacity_provider_strategy.weight, null)
    }
  }

  depends_on = [
    aws_ecs_capacity_provider.this
  ]
}

################################################################################
# Capacity Provider - Autoscaling Group(s)
################################################################################

resource "aws_ecs_capacity_provider" "this" {
  for_each = { for k, v in var.autoscaling_capacity_providers : k => v }

  name = try(each.value.name, each.key)

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.this[each.key].arn
    # When you use managed termination protection, you must also use managed scaling otherwise managed termination protection won't work
    managed_termination_protection = length(try([
      each.value.managed_scaling
    ], [])) == 0 ? "DISABLED" : try(each.value.managed_termination_protection, null)

    dynamic "managed_scaling" {
      for_each = try([each.value.managed_scaling], [])

      content {
        instance_warmup_period    = try(managed_scaling.value.instance_warmup_period, null)
        maximum_scaling_step_size = try(managed_scaling.value.maximum_scaling_step_size, null)
        minimum_scaling_step_size = try(managed_scaling.value.minimum_scaling_step_size, null)
        status                    = try(managed_scaling.value.status, null)
        target_capacity           = try(managed_scaling.value.target_capacity, null)
      }
    }
  }

  tags = var.tags
}


#LAUNCH TEMPLATE

resource "aws_launch_template" "this" {
  for_each    = { for k, v in var.autoscaling_capacity_providers : k => v }
  name        = var.name
  description = var.description

  ebs_optimized = var.ebs_optimized
  image_id      = var.ami_id

  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data

  vpc_security_group_ids = var.vpc_security_group_ids

  default_version                      = var.launch_template_default_version
  update_default_version               = var.update_launch_template_default_version
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  ram_disk_id                          = var.ram_disk_id

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = block_device_mappings.value.device_name
      no_device    = lookup(block_device_mappings.value, "no_device", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)

      dynamic "ebs" {
        for_each = flatten([lookup(block_device_mappings.value, "ebs", [])])
        content {
          delete_on_termination = lookup(ebs.value, "delete_on_termination", null)
          encrypted             = lookup(ebs.value, "encrypted", null)
          kms_key_id            = lookup(ebs.value, "kms_key_id", null)
          iops                  = lookup(ebs.value, "iops", null)
          throughput            = lookup(ebs.value, "throughput", null)
          snapshot_id           = lookup(ebs.value, "snapshot_id", null)
          volume_size           = lookup(ebs.value, "volume_size", null)
          volume_type           = lookup(ebs.value, "volume_type", null)
        }
      }
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []
    content {
      capacity_reservation_preference = lookup(capacity_reservation_specification.value, "capacity_reservation_preference", null)

      dynamic "capacity_reservation_target" {
        for_each = try([capacity_reservation_specification.value.capacity_reservation_target], [])
        content {
          capacity_reservation_id = lookup(capacity_reservation_target.value, "capacity_reservation_id", null)
        }
      }
    }
  }

  dynamic "cpu_options" {
    for_each = var.cpu_options != null ? [var.cpu_options] : []
    content {
      core_count       = cpu_options.value.core_count
      threads_per_core = cpu_options.value.threads_per_core
    }
  }

  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []
    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  dynamic "elastic_gpu_specifications" {
    for_each = var.elastic_gpu_specifications != null ? [var.elastic_gpu_specifications] : []
    content {
      type = elastic_gpu_specifications.value.type
    }
  }

  dynamic "elastic_inference_accelerator" {
    for_each = var.elastic_inference_accelerator != null ? [var.elastic_inference_accelerator] : []
    content {
      type = elastic_inference_accelerator.value.type
    }
  }

  dynamic "enclave_options" {
    for_each = var.enclave_options != null ? [var.enclave_options] : []
    content {
      enabled = enclave_options.value.enabled
    }
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null ? [var.iam_instance_profile] : []
    content {
      name = lookup(var.iam_instance_profile, "name", null)
      arn  = lookup(var.iam_instance_profile, "arn", null)
    }
  }

  dynamic "instance_market_options" {
    for_each = var.instance_market_options != null ? [var.instance_market_options] : []
    content {
      market_type = instance_market_options.value.market_type

      dynamic "spot_options" {
        for_each = lookup(instance_market_options.value, "spot_options", null) != null ? [instance_market_options.value.spot_options] : []
        content {
          block_duration_minutes         = lookup(spot_options.value, "block_duration_minutes", null)
          instance_interruption_behavior = lookup(spot_options.value, "instance_interruption_behavior", null)
          max_price                      = lookup(spot_options.value, "max_price", null)
          spot_instance_type             = lookup(spot_options.value, "spot_instance_type", null)
          valid_until                    = lookup(spot_options.value, "valid_until", null)
        }
      }
    }
  }

  dynamic "metadata_options" {
    for_each = var.metadata_options != null ? [var.metadata_options] : []
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", null)
      http_tokens                 = lookup(metadata_options.value, "http_tokens", null)
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", null)
      http_protocol_ipv6          = lookup(metadata_options.value, "http_protocol_ipv6", null)
      instance_metadata_tags      = lookup(metadata_options.value, "instance_metadata_tags", null)
    }
  }

  dynamic "monitoring" {
    for_each = var.enable_monitoring != null ? [1] : []
    content {
      enabled = var.enable_monitoring
    }
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces != null ? [var.network_interfaces] : []
    content {
      associate_carrier_ip_address = lookup(network_interfaces.value, "associate_carrier_ip_address", null)
      associate_public_ip_address  = lookup(network_interfaces.value, "associate_public_ip_address", null)
      delete_on_termination        = lookup(network_interfaces.value, "delete_on_termination", null)
      description                  = lookup(network_interfaces.value, "description", null)
      device_index                 = lookup(network_interfaces.value, "device_index", null)
      interface_type               = lookup(network_interfaces.value, "interface_type", null)
      ipv4_addresses               = try(network_interfaces.value.ipv4_addresses, [])
      ipv4_address_count           = lookup(network_interfaces.value, "ipv4_address_count", null)
      ipv6_addresses               = try(network_interfaces.value.ipv6_addresses, [])
      ipv6_address_count           = lookup(network_interfaces.value, "ipv6_address_count", null)
      network_interface_id         = lookup(network_interfaces.value, "network_interface_id", null)
      private_ip_address           = lookup(network_interfaces.value, "private_ip_address", null)
      security_groups              = lookup(network_interfaces.value, "security_groups", null)
      subnet_id                    = lookup(network_interfaces.value, "subnet_id", null)
    }
  }

  dynamic "placement" {
    for_each = var.placement != null ? [var.placement] : []
    content {
      affinity          = lookup(placement.value, "affinity", null)
      availability_zone = lookup(placement.value, "availability_zone", null)
      group_name        = lookup(placement.value, "group_name", null)
      host_id           = lookup(placement.value, "host_id", null)
      spread_domain     = lookup(placement.value, "spread_domain", null)
      tenancy           = lookup(placement.value, "tenancy", null)
      partition_number  = lookup(placement.value, "partition_number", null)
    }
  }

  dynamic "tag_specifications" {
    for_each = toset(["instance", "volume", "network-interface"])
    content {
      resource_type = tag_specifications.key
      tags          = merge({ Name = var.name }, var.tags)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

#ASG

resource "aws_autoscaling_group" "this" {
  for_each = { for k, v in var.autoscaling_capacity_providers : k => v }
  name     = var.name

  dynamic "launch_template" {
    for_each = var.use_mixed_instances_policy ? [] : [1]

    content {
      id      = aws_launch_template.this.id
      version = var.launch_template_asg_version
    }
  }

  availability_zones  = var.availability_zones
  vpc_zone_identifier = var.vpc_zone_identifier

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  desired_capacity_type     = var.desired_capacity_type
  capacity_rebalance        = var.capacity_rebalance
  min_elb_capacity          = var.min_elb_capacity
  wait_for_elb_capacity     = var.wait_for_elb_capacity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  default_cooldown          = var.default_cooldown
  default_instance_warmup   = var.default_instance_warmup
  protect_from_scale_in     = var.protect_from_scale_in

  load_balancers            = var.load_balancers
  target_group_arns         = var.target_group_arns
  placement_group           = var.placement_group
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  force_delete          = var.force_delete
  termination_policies  = var.termination_policies
  suspended_processes   = var.suspended_processes
  max_instance_lifetime = var.max_instance_lifetime

  enabled_metrics                  = var.enabled_metrics
  metrics_granularity              = var.metrics_granularity
  service_linked_role_arn          = var.service_linked_role_arn
  ignore_failed_scaling_activities = var.ignore_failed_scaling_activities

  dynamic "initial_lifecycle_hook" {
    for_each = var.initial_lifecycle_hooks
    content {
      name                    = initial_lifecycle_hook.value.name
      default_result          = try(initial_lifecycle_hook.value.default_result, null)
      heartbeat_timeout       = try(initial_lifecycle_hook.value.heartbeat_timeout, null)
      lifecycle_transition    = initial_lifecycle_hook.value.lifecycle_transition
      notification_metadata   = try(initial_lifecycle_hook.value.notification_metadata, null)
      notification_target_arn = try(initial_lifecycle_hook.value.notification_target_arn, null)
      role_arn                = try(initial_lifecycle_hook.value.role_arn, null)
    }
  }

  dynamic "instance_refresh" {
    for_each = length(var.instance_refresh) > 0 ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy
      triggers = try(instance_refresh.value.triggers, null)

      dynamic "preferences" {
        for_each = try([instance_refresh.value.preferences], [])
        content {
          checkpoint_delay             = try(preferences.value.checkpoint_delay, null)
          checkpoint_percentages       = try(preferences.value.checkpoint_percentages, null)
          instance_warmup              = try(preferences.value.instance_warmup, null)
          min_healthy_percentage       = try(preferences.value.min_healthy_percentage, null)
          auto_rollback                = try(preferences.value.auto_rollback, null)
          scale_in_protected_instances = try(preferences.value.scale_in_protected_instances, null)
          standby_instances            = try(preferences.value.standby_instances, null)
        }
      }
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.use_mixed_instances_policy ? [var.mixed_instances_policy] : []
    content {
      dynamic "instances_distribution" {
        for_each = try([mixed_instances_policy.value.instances_distribution], [])
        content {
          on_demand_allocation_strategy            = try(instances_distribution.value.on_demand_allocation_strategy, null)
          on_demand_base_capacity                  = try(instances_distribution.value.on_demand_base_capacity, null)
          on_demand_percentage_above_base_capacity = try(instances_distribution.value.on_demand_percentage_above_base_capacity, null)
          spot_allocation_strategy                 = try(instances_distribution.value.spot_allocation_strategy, null)
          spot_instance_pools                      = try(instances_distribution.value.spot_instance_pools, null)
          spot_max_price                           = try(instances_distribution.value.spot_max_price, null)
        }
      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.this[each.key].id
          version            = var.launch_template_asg_version
        }

        dynamic "override" {
          for_each = try(mixed_instances_policy.value.override, [])

          content {
            dynamic "instance_requirements" {
              for_each = try([override.value.instance_requirements], [])

              content {
                dynamic "accelerator_count" {
                  for_each = try([instance_requirements.value.accelerator_count], [])

                  content {
                    max = try(accelerator_count.value.max, null)
                    min = try(accelerator_count.value.min, null)
                  }
                }

                accelerator_manufacturers = try(instance_requirements.value.accelerator_manufacturers, null)
                accelerator_names         = try(instance_requirements.value.accelerator_names, null)

                dynamic "accelerator_total_memory_mib" {
                  for_each = try([instance_requirements.value.accelerator_total_memory_mib], [])

                  content {
                    max = try(accelerator_total_memory_mib.value.max, null)
                    min = try(accelerator_total_memory_mib.value.min, null)
                  }
                }

                accelerator_types      = try(instance_requirements.value.accelerator_types, null)
                allowed_instance_types = try(instance_requirements.value.allowed_instance_types, null)
                bare_metal             = try(instance_requirements.value.bare_metal, null)

                dynamic "baseline_ebs_bandwidth_mbps" {
                  for_each = try([instance_requirements.value.baseline_ebs_bandwidth_mbps], [])

                  content {
                    max = try(baseline_ebs_bandwidth_mbps.value.max, null)
                    min = try(baseline_ebs_bandwidth_mbps.value.min, null)
                  }
                }

                burstable_performance   = try(instance_requirements.value.burstable_performance, null)
                cpu_manufacturers       = try(instance_requirements.value.cpu_manufacturers, null)
                excluded_instance_types = try(instance_requirements.value.excluded_instance_types, null)
                instance_generations    = try(instance_requirements.value.instance_generations, null)
                local_storage           = try(instance_requirements.value.local_storage, null)
                local_storage_types     = try(instance_requirements.value.local_storage_types, null)

                dynamic "memory_gib_per_vcpu" {
                  for_each = try([instance_requirements.value.memory_gib_per_vcpu], [])

                  content {
                    max = try(memory_gib_per_vcpu.value.max, null)
                    min = try(memory_gib_per_vcpu.value.min, null)
                  }
                }

                dynamic "memory_mib" {
                  for_each = try([instance_requirements.value.memory_mib], [])

                  content {
                    max = try(memory_mib.value.max, null)
                    min = try(memory_mib.value.min, null)
                  }
                }

                dynamic "network_bandwidth_gbps" {
                  for_each = try([instance_requirements.value.network_bandwidth_gbps], [])

                  content {
                    max = try(network_bandwidth_gbps.value.max, null)
                    min = try(network_bandwidth_gbps.value.min, null)
                  }
                }

                dynamic "network_interface_count" {
                  for_each = try([instance_requirements.value.network_interface_count], [])

                  content {
                    max = try(network_interface_count.value.max, null)
                    min = try(network_interface_count.value.min, null)
                  }
                }

                on_demand_max_price_percentage_over_lowest_price = try(instance_requirements.value.on_demand_max_price_percentage_over_lowest_price, null)
                require_hibernate_support                        = try(instance_requirements.value.require_hibernate_support, null)
                spot_max_price_percentage_over_lowest_price      = try(instance_requirements.value.spot_max_price_percentage_over_lowest_price, null)

                dynamic "total_local_storage_gb" {
                  for_each = try([instance_requirements.value.total_local_storage_gb], [])

                  content {
                    max = try(total_local_storage_gb.value.max, null)
                    min = try(total_local_storage_gb.value.min, null)
                  }
                }

                dynamic "vcpu_count" {
                  for_each = try([instance_requirements.value.vcpu_count], [])

                  content {
                    max = try(vcpu_count.value.max, null)
                    min = try(vcpu_count.value.min, null)
                  }
                }
              }
            }

            instance_type = try(override.value.instance_type, null)

            dynamic "launch_template_specification" {
              for_each = try([override.value.launch_template_specification], [])

              content {
                launch_template_id = try(launch_template_specification.value.launch_template_id, null)
              }
            }

            weighted_capacity = try(override.value.weighted_capacity, null)
          }
        }
      }
    }
  }

  dynamic "warm_pool" {
    for_each = length(var.warm_pool) > 0 ? [var.warm_pool] : []

    content {
      pool_state                  = try(warm_pool.value.pool_state, null)
      min_size                    = try(warm_pool.value.min_size, null)
      max_group_prepared_capacity = try(warm_pool.value.max_group_prepared_capacity, null)

      dynamic "instance_reuse_policy" {
        for_each = try([warm_pool.value.instance_reuse_policy], [])

        content {
          reuse_on_scale_in = try(instance_reuse_policy.value.reuse_on_scale_in, null)
        }
      }
    }
  }

  timeouts {
    delete = var.delete_timeout
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}