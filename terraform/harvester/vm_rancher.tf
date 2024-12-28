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
    network_name = harvester_network.mgmt.id
    mac_address = "0a:00:10:10:20:50"
  }

  disk {
    name = "root"
    type = "disk"
    size = "32Gi"
    bus = "virtio"
    boot_order = 1
    image = harvester_image.leap156.id
    auto_delete = true
  }

  cloudinit {
    user_data = <<-EOF
      #cloud-config
      ssh_pwauth: false
      package_update: true
      packages:
        - helm
      runcmd:
        - "systemctl enable --now qemu-guest-agent"
        - "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.rancher_k3s_version} sh -s - server --cluster-init"
        - "helm repo add rancher-latest https://releases.rancher.com/server-charts/latest"
        - "kubectl create namespace cattle-system"
        - "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${var.rancher_certmanager_version}/cert-manager.crds.yaml"
        - "mkdir ~/.kube"
        - "sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config"
        - "chmod 600 ~/.kube/config"
        - "export KUBECONFIG=~/.kube/config"
        - "helm repo add jetstack https://charts.jetstack.io"
        - "helm repo update"
        - "helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace"
        - "helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname=${var.rancher_hostname} --set replicas=1 --set bootstrapPassword=${local.secrets.rancher.password}"
      ssh_authorized_keys:
        - ${var.ssh_authorized_key}
      EOF
  }
}
