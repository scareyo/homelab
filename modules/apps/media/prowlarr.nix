let
  images = {
    prowlarr = {
      image = "ghcr.io/home-operations/prowlarr";
      version = "2.6.5.5623";
    };
  };
in {
  flake.modules.apps.prowlarr = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.prowlarr = {
      inherit namespace project;

      templates.app.prowlarr = {
        workload = {
          inherit (images.prowlarr) image version;
          port = 9696;
          env = {
            PROWLARR__AUTH__METHOD = "External";
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
        };
        route = {};
        auth = {
          name = "Prowlarr";
          description = "Indexer manager";
          logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/prowlarr.webp";
        };
      };

      templates.backup.prowlarr-daily = {
        restore = true;
        schedule = "0 6 * * *"; # At 06:00 daily
        ttl = "360h";           # 15 days
        selector."app.kubernetes.io/instance" = "prowlarr";
      };
    };
  };
}
