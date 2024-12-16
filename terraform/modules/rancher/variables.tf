variable "rancher_username" {
  description = "Rancher username"
  type = string
}

variable "rancher_password" {
  description = "Rancher password"
  type = string
  sensitive = true
}
