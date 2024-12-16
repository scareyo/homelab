terraform {
  required_version = ">= 1.8"
  backend "kubernetes" {
    secret_suffix    = "state"
    config_path      = "${path.root}/../.kube/harvester.yaml"
  }
}

locals {
  secrets = jsondecode(file("${path.root}/../secrets.json"))
}

module "base" {
  source = "./modules/base"
  ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChdQW4k6/5G12/6y68bH0QBeuvL9tb2uVAi/ILzfxCH"

  rancher_hostname = "rancher.int.scarey.me"
  rancher_password = local.secrets.rancher.password
  rancher_k3s_version = "v1.31.3+k3s1"
  rancher_certmanager_version = "v1.16.2"
}

module "rancher" {
  source = "./modules/rancher"

  rancher_username = local.secrets.rancher.username
  rancher_password = local.secrets.rancher.password
}
