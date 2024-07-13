resource "harvester_image" "truenas-scale" {
  name = "truenas-scale"
  namespace = var.namespace
  display_name = "truenas"
  source_type = "download"
  url = "https://download.sys.truenas.net/TrueNAS-SCALE-Dragonfish/24.04.1.1/TrueNAS-SCALE-24.04.1.1.iso"

  storage_class_name = harvester_storageclass.infrastructure-longhorn.name
}

resource "harvester_image" "almalinux9" {
  name = "almalinux9"
  namespace = var.namespace
  display_name = "almalinux9"
  source_type = "download"
  url = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.4-20240507.x86_64.qcow2"

  storage_class_name = harvester_storageclass.infrastructure-longhorn.name
}
