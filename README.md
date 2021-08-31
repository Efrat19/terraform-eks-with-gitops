# terraform-eks-with-gitops
Terraform Module for EKS with built-in Flux GitOps 

## Usage
```hcl
module "example_cluster" {
  source = "git::https://Efrat19/terraform-eks-with-gitops.git"

  account             = "12345678"
  region              = "us-east-1"
  vpc_id              = "vpc-12345678"
  igw_id              = "igw-12345678"
  vpc_private_subnets = ["10.130.112.0/22", "10.130.156.0/22","10.130.144.0/22"]
  vpc_public_subnets  = ["10.130.110.0/24"]
  nat_gateways        = ["nat-123456", "nat-654321", "nat-112233"] # NAT for each AZ, to save cross-region traffic
  cluster_name        = "example"
  cluster_version     = "1.20"
  vpc_cidr            = "10.130.0.0/16"
  auth_users          = ["terraform-iam-user", "my-iam-user"]
  managed_node_groups = [
    {
      name                          = "example_spot_managed_node_group_v1"
      capacity_type                 = "SPOT"
      desired_capacity              = 2
      instance_types                = ["t3.2xlarge", "m5.xlarge", "m5.large", "c5.xlarge", "t2.xlarge"]
      max_capacity                  = 4
      min_capacity                  = 2
      additional_security_group_ids = []
      k8s_labels = {
        spot = "true"
        env  = "example"
      }
    },
    {
      name                          = "example_ondemand_managed_node_group_v1"
      capacity_type                 = "ON_DEMAND"
      desired_capacity              = 0
      instance_types                = ["t3.2xlarge", "m5.xlarge", "m5.large", "c5.xlarge", "t2.xlarge"]
      max_capacity                  = 2
      min_capacity                  = 0
      additional_security_group_ids = []
      k8s_labels = {
        spot = "false"
        env  = "example"
      }
    }
  ]
  flux_github_url        = "ssh://git@github.com/me/my_repo.git"
  flux_target_path       = "example_cluster_source"
  flux_repo              = "my_repo"
  flux_branch            = "main"
  flux_auto_image_update = true
  extra_flux_sources = [
    {
      source_name     = "another-source"
      github_owner    = "another-owner"
      repository_name = "another_repo"
      branch          = "main"
      target_path     = "charts"
      read_only       = true
    }
  ]
  tags                   = {
    Env                = "example"
    App                = "example-cluster"
    Author             = "me"
    Expires            = false
    ExpiryDate         = 0
    TaggingVersion     = 1
    ManagedByTerraform = true
  }
  irsa_roles = [
    {
      role_name       = "k8s-secretmanager-example-cluster"
      service_account = "system:serviceaccount:management:kubernetes-external-secrets"
      policies_to_assign = [
        "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
      ]
    }
  ]
}

```

## Base Modules Documentation
- [terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [terraform-kubernetes-addons](https://github.com/particuleio/terraform-kubernetes-addons)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.40.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 2.4.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 1.11.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.4 |
| <a name="requirement_flux"></a> [flux](#requirement\_flux) | ~> 0.2 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 4.5 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.40.0 |
| <a name="provider_http"></a> [http](#provider\_http) | >= 2.4.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 1.4 |
| <a name="provider_flux"></a> [flux](#provider\_flux) | ~> 0.2 |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 4.5 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

## Inputs


## Outputs

