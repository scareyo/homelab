resource "harvester_virtualmachine" "rancher" {
  count = 1

  name = "rancher"
  namespace = var.namespace
  description = "Rancher server"

  cpu = 2
  memory = "4Gi"

  efi = true
  secure_boot = false

  network_interface {
    name = "nic-1"
    network_name = harvester_network.service-vlan.id
    mac_address = "52:54:00:d7:20:51"
  }

  disk {
    name = "root"
    type = "disk"
    size = "32Gi"
    bus = "virtio"
    boot_order = 1
    image = harvester_image.almalinux9.id
    auto_delete = true
  }

  cloudinit {
    user_data = <<-EOF
      #cloud-config
      ssh_pwauth: true
      package_update: true
      packages:
        - qemu-guest-agent
      runcmd:
        - - systemctl
          - enable
          - '--now'
          - qemu-guest-agent
      ssh_authorized_keys:
        - ${var.ssh_authorized_key}
      EOF
  }
}
