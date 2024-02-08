variable "name" {
  description = "Prefix name to create IAC"
}
variable "environment" {
  description = "PRD DEV or HML to help creating the ssm_parameter"
}
variable "setting" {
  description = "if true enable container insights"
  default     = false
}
variable "tags" {
  type        = map(string)
  description = "map of tags"
}

################################################################################
# Capacity Providers
################################################################################

variable "default_capacity_provider_use_fargate" {
  description = "Determines whether to use Fargate or autoscaling for default capacity provider strategy"
  type        = bool
  default     = true
}

variable "fargate_capacity_providers" {
  description = "Map of Fargate capacity provider definitions to use for the cluster"
  type        = any
  default     = {}
}

variable "autoscaling_capacity_providers" {
  description = "Map of autoscaling capacity provider definitions to create for the cluster"
  type        = any
  default     = {}
}

#####################################
# LAUNCH TEMPLATE
#####################################

variable "user_data" {
  description = "The user data to provide when launching the instance. Do not pass gzip-compressed data via this argument"
  type        = any
  default     = null
}

variable "description" {
  description = "description of the lauch template"
  type        = string
  default     = null
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance(s) will be EBS-optimized"
  type        = bool
  default     = null
}

variable "ami_id" {
  description = "The AMI from which to launch the instance. If not supplied, EKS will use its own default image"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "The type of the instance"
  type        = string
  default     = null
}

variable "key_name" {
  description = "The key name that should be used for the instance(s)"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "launch_template_default_version" {
  description = "Default version of the launch template"
  type        = string
  default     = null
}

variable "update_launch_template_default_version" {
  description = "Whether to update the launch templates default version on each update. Conflicts with `launch_template_default_version`"
  type        = bool
  default     = true
}

variable "disable_api_termination" {
  description = "If true, enables EC2 instance termination protection"
  type        = bool
  default     = null
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance. Can be stop or terminate"
  type        = string
  default     = "terminate"
}

variable "ram_disk_id" {
  description = "The ID of the ram disk"
  type        = string
  default     = null
}

variable "block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type        = any
  default     = {}
}

variable "capacity_reservation_specification" {
  description = "Targeting for EC2 capacity reservations"
  type        = any
  default     = null
}

variable "cpu_options" {
  description = "The CPU options for the instance"
  type        = map(string)
  default     = null
}

variable "credit_specification" {
  description = "Customize the credit specification of the instance"
  type        = map(string)
  default     = null
}

variable "elastic_gpu_specifications" {
  description = "The elastic GPU to attach to the instance"
  type        = map(string)
  default     = null
}

variable "elastic_inference_accelerator" {
  description = "Configuration block containing an Elastic Inference Accelerator to attach to the instance"
  type        = map(string)
  default     = null
}

variable "enclave_options" {
  description = "Enable Nitro Enclaves on launched instances"
  type        = map(string)
  default     = null
}

variable "hibernation_options" {
  description = " The hibernation options for the instance"
  type        = map(string)
  default     = null
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile to launch the instance with"
  type        = map(string)
  default     = null
}

variable "instance_market_options" {
  description = "The market (purchasing) option for the instance"
  type        = any
  default     = null
}

variable "license_specifications" {
  description = "A list of license specifications to associate with"
  type        = map(string)
  default     = null
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type        = map(string)
  default     = null
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring"
  type        = bool
  default     = null
}

variable "network_interfaces" {
  description = "Customize network interfaces to be attached at instance boot time"
  type        = list(any)
  default     = null
}

variable "placement" {
  description = "The placement of the instance"
  type        = map(string)
  default     = null
}


################################################################################
# Autoscaling group
################################################################################

variable "launch_template_asg_version" {
  type        = string
  default     = "$Latest"
  description = "The default version of launch template to be used"
}

variable "ignore_desired_capacity_changes" {
  description = "Determines whether the `desired_capacity` value is ignored after initial apply. See README note for more details"
  type        = bool
  default     = false
}

