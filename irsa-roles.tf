
locals {
  provider_domain = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  irsa_roles = concat(var.irsa_roles,local.ecr_sync_irsa_roles)
}

resource "aws_iam_role" "irsa_role" {
  count = length(local.irsa_roles) > 0 ? length(local.irsa_roles) : 0
  name                = local.irsa_roles[count.index].role_name
  path                = "/"
  managed_policy_arns = local.irsa_roles[count.index].policies_to_assign
  assume_role_policy  = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.account}:oidc-provider/${local.provider_domain}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.provider_domain}:aud": "sts.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.account}:oidc-provider/${local.provider_domain}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.provider_domain}:sub": "${local.irsa_roles[count.index].service_account}"
        }
      }
    }
  ]
}
POLICY

  tags = local.common_tags
}

