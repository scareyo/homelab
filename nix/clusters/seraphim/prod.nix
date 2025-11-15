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
    external-secrets.enable = true;
    gateway.enable = true;
  };
}
