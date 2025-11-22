{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.argocd;
in
{
  options = with lib; {
    scarey.k8s.argocd.enable = mkEnableOption "Enable Argo CD";
  };

  config = lib.mkIf cfg.enable {
    applications.argocd = {
      namespace = "argocd";
      createNamespace = true;

      syncPolicy.autoSync.enable = true;

      helm.releases.argocd = {
        chart = charts.argoproj.argo-cd;
        values = {
          global.domain = "argocd.vegapunk.cloud";
          configs.params."server.insecure" = true;
        };
      };

      templates.httpRoute.argocd = {
        hostname = "argocd.vegapunk.cloud";
        serviceName = "argocd-server";
      };
    };
  };
}
