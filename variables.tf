
variable "igw_id" {
  type = string
}

variable "region" {
  type = string
}

variable "account" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_private_subnets" {
  description = "list of 1-3 CIDRs to create private subnets"
  type        = list(string)
  default     = []
}

variable "vpc_public_subnets" {
  description = "list of 1-3 CIDRs to create public subnets"
  type        = list(string)
  default     = []
}

variable "nat_gateways" {
  description = "list of 1-3 nat gateway ids to assign to the AZ-mathcing private subnets"
  type        = list(string)
  default     = []

}
variable "enabled_metrics" {
  default = []
}

variable "auth_users" {
  default = []
}

variable "flux_enabled" {
  default = true
}

variable "flux_version" {
  default = "v0.21.1"
}

variable "flux_github_url" {
  default = ""
}

variable "flux_target_path" {
  default = ""
}

variable "flux_repo" {
  default = ""
}

variable "flux_branch" {
  default = "main"
}

variable "ecr_sync_job" {
  default = true
  type    = bool
}

variable "flux_auto_image_update" {
  default = false
  type    = bool
}

variable "flux_default_components" {
  default = ["source-controller", "kustomize-controller", "helm-controller", "notification-controller"]
}

variable "flux_patch_gotk" {
  type = bool
  default = false
}

variable "cluster_version" {
  default = "1.21"
}

variable "use_existing_private_subnets" {
  description = "Control weather to create the private subnets with the cluster. if false, you will have to create the subnets yourself before creating the cluster"
  type    = bool
  default = false
}


variable "tags" {
  type = object({
    Env                = string
    App                = string
    Author             = string
    Expires            = bool
    ExpiryDate         = number
    TaggingVersion     = number
    ManagedByTerraform = bool
  })
  default = {
    Env                = ""
    App                = ""
    Author             = ""
    Expires            = false
    ExpiryDate         = 0
    TaggingVersion     = 1
    ManagedByTerraform = true
  }
}

locals {
  common_tags          = var.tags
  node_groups = {
    for group in var.managed_node_groups : group.name => merge({
      subnets = var.use_existing_private_subnets ? data.aws_subnet.existing_private_subnets.*.id : aws_subnet.cluster_private.*.id
      source_security_group_ids = [aws_security_group.workers_sg.id]
    }, group)
  }
}


# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/a26c9fd0c9c880d5b99c438ad620e91dda957e10/local.tf#L28
variable "worker_groups" {
  type    = list(any)
  default = []
}

variable "managed_node_groups" {
  type    = list(any)
  default = []
}
# https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/node_groups
variable "node_groups_defaults" {
  description = "Map of values to be applied to all managed node groups"
  type        = any
  default = {
    name                     = "default_managed_node_group"
    desired_capacity         = 1
    capacity_type            = "SPOT"
    instance_types           = []
    key_name                 = "nodes-access"
    max_capacity             = 1
    min_capacity             = 0
    kubelet_extra_args       = "--node-labels=spot=true"
    disk_size                = "100"
    disk_type                = "gp3"
    k8s_labels               = {}
    taints                   = []
    enable_monitoring        = true
    eni_delete               = true
    public_ip                = false
    set_instance_types_on_lt = true
    create_launch_template   = true
    # launch_template_id            = ""
    launch_template_version = "$Latest"
    pre_userdata            = ""
    additional_tags         = {}
    # additional_security_group_ids = ""
    # iam_role_arn                  = ""
    source_security_group_ids     = [""]
    ami_type = "AL2_x86_64"
    subnets  = ""
  }
}

variable "workers_group_defaults" {
  description = "Map of values to be applied to all unmanaged node groups"
  type        = any
  default = {
    name                                     = "default_worker_group"
    instance_type                            = "t3.medium"
    override_instance_types                  = []
    root_volume_size                         = "100"
    root_volume_type                         = "gp3"
    key_name                                 = "nodes-access"
    asg_desired_capacity                     = 2
    asg_max_size                             = 3
    asg_min_size                             = 1
    spot_allocation_strategy                 = "lowest-price"
    spot_max_price                           = "0.8"
    on_demand_base_capacity                  = "0"
    on_demand_percentage_above_base_capacity = "0"
    spot_instance_pools                      = 10
    protect_from_scale_in                    = false
    root_iops                                = "0"
    root_volume_throughput                   = null
    kubelet_extra_args                       = "--node-labels=spot=true"
    suspended_processes                      = ["AZRebalance"]

    # IRSA Support
    metadata_http_endpoint               = "enabled"
    metadata_http_tokens                 = "required"
    metadata_http_put_response_hop_limit = 1
  }
}

variable "internal_elb" {
  type = object({
    enabled                    = bool
    instance_port              = string
    instance_ssl_port          = string
    instance_health_check_port = string
    cert_arn                   = string
  })
  default = {
    enabled                    = false
    instance_port              = ""
    instance_ssl_port          = ""
    instance_health_check_port = ""
    cert_arn                   = ""
  }
}

variable "irsa_roles" {
  description = "OIDC irsa roles to create, which you can use later in your cluster service-accounts"
  type = list(object({
    role_name          = string
    service_account    = string
    policies_to_assign = list(string)
  }))
  default = []
}

variable "extra_flux_sources" {
  description = "only github repos are supported"
  type = list(object({
    source_name     = string # will become the name of the GitRepository and the secret
    repository_name = string
    github_owner    = string
    branch          = string
    target_path     = string
    read_only       = bool
  }))
  default = []
}
