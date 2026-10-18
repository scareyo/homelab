let
  images = {
    sonarr = {
      image = "ghcr.io/home-operations/sonarr";
      version = "5.0.0.2635";
    };
  };
in {
  flake.modules.apps.sonarr = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.sonarr = {
      inherit namespace project;

      templates.app.sonarr = {
        workload = {
          inherit (images.sonarr) image version;
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
              size = "2Gi";
            };
          };
          tmp = {
            type = "emptyDir";
            path = "/tmp";
          };
          media = {
            type = "pvc";
            path = "/media";
            config = {
              existingClaim = "boxmon-media";
            };
          };
        };
        route = {};
        auth = {
          name = "Sonarr";
          description = "Monitor TV shows";
          logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/sonarr.webp";
          allowFrom = [ "prowlarr" "recyclarr" ];
        };
      };

      templates.backup.sonarr-daily = {
        restore = true;
        schedule = "0 6 * * *"; # At 06:00 daily
        ttl = "360h";           # 15 days
        selector."app.kubernetes.io/instance" = "sonarr";
      };
    };
  };
}
