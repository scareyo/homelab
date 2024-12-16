resource "harvester_image" "leap156" {
  name = "leap156"
  namespace = var.namespace

  display_name = "openSUSE-Leap-15.6.x86_64-NoCloud.qcow2"
  source_type = "download"
  url = "https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.6/images/openSUSE-Leap-15.6.x86_64-NoCloud.qcow2"
}
