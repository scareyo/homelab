resource "harvester_clusternetwork" "vm" {
  name = "vm"
}

data "harvester_clusternetwork" "mgmt" {
  name = "mgmt"
}

resource "harvester_vlanconfig" "vm" {
  name = "vm"

  cluster_network_name = resource.harvester_clusternetwork.vm.name

  uplink {
    nics = [
      "enp3s0f0"
    ]
    bond_miimon = 100
  }
}

resource "harvester_network" "vm" {
  name = "vm"
  namespace = var.namespace

  cluster_network_name = resource.harvester_clusternetwork.vm.name

  vlan_id = 21
  route_mode = "auto"
}

resource "harvester_network" "mgmt" {
  name = "mgmt"
  namespace = var.namespace

  cluster_network_name = data.harvester_clusternetwork.mgmt.name

  vlan_id = 20
  route_mode = "auto"
}
