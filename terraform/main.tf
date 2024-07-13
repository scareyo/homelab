terraform {
  required_version = ">= 0.13"
}


module "base" {
  source = "./modules/base"

  ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+ONWXANqXm3vUJEEjdsEZIxcyGQnk0TQiG6TxnFMm5 scarey@teseuka"
}