variable "use_name_prefix" {
  description = "Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix"
  type        = bool
  default     = true
}

variable "instance_name" {
  description = "Name that is propogated to launched EC2 instances via a tag - if not provided, defaults to `var.name`"
  type        = string
  default     = ""
}

variable "launch_template_id" {
  description = "ID of an existing launch template to be used (created outside of this module)"
  type        = string
  default     = null
}

variable "launch_template_version" {
  description = "Launch template version. Can be version number, `$Latest`, or `$Default`"
  type        = string
  default     = null
}

variable "availability_zones" {
  description = "A list of one or more availability zones for the group. Used for EC2-Classic and default subnets when not specified with `vpc_zone_identifier` argument. Conflicts with `vpc_zone_identifier`"
  type        = list(string)
  default     = null
}

variable "vpc_zone_identifier" {
  description = "A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside. Conflicts with `availability_zones`"
  type        = list(string)
  default     = null
}

variable "min_size" {
  description = "The minimum size of the autoscaling group"
  type        = number
  default     = null
}

variable "max_size" {
  description = "The maximum size of the autoscaling group"
  type        = number
  default     = null
}

variable "desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the autoscaling group"
  type        = number
  default     = null
}

variable "desired_capacity_type" {
  description = "The unit of measurement for the value specified for desired_capacity. Supported for attribute-based instance type selection only. Valid values: `units`, `vcpu`, `memory-mib`."
  type        = string
  default     = null
}

variable "capacity_rebalance" {
  description = "Indicates whether capacity rebalance is enabled"
  type        = bool
  default     = null
}

variable "min_elb_capacity" {
  description = "Setting this causes Terraform to wait for this number of instances to show up healthy in the ELB only on creation. Updates will not wait on ELB instance number changes"
  type        = number
  default     = null
}

variable "wait_for_elb_capacity" {
  description = "Setting this will cause Terraform to wait for exactly this number of healthy instances in all attached load balancers on both create and update operations. Takes precedence over `min_elb_capacity` behavior."
  type        = number
  default     = null
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. (See also Waiting for Capacity below.) Setting this to '0' causes Terraform to skip all Capacity Waiting behavior."
  type        = string
  default     = null
}

variable "default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start"
  type        = number
  default     = null
}

variable "default_instance_warmup" {
  description = "Amount of time, in seconds, until a newly launched instance can contribute to the Amazon CloudWatch metrics. This delay lets an instance finish initializing before Amazon EC2 Auto Scaling aggregates instance metrics, resulting in more reliable usage data. Set this value equal to the amount of time that it takes for resource consumption to become stable after an instance reaches the InService state."
  type        = number
  default     = null
}

variable "protect_from_scale_in" {
  description = "Allows setting instance protection. The autoscaling group will not select instances with this setting for termination during scale in events."
  type        = bool
  default     = false
}

variable "load_balancers" {
  description = "A list of elastic load balancer names to add to the autoscaling group names. Only valid for classic load balancers. For ALBs, use `target_group_arns` instead"
  type        = list(string)
  default     = []
}

variable "target_group_arns" {
  description = "A set of `aws_alb_target_group` ARNs, for use with Application or Network Load Balancing"
  type        = list(string)
  default     = []
}

variable "placement_group" {
  description = "The name of the placement group into which you'll launch your instances, if any"
  type        = string
  default     = null
}

variable "health_check_type" {
  description = "`EC2` or `ELB`. Controls how health checking is done"
  type        = string
  default     = null
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = null
}

variable "force_delete" {
  description = "Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate. You can force an Auto Scaling Group to delete even if it's in the process of scaling a resource. Normally, Terraform drains all the instances before deleting the group. This bypasses that behavior and potentially leaves resources dangling"
  type        = bool
  default     = null
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the Auto Scaling Group should be terminated. The allowed values are `OldestInstance`, `NewestInstance`, `OldestLaunchConfiguration`, `ClosestToNextInstanceHour`, `OldestLaunchTemplate`, `AllocationStrategy`, `Default`"
  type        = list(string)
  default     = []
}

