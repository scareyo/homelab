{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.immich;
  namespace = "immich";
  project = "general";
in
{
  options = {
    vegapunk.immich.enable = lib.mkEnableOption "Enable Immich";
  };

  config = lib.mkIf cfg.enable {
    applications.immich = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.immich = {
        chart = charts.immich;
        values = import ./values.nix;
      };

      helm.releases.valkey = {
        chart = charts.valkey;
      };

      templates.app.immich = {
        inherit namespace;

        route = {
          hostname = "photos.vegapunk.cloud";
          serviceName = "immich-server";
          servicePort = 2283;
        };

        persistence = {
          library = {
            type = "pvc";
            config = {
              size = "1Ti";
            };
          };
        };

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
            location = "garage";
          };
        };
      };

      templates.postgres.immich-pg = {
        instances = 3;
        image = "ghcr.io/tensorchord/cloudnative-vectorchord:17.5-0.4.3";
        size = "8Gi";
        sharedPreloadLibraries = ["vchord.so"];
        database.extensions = [
          "cube"
          "earthdistance"
          "vchord"
          "vector"
        ];
      };

      templates.externalSecret.config = {
        keys = [
          { source = "/immich/OIDC_CLIENT_ID"; dest = "key"; }
          { source = "/immich/OIDC_CLIENT_SECRET"; dest = "secret"; }
        ];
        templates = {
          "immich-config.yaml" = ''
            oauth:
              enabled: true
              clientId: "{{ .key }}"
              clientSecret: "{{ .secret }}"
              issuerUrl: "https://id.vegapunk.cloud"
            passwordLogin:
              enabled: false
          '';
        };
      };
    };
  };
}
