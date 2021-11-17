terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 0.7"
    }
  }
}