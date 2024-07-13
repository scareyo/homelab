data "harvester_clusternetwork" "mgmt" {
  name = "mgmt"
}

resource "harvester_network" "service-vlan" {
  name = "service-vlan"
  namespace = var.namespace
  vlan_id = 20
  route_mode = "auto"
  route_dhcp_server_ip = ""
  cluster_network_name = data.harvester_clusternetwork.mgmt.name
}
