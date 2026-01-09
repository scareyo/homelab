{ config, lib, ... }:

let
  cfg = config.vegapunk.prowlarr;
  namespace = "prowlarr";
in
{
  options = {
    vegapunk.prowlarr.enable = lib.mkEnableOption "Enable Prowlarr";
  };

  config = lib.mkIf cfg.enable {
    applications.prowlarr = {
      namespace = namespace;
      createNamespace = true;

      templates.app.prowlarr = {
        inherit namespace;

        workload = {
          image = "ghcr.io/home-operations/prowlarr";
          version = "2.3.2";
          port = 9696;
          env = {
            PROWLARR__AUTH__METHOD = "External";
          };
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/config";
            config = {
              size = "4Gi";
            };
          };
        };

        route = {
          auth = {
            enable = true;
            banner = "Prowlarr";
            logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg";
          };
        };

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
        };
      };

      templates.externalSecret.oidc = {
        keys = [
          { source = "/prowlarr/OIDC_CLIENT_ID"; dest = "client-id"; }
          { source = "/prowlarr/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
          { type = "password"; length = 32; dest = "cookie-secret"; }
        ];
      };
    };
  };
}
