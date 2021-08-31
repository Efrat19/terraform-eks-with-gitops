# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/basic/main.tf
# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/1e2c32430f458409771938c16a3dc437cd657d02/local.tf
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

resource "aws_security_group" "workers_sg" {
  name_prefix = var.cluster_name
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}



module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnets         = var.use_existing_private_subnets ? data.aws_subnet.existing_private_subnets.*.id : aws_subnet.cluster_private.*.id
  tags            = local.common_tags

  vpc_id = var.vpc_id

  worker_groups = var.worker_groups
  workers_group_defaults = var.workers_group_defaults

  node_groups = local.node_groups
  node_groups_defaults = var.node_groups_defaults

  worker_additional_security_group_ids = [aws_security_group.workers_sg.id]
  write_kubeconfig                     = true
  enable_irsa                          = true
  map_users = [for user in var.auth_users : {
    userarn  = "arn:aws:iam::${var.account}:user/${user}"
    username = user
    groups   = ["system:masters"]
  }]

}
