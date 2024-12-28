resource "rancher2_cloud_credential" "seraphim" {
  provider = rancher2.admin
  name = "seraphim"
  harvester_credential_config {
    cluster_id = resource.rancher2_cluster.seraphim.id
    cluster_type = "imported"
    kubeconfig_content = resource.rancher2_cluster.seraphim.kube_config
  }
}

resource "rancher2_machine_config_v2" "harvester" {
  provider = rancher2.admin
  generate_name = "harvester"
  harvester_config {
    vm_namespace = "infrastructure"
    cpu_count = "8"
    memory_size = "16"
    disk_info = <<EOF
    {
      "disks": [{
        "imageName": "infrastructure/leap156",
        "size": 32,
        "bootOrder": 1
      }]
    }
    EOF
    network_info = <<EOF
    {
      "interfaces": [{
        "networkName": "infrastructure/mgmt"
      }]
    }
    EOF
    ssh_user = "opensuse"
    user_data = <<EOF
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - - systemctl
        - enable
        - '--now'
        - qemu-guest-agent.service
    EOF
  }
}

resource "rancher2_secret_v2" "harvester-cloud-provider" {
  provider = rancher2.admin
  cluster_id = "local"
  namespace = "fleet-default"
  name = "harvester-cloud-provider"
  data = {
      credential = "${local.harvester_config}"
  }
}

resource "rancher2_cluster_v2" "labophase" {
  provider = rancher2.admin
  name = "labophase"
  kubernetes_version = "v1.31.3+rke2r1"
  rke_config {
    machine_pools {
      name = "pool1"
      cloud_credential_secret_name = rancher2_cloud_credential.seraphim.id
      control_plane_role = true
      etcd_role = true
      worker_role = true
      quantity = 7
      machine_config {
        kind = rancher2_machine_config_v2.harvester.kind
        name = rancher2_machine_config_v2.harvester.name
      }
    }
    machine_selector_config {
      config = <<EOF
        cloud-provider-config: "secret://fleet-default:harvester-cloud-provider"
        cloud-provider-name: "harvester"
      EOF
    }
    machine_global_config = <<EOF
      cni: "calico"
      disable-kube-proxy: false
      etcd-expose-metrics: false
    EOF
    upgrade_strategy {
      control_plane_concurrency = "1"
      worker_concurrency = "1"
    }
    etcd {
      snapshot_schedule_cron = "0 */5 * * *"
      snapshot_retention = 5
    }
    chart_values = <<EOF
      harvester-cloud-provider:
        cloudConfigPath: /var/lib/rancher/rke2/etc/config-files/cloud-provider-config
        global:
          cattle:
            clusterName: labophase
      rke2-calico: {}
    EOF
  }
}
