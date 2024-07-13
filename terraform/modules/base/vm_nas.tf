resource "harvester_virtualmachine" "nas" {
  count = 1

  name = "nas"
  namespace = var.namespace
  description = "Network attached storage"

  cpu = 2
  memory = "8Gi"

  efi = true
  secure_boot = false

  network_interface {
    name = "nic-1"
    network_name = harvester_network.service-vlan.id
    mac_address = "52:54:00:d7:20:50"
  }

  disk {
    name = "cdrom-disk"
    type = "cd-rom"
    size = "10Gi"
    bus = "sata"
    boot_order = 2
    image = harvester_image.truenas-scale.id
    auto_delete = true
  }

  disk {
    name = "root"
    type = "disk"
    size = "32Gi"
    bus = "virtio"
    boot_order = 1

    storage_class_name = harvester_storageclass.infrastructure-longhorn.name
  }
}
