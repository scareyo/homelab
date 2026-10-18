let
  images = {
    recyclarr = {
      image = "ghcr.io/recyclarr/recyclarr";
      version = "8.8.0";
    };
  };
in {
  flake.modules.apps.recyclarr = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.recyclarr = {
      inherit namespace project;

      templates.app.recyclarr = {
        workload = {
          inherit (images.recyclarr) image version;
          type = "cronjob";
          args = [
            "sync"
            "--config"
            "/cfg/recyclarr.yaml"
          ];
          envSecret = "recyclarr";
        };
        persistence = {
          config = {
            type = "cm";
            path = "/cfg";
            config.data."recyclarr.yaml" = builtins.readFile ./recyclarr/config.yaml;
          };
        };
      };

      templates.externalSecret.recyclarr.secrets = {
        SONARR_API_KEY.key = "/recyclarr/SONARR_API_KEY";
        RADARR_API_KEY.key = "/recyclarr/RADARR_API_KEY";
      };
    };
  };
}
