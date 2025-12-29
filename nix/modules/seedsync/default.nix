{ config, lib, ... }:

let
  cfg = config.vegapunk.seedsync;
  namespace = "seedsync";
in
{
  options = {
    vegapunk.seedsync.enable = lib.mkEnableOption "Enable SeedSync";
  };

  config = lib.mkIf cfg.enable {
    applications.seedsync = {
      namespace = namespace;
      createNamespace = true;

      templates.app.seedsync = {
        inherit namespace;

        workload = {
          image = "ipsingh06/seedsync";
          version = "0.8.6";
          port = 8800;
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/config";
            config = {
              size = "4Gi";
            };
          };
          downloads = {
            type = "nfs";
            path = "/downloads";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/downloads";
              readOnly = false;
            };
          };
          home = {
            type = "emptyDir";
            path = "/home/seedsync";
          };
          tmp = {
            type = "emptyDir";
            path = "/var/tmp";
          };
        };

        route = {
          auth = {
            enable = true;
            banner = "SeedSync";
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
          { source = "/seedsync/OIDC_CLIENT_ID"; dest = "client-id"; }
          { source = "/seedsync/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
          { type = "password"; length = 32; dest = "cookie-secret"; }
        ];
      };
    };
  };
}
