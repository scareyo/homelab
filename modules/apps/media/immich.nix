let
  images = {
    immich = {
      image = "ghcr.io/immich-app/immich-server";
      version = "v3.3.5";
    };
    pgsql = {
      image = "ghcr.io/tensorchord/cloudnative-vectorchord";
      version = "18.6";
    };
  };
in {
  flake.modules.apps.immich = { lib, ... }: let
    namespace = "immich";
    project = "media";
    charts.immich = {
      repo = "oci://ghcr.io/immich-app/immich-charts";
      chart = "immich";
      version = "0.13.4";
      chartHash = "sha256-Nj9kifEjGhulJ2+9ktv58wAFYiCLuxH9Q04TOyKC4x8=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.immich = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.immich = {
        chart = chart.immich;
        values = {
          immich = {
            configurationKind = "Secret";
            existingConfiguration = "immich";
            persistence.library.existingClaim = "immich";
          };

          controllers.main.containers.main = {
            image.tag = images.immich.version;
            env = {
              IMMICH_ALLOW_SETUP = "false";
              REDIS_HOSTNAME = "immich-cache";
              DB_HOSTNAME = {
                valueFrom.secretKeyRef = {
                  name = "immich-db-app";
                  key = "host";
                };
              };
              DB_USERNAME = {
                valueFrom.secretKeyRef = {
                  name = "immich-db-app";
                  key = "username";
                };
              };
              DB_PASSWORD = {
                valueFrom.secretKeyRef = {
                  name = "immich-db-app";
                  key = "password";
                };
              };
              DB_DATABASE_NAME = {
                valueFrom.secretKeyRef = {
                  name = "immich-db-app";
                  key = "dbname";
                };
              };
            };
          };

          server.route.main = {
            hostnames = [ "photos.vegapunk.cloud" ];
            parentRefs = [ { name = "internal"; namespace = "gateway"; } ];
          };
        };
      };

      templates.postgres.immich-db = {
        instances = 3;
        image = "${images.pgsql.image}:${images.pgsql.version}";
        size = "8Gi";
        sharedPreloadLibraries = ["vchord.so"];
        database.extensions = [
          "cube"
          "earthdistance"
          "vchord"
          "vector"
        ];
      };

      templates.redis.immich-cache = {
        size = "2Gi";
      };

      templates.externalSecret.immich = {
        secrets = {
          client_id = { provider = "kubernetes"; key = "immich-oidc-credentials"; property = "client_id"; };
          client_secret = { provider = "kubernetes"; key = "immich-oidc-credentials"; property = "client_secret"; };
        };
        templates = {
          "immich-config.yaml" = ''
            oauth:
              enabled: true
              clientId: "{{ .client_id }}"
              clientSecret: "{{ .client_secret }}"
              issuerUrl: "https://id.vegapunk.cloud"
            passwordLogin:
              enabled: false
          '';
        };
      };

      resources.pocketIDOIDCClients.immich = {
        spec = {
          name = "Immich";
          description = "Photo and video management";
          launchUrl = "https://photos.vegapunk.cloud";
          callbackUrls = [
            "app.immich:///oauth-callback"
            "https://photos.vegapunk.cloud/auth/login"
            "https://photos.vegapunk.cloud/user-settings"
          ];
        };
      };

      resources.pocketIDUserGroups.immich-admin.spec = {
        customClaims = [ { key = "immich_role"; value = "admin"; } ];
      };

      resources.persistentVolumeClaims.immich = {
        metadata.annotations."argocd.argoproj.io/sync-options" = "Prune=false,Delete=false";
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = "2Ti";
          storageClassName = "media";
        };
      };
    };
  };
}
