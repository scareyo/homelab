{
  imports = [
    ../../modules
  ];

  nixidy.target.repository = "https://github.com/scareyo/homelab.git";
  nixidy.target.branch = "main";
  nixidy.target.rootPath = "./manifests/seraphim/prod";

  nixidy.defaults.syncPolicy.autoSync.enable = true;

  scarey.k8s = {
    external-snapshotter = {
      enable = true;
      syncWave = "-6";
    };

    external-secrets = {
      enable = true;
      syncWave = "-6";
    };

    hcloud = {
      enable = true;
      syncWave = "-5";
    };

    cert-manager = {
      enable = true;
      syncWave = "-5";
    };

    gateway = {
      enable = true;
      syncWave = "-4";
    };

    cilium = {
      enable = true;
      syncWave = "-4";
    };

    argocd = {
      enable = true;
      syncWave = "-4";
    };

    external-dns = {
      enable = true;
      syncWave = "-3";
    };

    rook = {
      enable = true;
      syncWave = "-3";
    };

    velero = {
      enable = true;
      syncWave = "-2";
    };

    cnpg = {
      enable = true;
      syncWave = "-2";
    };

    monitoring = {
      enable = true;
      syncWave = "-1";
    };

    pocket-id = {
      enable = true;
      syncWave = "-1";
    };

    renovate.enable = true;
    prowlarr.enable = true;
  };
}
