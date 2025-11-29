{
  imports = [
    ../../modules
  ];

  nixidy.target.repository = "https://github.com/scareyo/homelab.git";
  nixidy.target.branch = "main";
  nixidy.target.rootPath = "./manifests/seraphim/prod";

  #nixidy.defaults.syncPolicy.autoSync.enable = true;

  scarey.k8s = {
    # Infrastructure
    external-snapshotter.enable = true;
    external-secrets.enable = true;
    hcloud.enable = true;
    cert-manager.enable = true;
    gateway.enable = true;
    cilium.enable = true;
    argocd.enable = true;
    external-dns.enable = true;
    rook.enable = true;
    velero.enable = true;
    cnpg.enable = true;
    monitoring.enable = true;
    pocket-id.enable = true;
    renovate.enable = true;

    # Applications
    prowlarr.enable = true;
  };
}
