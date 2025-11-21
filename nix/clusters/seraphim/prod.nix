{
  imports = [
    ../../modules
  ];

  nixidy.target.repository = "https://github.com/scareyo/homelab.git";
  nixidy.target.branch = "main";
  nixidy.target.rootPath = "./manifests/seraphim/prod";

  scarey.k8s = {
    argocd.enable = true;
    cert-manager.enable = true;
    cilium.enable = true;
    cnpg.enable = true;
    external-dns.enable = true;
    external-secrets.enable = true;
    external-snapshotter.enable = true;
    gateway.enable = true;
    hcloud.enable = true;
    monitoring.enable = true;
    rook.enable = true;
    velero.enable = true;
  };
}
