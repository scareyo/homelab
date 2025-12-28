{
  imports = [
    ../../modules
  ];

  nixidy.target.repository = "https://github.com/scareyo/homelab.git";
  nixidy.target.branch = "main";
  nixidy.target.rootPath = "./manifests/seraphim/prod";

  nixidy.defaults.helm.extraOpts = [
    "--api-versions gateway.networking.k8s.io/v1/GatewayClass"
    "--api-versions monitoring.coreos.com/v1/PodMonitor"
  ];

  #nixidy.defaults.syncPolicy.autoSync.enable = true;

  vegapunk = {
    argocd.enable = true;
    cert-manager.enable = true;
    cilium.enable = true;
    cnpg.enable = true;
    external-dns.enable = true;
    external-secrets.enable = true;
    external-snapshotter.enable = true;
    gateway.enable = true;
    monitoring.enable = true;
    pocket-id.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    renovate.enable = true;
    rook.enable = true;
    sonarr.enable = true;
    velero.enable = true;
  };
}
