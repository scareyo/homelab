{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.cert-manager;
in
{
  options = with lib; {
    scarey.k8s.cert-manager.enable = mkEnableOption "Enable cert-manager";

    scarey.k8s.cert-manager.syncWave = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Argo CD application sync wave";
    };
  };
  
  config = lib.mkIf cfg.enable {
    applications.cert-manager = {
      namespace = "cert-manager";
      createNamespace = true;

      annotations = lib.mkIf (cfg.syncWave != null) {
        "argocd.argoproj.io/sync-wave" = "${cfg.syncWave}";
      };

      helm.releases.cert-manager = {
        chart = charts.jetstack.cert-manager;
        values = {
          crds.enabled = true;
          config = {
            apiVersion = "controller.config.cert-manager.io/v1alpha1";
            kind = "ControllerConfiguration";
            enableGatewayAPI = true;
          };
          extraArgs = [
            "--enable-gateway-api"
          ];
        };
      };

      templates.externalSecret.cloudflare = {
        keys = [
          { source = "/cloudflare/API_TOKEN"; dest = "token"; }
        ];
      };

      resources = {
        "cert-manager.io".v1.ClusterIssuer.letsencrypt-staging = {
          metadata = {
            name = "letsencrypt-staging";
            annotations = {
              "argocd.argoproj.io/sync-wave" = "10";
            };
          };
          spec = {
            acme = {
              server = "https://acme-staging-v02.api.letsencrypt.org/directory";
              email = "sam@scarey.me";
              privateKeySecretRef.name = "letsencrypt-staging";
              solvers = [
                {
                  dns01.cloudflare.apiTokenSecretRef = {
                    name = "cloudflare";
                    key = "token";
                  };
                }
              ];
            };
          };
        };
        "cert-manager.io".v1.ClusterIssuer.letsencrypt-production = {
          metadata = {
            name = "letsencrypt-production";
            annotations = {
              "argocd.argoproj.io/sync-wave" = "10";
            };
          };
          spec = {
            acme = {
              server = "https://acme-v02.api.letsencrypt.org/directory";
              email = "sam@scarey.me";
              privateKeySecretRef.name = "letsencrypt-production";
              solvers = [
                {
                  dns01.cloudflare.apiTokenSecretRef = {
                    name = "cloudflare";
                    key = "token";
                  };
                }
              ];
            };
          };
        };
      };
    };
  };
}