variable "suspended_processes" {
  description = "A list of processes to suspend for the Auto Scaling Group. The allowed values are `Launch`, `Terminate`, `HealthCheck`, `ReplaceUnhealthy`, `AZRebalance`, `AlarmNotification`, `ScheduledActions`, `AddToLoadBalancer`, `InstanceRefresh`. Note that if you suspend either the `Launch` or `Terminate` process types, it can prevent your Auto Scaling Group from functioning properly"
  type        = list(string)
  default     = []
}

variable "max_instance_lifetime" {
  description = "The maximum amount of time, in seconds, that an instance can be in service, values must be either equal to 0 or between 86400 and 31536000 seconds"
  type        = number
  default     = null
}

variable "enabled_metrics" {
  description = "A list of metrics to collect. The allowed values are `GroupDesiredCapacity`, `GroupInServiceCapacity`, `GroupPendingCapacity`, `GroupMinSize`, `GroupMaxSize`, `GroupInServiceInstances`, `GroupPendingInstances`, `GroupStandbyInstances`, `GroupStandbyCapacity`, `GroupTerminatingCapacity`, `GroupTerminatingInstances`, `GroupTotalCapacity`, `GroupTotalInstances`"
  type        = list(string)
  default     = []
}

variable "metrics_granularity" {
  description = "The granularity to associate with the metrics to collect. The only valid value is `1Minute`"
  type        = string
  default     = null
}

variable "service_linked_role_arn" {
  description = "The ARN of the service-linked role that the ASG will use to call other AWS services"
  type        = string
  default     = null
}

variable "initial_lifecycle_hooks" {
  description = "One or more Lifecycle Hooks to attach to the Auto Scaling Group before instances are launched. The syntax is exactly the same as the separate `aws_autoscaling_lifecycle_hook` resource, without the `autoscaling_group_name` attribute. Please note that this will only work when creating a new Auto Scaling Group. For all other use-cases, please use `aws_autoscaling_lifecycle_hook` resource"
  type        = list(map(string))
  default     = []
}

variable "instance_refresh" {
  description = "If this block is configured, start an Instance Refresh when this Auto Scaling Group is updated"
  type        = any
  default     = {}
}

variable "use_mixed_instances_policy" {
  description = "Determines whether to use a mixed instances policy in the autoscaling group or not"
  type        = bool
  default     = false
}

variable "mixed_instances_policy" {
  description = "Configuration block containing settings to define launch targets for Auto Scaling groups"
  type        = any
  default     = null
}

variable "delete_timeout" {
  description = "Delete timeout to wait for destroying autoscaling group"
  type        = string
  default     = null
}

variable "warm_pool" {
  description = "If this block is configured, add a Warm Pool to the specified Auto Scaling group"
  type        = any
  default     = {}
}

variable "image_id" {
  description = "The AMI from which to launch the instance"
  type        = string
  default     = ""
}

variable "asg_instance_type" {
  description = "The type of the instance. If present then `instance_requirements` cannot be present"
  type        = string
  default     = null
}

variable "instance_requirements" {
  description = "The attribute requirements for the type of instance. If present then `instance_type` cannot be present"
  type        = any
  default     = {}
}

variable "security_groups" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "autoscaling_group_tags" {
  description = "A map of additional tags to add to the autoscaling group"
  type        = map(string)
  default     = {}
}

variable "ignore_failed_scaling_activities" {
  description = "Whether to ignore failed Auto Scaling scaling activities while waiting for capacity. The default is false -- failed scaling activities cause errors to be returned."
  type        = bool
  default     = false
}

variable "asg_tags" {
  description = "ASG tags must be set in a different way but instance tags can be set with Launch template"
  type        = list(any)
  default     = []
}