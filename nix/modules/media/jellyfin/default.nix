{ config, lib, ... }:

let
  cfg = config.vegapunk.jellyfin;
  namespace = "jellyfin";
  project = "media";
in
{
  options = {
    vegapunk.jellyfin.enable = lib.mkEnableOption "Enable Jellyfin";
  };

  config = lib.mkIf cfg.enable {
    applications.jellyfin = {
      inherit namespace project;

      createNamespace = true;

      templates.app.jellyfin = {
        inherit namespace;

        workload = {
          image = "ghcr.io/jellyfin/jellyfin";
          version = "10.11.6";
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
          movies = {
            type = "nfs";
            path = "/mnt/media/movies";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/movies";
              readOnly = true;
            };
          };
          shows = {
            type = "nfs";
            path = "/mnt/media/shows";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/shows";
              readOnly = true;
            };
          };
          livetv = {
            type = "nfs";
            path = "/mnt/media/livetv";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/livetv";
              readOnly = false;
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
      templates.app.zap2xml = {
        inherit namespace;

        workload = {
          image = "ghcr.io/jef/zap2xml";
          version = "v2.2.0";
          env = {
            POSTAL_CODE = "02215";
            OUTPUT_FILE = "/mnt/media/livetv/xmltv.xml";
          };
        };

        persistence = {
          livetv = {
            type = "nfs";
            path = "/mnt/media/livetv";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/livetv";
              readOnly = false;
            };
          };
        };
      };
    };
  };
}
