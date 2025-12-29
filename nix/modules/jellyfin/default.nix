{ config, lib, ... }:

let
  cfg = config.vegapunk.jellyfin;
  namespace = "jellyfin";
in
{
  options = {
    vegapunk.jellyfin.enable = lib.mkEnableOption "Enable Jellyfin";
  };

  config = lib.mkIf cfg.enable {
    applications.jellyfin = {
      namespace = namespace;
      createNamespace = true;

      templates.app.jellyfin = {
        inherit namespace;

        workload = {
          image = "ghcr.io/jellyfin/jellyfin";
          version = "10.11.5";
          port = 8096;
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/config";
            config = {
              size = "4Gi";
            };
          };
          cache = {
            type = "emptyDir";
            path = "/cache";
          };
          shows = {
            type = "nfs";
            path = "/media/shows";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/shows";
              readOnly = true;
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
