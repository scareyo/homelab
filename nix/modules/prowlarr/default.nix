{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.prowlarr;
in
{
  options = {
    vegapunk.prowlarr.enable = lib.mkEnableOption "Enable Prowlarr";
  };

  config = lib.mkIf cfg.enable {
    applications.prowlarr = {
      namespace = "prowlarr";
      createNamespace = true;

      helm.releases.oauth2-proxy = {
        chart = charts.oauth2-proxy;
        values = {
          config = {
            existingSecret = "oidc";
            configFile = ''
              upstreams="http://prowlarr.prowlarr.svc.cluster.local"
              email_domains="*"
              redirect_url="https://prowlarr.vegapunk.cloud/oauth2/callback"
              provider="oidc"
              scope="openid email profile groups"
              oidc_issuer_url="https://id.vegapunk.cloud"
              provider_display_name="Pocket ID"
              custom_sign_in_logo="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg"
              banner="Prowlarr"
              insecure_oidc_allow_unverified_email="true"
            '';
          };
        };
      };

      templates.app.prowlarr = {
        workload = {
          enable = true;
          image = "ghcr.io/home-operations/prowlarr:2.3.1";
          port = 9696;
          env = {
            PROWLARR__AUTH__METHOD = "External";
          };
        };
        persistence = {
          config = {
            type = "pvc";
            path = "/config";
            size = "4Gi";
          };
        };
        route = {
          enable = true;
          serviceName = "oauth2-proxy";
        };
      };

      templates.externalSecret.oidc = {
        keys = [
          { source = "/prowlarr/OIDC_CLIENT_ID"; dest = "client-id"; }
          { source = "/prowlarr/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
          { type = "password"; length = 32; dest = "cookie-secret"; }
        ];
      };

      resources = {
        deployments.oauth2-proxy = {
          spec = {
            template.metadata.annotations = lib.mkForce null;
          };
        };
      };
    };
  };
}
