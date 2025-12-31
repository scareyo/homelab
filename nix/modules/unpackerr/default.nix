{ config, lib, ... }:

let
  cfg = config.vegapunk.unpackerr;
  namespace = "unpackerr";
in
{
  options = {
    vegapunk.unpackerr.enable = lib.mkEnableOption "Enable Unpackerr";
  };

  config = lib.mkIf cfg.enable {
    applications.unpackerr = {
      namespace = namespace;
      createNamespace = true;

      templates.app.unpackerr = {
        inherit namespace;

        workload = {
          image = "ghcr.io/unpackerr/unpackerr";
          version = "0.14.5";
          port = 9696;
          env = {
            UN_SONARR_0_URL = "http://sonarr.sonarr";
            UN_SONARR_0_DELETE_DELAY = "-1s";
            UN_SONARR_0_SYNCTHING = "true";
            UN_SONARR_0_API_KEY = {
              secretKeyRef = {
                key = "sonarr-api-key";
                name = "unpackerr";
              };
            };
            UN_RADARR_0_URL = "http://radarr.radarr";
            UN_RADARR_0_DELETE_DELAY = "-1s";
            UN_RADARR_0_SYNCTHING = "true";
            UN_RADARR_0_API_KEY = {
              secretKeyRef = {
                key = "radarr-api-key";
                name = "unpackerr";
              };
            };
          };
        };

        persistence = {
          config = {
            type = "emptyDir";
            path = "/config";
          };
          downloads = {
            type = "nfs";
            path = "/mnt/media/downloads";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/downloads";
              readOnly = false;
            };
          };
        };
      };

      templates.externalSecret.unpackerr = {
        keys = [
          { source = "/sonarr/API_KEY"; dest = "sonarr-api-key"; }
          { source = "/radarr/API_KEY"; dest = "radarr-api-key"; }
        ];
      };
    };
  };
}
