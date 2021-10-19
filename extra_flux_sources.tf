
resource "tls_private_key" "main" {
  count     = length(var.extra_flux_sources)
  algorithm = "RSA"
  rsa_bits  = 4096
}


data "flux_sync" "main" {
  name        = var.extra_flux_sources[count.index].source_name
  secret      = "${var.extra_flux_sources[count.index].source_name}-secret"
  count       = length(var.extra_flux_sources)
  target_path = var.extra_flux_sources[count.index].target_path
  url         = "ssh://git@github.com/${var.extra_flux_sources[count.index].github_owner}/${var.extra_flux_sources[count.index].repository_name}.git"
  branch      = var.extra_flux_sources[count.index].branch
}

# Kubernetes


data "kubectl_file_documents" "sync" {
  count   = length(var.extra_flux_sources)
  content = data.flux_sync.main[count.index].content
}

resource "kubectl_manifest" "sync" {
  #   count      = length(var.extra_flux_sources)
  for_each   = { for v in local.sync : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  depends_on = [module.addons_flux]
  yaml_body  = each.value
  lifecycle {
    ignore_changes = [
      yaml_incluster
    ]
    create_before_destroy = true
  }
}

resource "kubernetes_secret" "main" {
  count = length(var.extra_flux_sources)

  metadata {
    name      = data.flux_sync.main[count.index].secret
    namespace = data.flux_sync.main[count.index].namespace
  }

  data = {
    identity       = tls_private_key.main[count.index].private_key_pem
    "identity.pub" = tls_private_key.main[count.index].public_key_pem
    known_hosts    = local.known_hosts
  }
}

# GitHub
data "github_repository" "main" {
  name = var.flux_repo
}

resource "github_repository_deploy_key" "main" {
  count      = length(var.extra_flux_sources)
  title      = "${var.cluster_name}_${var.extra_flux_sources[count.index].source_name}_flux_deploy_key"
  repository = var.extra_flux_sources[count.index].repository_name
  key        = tls_private_key.main[count.index].public_key_openssh
  read_only  = var.extra_flux_sources[count.index].read_only
}

resource "github_repository_file" "sync" {
  count      = length(var.extra_flux_sources)
  repository = data.github_repository.main.name
  file       = "${var.flux_target_path}/${local.flux_manifests_path}/${var.extra_flux_sources[count.index].source_name}.yaml"
  content    = data.flux_sync.main[count.index].content
  branch     = var.flux_branch
  lifecycle {
    ignore_changes = [content, sha]
  }
}


locals {
  extra_flux_sources_dis = [for dis in {for x in var.extra_flux_sources : "${x.github_owner}:${x.repository_name}" => x...} : dis[0]]
  sync = flatten([
    for i, src in var.extra_flux_sources : [
      for v in data.kubectl_file_documents.sync[i].documents : {
        data : yamldecode(v)
        content : v
      }
    ]
  ])
  flux_manifests_path = "flux-system"
}
