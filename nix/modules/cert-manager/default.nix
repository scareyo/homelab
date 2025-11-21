{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.cert-manager;
in
{
  options = with lib; {
    scarey.k8s.cert-manager.enable = mkEnableOption "Enable cert-manager";
  };
  
  config = lib.mkIf cfg.enable {
    applications.cert-manager = {
      namespace = "cert-manager";
      createNamespace = true;

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
          metadata.name = "letsencrypt-staging";
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
      };
    };
  };
}
