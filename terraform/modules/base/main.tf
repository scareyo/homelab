terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.35.0"
    }
    harvester = {
      source = "harvester/harvester"
      version = "0.6.6"
    }
  }
}

provider "kubernetes" {
  config_path = "${path.root}/../.kube/harvester.yaml"
}

provider "harvester" {
  kubeconfig = "${path.root}/../.kube/harvester.yaml"
}

data "harvester_storageclass" "harvester-longhorn" {
  name = "harvester-longhorn"
}

resource "kubernetes_namespace" "infrastructure" {
  metadata {
    name = var.namespace
  }
}
