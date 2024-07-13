variable "namespace" {
  description = "Namespace of the virtual machines"
  type = string
  default = "infrastructure"
}

variable "ssh_authorized_key" {
  description = "Cloud user public key"
  type = string
}
