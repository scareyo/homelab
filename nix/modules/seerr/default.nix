{ config, lib, ... }:

let
  cfg = config.vegapunk.seerr;
  namespace = "seerr";
in
{
  options = {
    vegapunk.seerr.enable = lib.mkEnableOption "Enable Seerr";
  };

  config = lib.mkIf cfg.enable {
    applications.seerr = {
      namespace = namespace;
      createNamespace = true;

      templates.app.seerr = {
        inherit namespace;

        workload = {
          image = "ghcr.io/seerr-team/seerr";
          version = "sha-8bbe786";
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
