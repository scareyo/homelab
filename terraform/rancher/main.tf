terraform {
  required_version = ">= 1.8"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    rancher2 = {
      source = "rancher/rancher2"
    }
  }
  backend "kubernetes" {
    secret_suffix    = "rancher"
    config_path      = "${path.root}/../../.kube/harvester.yaml"
  }
}

provider "kubernetes" {
  config_path = "${path.root}/../../.kube/harvester.yaml"
}

provider "rancher2" {
  api_url   = "https://rancher.int.scarey.me"
  bootstrap = true
  insecure = true
}

locals {
  secrets = jsondecode(file("${path.root}/../../secrets.json"))
  harvester_config = file("${path.module}/../../.kube/harvester.yaml")
}
