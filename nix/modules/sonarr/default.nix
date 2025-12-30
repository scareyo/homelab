{ config, lib, ... }:

let
  cfg = config.vegapunk.sonarr;
  namespace = "sonarr";
in
{
  options = {
    vegapunk.sonarr.enable = lib.mkEnableOption "Enable Sonarr";
  };

  config = lib.mkIf cfg.enable {
    applications.sonarr = {
      namespace = namespace;
      createNamespace = true;

      templates.app.sonarr = {
        inherit namespace;

        workload = {
          image = "ghcr.io/home-operations/sonarr";
          version = "4.0.16";
          port = 8989;
          env = {
            SONARR__AUTH__METHOD = "External";
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
          media = {
            type = "nfs";
            path = "/mnt/media";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media";
              readOnly = false;
            };
          };
        };

        route = {
          auth = {
            enable = true;
            banner = "Sonarr";
            logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg";
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
          { source = "/sonarr/OIDC_CLIENT_ID"; dest = "client-id"; }
          { source = "/sonarr/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
          { type = "password"; length = 32; dest = "cookie-secret"; }
        ];
      };
    };
  };
}
