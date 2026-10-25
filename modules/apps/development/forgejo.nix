{
  flake.modules.apps.forgejo = { lib, ... }: let
    namespace = "forgejo";
    project = "development";
    charts.forgejo = {
      repo = "oci://code.forgejo.org/forgejo-helm";
      chart = "forgejo";
      version = "17.3.1";
      chartHash = "sha256-wDB8GZtXVQ0gbM+PvViQ42FdEpvRBfNJn3vd67qMC4o=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.forgejo = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.forgejo = {
        chart = chart.forgejo;
        values = {
          gitea = {
            admin.existingSecret = "admin";
            config = {
              APP_NAME = "scarey.dev";
              server = {
                ROOT_URL = "https://scarey.dev";
                DOMAIN = "scarey.dev";
                SSH_DOMAIN = "scarey.dev";
              };

              service.DISABLE_REGISTRATION = true;

              oauth2_client = {
                ENABLE_AUTO_REGISTRATION = true;
                UPDATE_AVATAR = true;
              };

              database = {
                DB_TYPE = "postgres";
              };

              actions.ENABLED = true;

              ui = {
                THEMES = "scarey,forgejo-auto,forgejo-light,forgejo-dark";
                DEFAULT_THEME = "scarey";
              };
            };
            oauth = [
              {
                name = "Pocket ID";
                provider = "openidConnect";
                existingSecret = "forgejo-oidc-credentials";
                autoDiscoverUrl = "https://id.vegapunk.cloud/.well-known/openid-configuration";
                iconUrl = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pocket-id-light.svg";
                scopes = "email profile";
              }
            ];
            additionalConfigFromEnvs = [
              {
                name = "FORGEJO__DATABASE__HOST";
                valueFrom.secretKeyRef = {
                  key = "host";
                  name = "forgejo-db-app";
                };
              }
              {
                name = "FORGEJO__DATABASE__NAME";
                valueFrom.secretKeyRef = {
                  key = "dbname";
                  name = "forgejo-db-app";
                };
              }
              {
                name = "FORGEJO__DATABASE__USER";
                valueFrom.secretKeyRef = {
                  key = "username";
                  name = "forgejo-db-app";
                };
              }
              {
                name = "FORGEJO__DATABASE__PASSWD";
                valueFrom.secretKeyRef = {
                  key = "password";
                  name = "forgejo-db-app";
                };
              }
            ];
          };

          extraVolumes = [ { name = "theme"; configMap.name = "forgejo-theme"; } ];
          extraContainerVolumeMounts = [
            {
              name = "theme";
              mountPath = "/data/gitea/public/assets/css/theme-scarey.css";
              subPath = "theme-scarey.css";
            }
          ];

          httpRoute = {
            enabled = true;
            hostnames = [ "scarey.dev" ];
            parentRefs = [ { name = "internal"; namespace = "gateway"; } ];
          };
        };
      };

      templates.postgres.forgejo-db = {
        instances = 3;
        size = "256Gi";
      };

      templates.backup.daily = {
        restore = true;
        schedule = "0 6 * * *"; # At 06:00 daily
        ttl = "360h";           # 15 days
      };

      templates.externalSecret.admin.secrets = {
        username.key = "/forgejo/ADMIN_USERNAME";
        password.key = "/forgejo/ADMIN_PASSWORD";
      };

      resources.configMaps.forgejo-theme.data."theme-scarey.css" =
        builtins.readFile ./forgejo/theme-scarey.css;

      resources.pocketIDOIDCClients.forgejo = {
        spec = {
          name = "Forgejo";
          description = "A self-hosted lightweight software forge";
          launchUrl = "https://scarey.dev";
          callbackUrls = [ "https://scarey.dev/user/oauth2/Pocket%20ID/callback" ];
          secret = {
            keys.clientID = "key";
            keys.clientSecret = "secret";
          };
        };
      };

      resources.tcpRoutes.forgejo-ssh = {
        spec = {
          parentRefs = [
            {
              name = "internal";
              namespace = "gateway";
              sectionName = "dev-scarey-tcp";
            }
          ];
          rules = [
            {
              backendRefs = [
                { group = ""; kind = "Service"; name = "forgejo-ssh"; port = 22; }
              ];
            }
          ];
        };
      };
    };
  };
}
