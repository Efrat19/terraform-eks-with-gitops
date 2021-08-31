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

| Name | Type |
|------|---------|
| aws_iam_role.irsa_role | Resource
| aws_route_table.cluster_private_rtb | Resource
| aws_route_table.cluster_public_rtb_dynamic | Resource
| aws_route_table_association.cluster_private | Resource=
| aws_route_table_association.cluster_public | Resource
| aws_security_group.workers_sg | Resource
| aws_subnet.cluster_private | Resource
| aws_subnet.cluster_public | Resource
| github_repository_deploy_key.main | Resource
| github_repository_file.ecr-sync | Resource
| github_repository_file.sync | Resource
| kubectl_manifest.ecr-sync | Resource
| kubectl_manifest.sync | Resource
| kubernetes_secret.main | Resource
| tls_private_key.main | Resource
| module.addons_flux.github_repository_deploy_key.main | Resource
| module.addons_flux.github_repository_file.install | Resource
| module.addons_flux.github_repository_file.kustomize | Resource
| module.addons_flux.github_repository_file.sync | Resource
| module.addons_flux.kubectl_manifest.apply | Resource
| module.addons_flux.kubectl_manifest.sync | Resource
| module.addons_flux.kubernetes_namespace.flux2 | Resource
| module.addons_flux.kubernetes_network_policy.flux2_allow_monitoring | Resource
| module.addons_flux.kubernetes_network_policy.flux2_allow_namespace | Resource
| module.addons_flux.kubernetes_priority_class.kubernetes_addons | Resource
| module.addons_flux.kubernetes_priority_class.kubernetes_addons_ds | Resource
| module.addons_flux.kubernetes_secret.main | Resource
| module.addons_flux.tls_private_key.identity | Resource
| module.eks.aws_eks_cluster.this | Resource
| module.eks.aws_iam_openid_connect_provider.oidc_provider | Resource
| module.eks.aws_iam_policy.cluster_elb_sl_role_creation | Resource
| module.eks.aws_iam_role.cluster | Resource
| module.eks.aws_iam_role.workers | Resource
| module.eks.aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy | Resource
| module.eks.aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy | Resource
| module.eks.aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy | Resource
| module.eks.aws_iam_role_policy_attachment.cluster_elb_sl_role_creation | Resource
| module.eks.aws_iam_role_policy_attachment.workers_AmazonEC2ContainerRegistryReadOnly | Resource
| module.eks.aws_iam_role_policy_attachment.workers_AmazonEKSWorkerNodePolicy | Resource
| module.eks.aws_iam_role_policy_attachment.workers_AmazonEKS_CNI_Policy | Resource
| module.eks.aws_security_group.cluster | Resource
| module.eks.aws_security_group.workers | Resource
| module.eks.aws_security_group_rule.cluster_egress_internet | Resource
| module.eks.aws_security_group_rule.cluster_https_worker_ingress | Resource
| module.eks.aws_security_group_rule.workers_egress_internet | Resource
| module.eks.aws_security_group_rule.workers_ingress_cluster | Resource
| module.eks.aws_security_group_rule.workers_ingress_cluster_https | Resource
| module.eks.aws_security_group_rule.workers_ingress_self | Resource
| module.eks.kubernetes_config_map.aws_auth | Resource
| module.eks.local_file.kubeconfig | Resource
| module.eks.module.node_groups.aws_eks_node_group.workers | Resource
| module.eks.module.node_groups.aws_launch_template.workers | Resource
| data.aws_availability_zones.available | Data Source
| data.aws_eks_cluster.cluster | Data Source
| data.aws_eks_cluster_auth.cluster | Data Source
| data.aws_nat_gateway.cluster_networking | Data Source
| data.aws_subnet.cluster_networking | Data Source
| data.flux_sync.main | Data Source
| data.github_repository.main | Data Source
| data.kubectl_file_documents.sync | Data Source
| module.addons_flux.data.flux_install.main | Data Source
| module.addons_flux.data.flux_sync.main | Data Source
| module.addons_flux.data.github_repository.main | Data Source
| module.addons_flux.data.kubectl_file_documents.apply | Data Source
| module.addons_flux.data.kubectl_file_documents.sync | Data Source
| module.addons_flux.data.kubectl_path_documents.cert-manager_cluster_issuers | Data Source
| module.addons_flux.data.kubectl_path_documents.cert-manager_csi_driver | Data Source
| module.eks.data.aws_caller_identity.current | Data Source
| module.eks.data.aws_iam_policy_document.cluster_assume_role_policy | Data Source
| module.eks.data.aws_iam_policy_document.cluster_elb_sl_role_creation | Data Source
| module.eks.data.aws_iam_policy_document.workers_assume_role_policy | Data Source
| module.eks.data.aws_partition.current | Data Source
| module.eks.data.http.wait_for_cluster | Data Source
| module.eks.module.node_groups.data.cloudinit_config.workers_userdata | Data Source

## Inputs


## Outputs

