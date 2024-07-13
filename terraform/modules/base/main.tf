terraform {
  required_providers {
    harvester = {
      source = "harvester/harvester"
      version = "0.6.4"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.31.0"
    }
    rancher2 = {
      source = "rancher/rancher2"
      version = "4.2.0"
    }
  }
}


provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "harvester" {
  kubeconfig = "~/.kube/config"
}

resource "kubernetes_namespace" "infrastructure" {
  metadata {
    name = var.namespace
  }
}

