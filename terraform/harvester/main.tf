terraform {
  required_version = ">= 1.8"
  required_providers {
    harvester = {
      source = "harvester/harvester"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  backend "kubernetes" {
    secret_suffix    = "harvester"
    config_path      = "${path.root}/../../.kube/harvester.yaml"
  }
}

provider "harvester" {
  kubeconfig = "${path.root}/../../.kube/harvester.yaml"
}

provider "kubernetes" {
  config_path = "${path.root}/../../.kube/harvester.yaml"
}

locals {
  secrets = jsondecode(file("${path.root}/../../secrets.json"))
}

data "harvester_storageclass" "harvester-longhorn" {
  name = "harvester-longhorn"
}

resource "kubernetes_namespace" "infrastructure" {
  metadata {
    name = var.namespace
  }
}
