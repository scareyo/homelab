terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
      version = "3.4.5"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.35.0"
    }
    rancher2 = {
      source = "rancher/rancher2"
      version = "4.2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "${path.root}/../.kube/harvester.yaml"
}

provider "rancher2" {
  api_url = "https://rancher.int.scarey.me"
  bootstrap = true
  insecure = true
}

data "http" "rancher_health" {
  url = "https://rancher.int.scarey.me/healthz"
  insecure = true
}

resource "rancher2_bootstrap" "admin" {
  initial_password = "${var.rancher_password}"
  password = "${var.rancher_password}"
  telemetry = false

  depends_on = [data.http.rancher_health]
}
