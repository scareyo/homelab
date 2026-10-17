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
            type = "emptyDir";
            path = "/config";
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
        };
      };
    };
  };
}
