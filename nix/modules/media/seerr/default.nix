{ config, lib, ... }:

let
  cfg = config.vegapunk.seerr;
  namespace = "seerr";
  project = "media";
in
{
  options = {
    vegapunk.seerr.enable = lib.mkEnableOption "Enable Seerr";
  };

  config = lib.mkIf cfg.enable {
    applications.seerr = {
      inherit namespace project;

      createNamespace = true;

      templates.app.seerr = {
        inherit namespace;

        workload = {
          image = "fallenbagel/jellyseerr";
          version = "preview-OIDC";
          port = 5055;
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/app/config";
            config = {
              size = "4Gi";
            };
          };
        };

        route = {};

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
        };
      };
    };
  };
}
