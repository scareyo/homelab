terraform {
  required_providers {
    digitalocean = {

    }
  }
}

variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "omada" {
  image = "almalinux-9-x64"
  name = "omada"
  region = "nyc1"
  size = "s-1vcpu-1gb"
}
