variable "namespace" {
  description = "Name of the infrastructure namespace"
  type = string
  default = "infrastructure"
}

variable "ssh_authorized_key" {
  description = "Cloud user public key"
  type = string
}

variable "rancher_hostname" {
  description = "Rancher hostname"
  type = string
}

variable "rancher_k3s_version" {
  description = "Rancher K3s version"
  type = string
}

variable "rancher_certmanager_version" {
  description = "Rancher cert-manager version"
  type = string
}
