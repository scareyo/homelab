let
  images = {
    radarr = {
      image = "ghcr.io/home-operations/radarr";
      version = "6.4.4.10685";
    };
  };
in {
  flake.modules.apps.radarr = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.radarr = {
      inherit namespace project;

      templates.app.radarr = {
        workload = {
          inherit (images.radarr) image version;
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
              size = "2Gi";
            };
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
          name = "Radarr";
          description = "Monitor movies";
          logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/radarr.webp";
          allowFrom = [ "prowlarr" "recyclarr" ];
        };
      };

      templates.backup.radarr-daily = {
        restore = true;
        schedule = "0 6 * * *"; # At 06:00 daily
        ttl = "360h";           # 15 days
        selector."app.kubernetes.io/instance" = "radarr";
      };
    };
  };
}
