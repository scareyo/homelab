# hcloud.pkr.hcl

packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
    infisical = {
      source = "github.com/infisical/infisical"
      version = ">=0.0.1"
    }
  }
}

variable "talos_version" {
  type    = string
  default = "v1.11.1"
}

variable "arch" {
  type    = string
  default = "amd64"
}

variable "server_type" {
  type    = string
  default = "cpx11"
}

variable "server_location" {
  type    = string
  default = "ash"
}

variable "infisical_client_id" {
  type = string
  default = env("INFISICAL_UNIVERSAL_AUTH_CLIENT_ID")
}

data "infisical-secrets" "prod" {
  folder_path = "/omni"
  env_slug = "prod"
  project_id = "64853e11f7a9ba1c4ac21cfd"

  universal_auth {
    client_id = "${var.infisical_client_id}"
  }
}

locals {
  schematic_id = data.infisical-secrets.prod.secrets["SCHEMATIC_ID_HCLOUD"].secret_value
  image = "https://factory.talos.dev/image/${local.schematic_id}/${var.talos_version}/hcloud-${var.arch}.raw.xz"
}

source "hcloud" "talos" {
  rescue       = "linux64"
  image        = "debian-11"
  location     = "${var.server_location}"
  server_type  = "${var.server_type}"
  ssh_username = "root"

  snapshot_name   = "talos system disk - ${var.arch} - ${var.talos_version}"
  snapshot_labels = {
    type    = "infra",
    os      = "talos",
    version = "${var.talos_version}",
    arch    = "${var.arch}",
  }
}

build {
  sources = ["source.hcloud.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}
