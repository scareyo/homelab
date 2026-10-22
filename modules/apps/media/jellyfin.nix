let
  images = {
    jellyfin = {
      image = "ghcr.io/jellyfin/jellyfin";
      version = "12.2";
    };
  };
in {
  flake.modules.apps.jellyfin = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.jellyfin = {
      inherit namespace project;

      templates.app.jellyfin = {
        workload = {
          inherit (images.jellyfin) image version;
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
          media = {
            type = "pvc";
            path = "/media";
            config = {
              existingClaim = "media";
            };
          };
        };
        route = {};
      };

      templates.backup.jellyfin-daily = {
        restore = true;
        schedule = "0 6 * * *"; # At 06:00 daily
        ttl = "360h";           # 15 days
        selector."app.kubernetes.io/instance" = "jellyfin";
      };
    };
  };
}
