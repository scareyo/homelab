{ config, lib, ... }:

let
  cfg = config.vegapunk.radarr;
  namespace = "radarr";
in
{
  options = {
    vegapunk.radarr.enable = lib.mkEnableOption "Enable Radarr";
  };

  config = lib.mkIf cfg.enable {
    applications.radarr = {
      namespace = namespace;
      createNamespace = true;

      templates.app.radarr = {
        inherit namespace;

        workload = {
          image = "ghcr.io/home-operations/radarr";
          version = "6.1.1";
          port = 7878;
          env = {
            RADARR__AUTH__METHOD = "External";
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
            banner = "Radarr";
            logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg";
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
          { source = "/radarr/OIDC_CLIENT_ID"; dest = "client-id"; }
          { source = "/radarr/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
          { type = "password"; length = 32; dest = "cookie-secret"; }
        ];
      };
    };
  };
}
