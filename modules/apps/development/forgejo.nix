{
  flake.modules.apps.forgejo = { lib, ... }: let
    namespace = "forgejo";
    project = "development";
    charts.forgejo = {
      repo = "oci://code.forgejo.org/forgejo-helm";
      chart = "forgejo";
      version = "17.2.0";
      chartHash = "sha256-BESPtfcOgn2/bV9nDNGDvY9Fbxpd6u02h/1W0HE46eg=";
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
              server.ROOT_URL = "https://scarey.dev";
              server.DOMAIN = "scarey.dev";
              server.SSH_DOMAIN = "scarey.dev";
              service.DISABLE_REGISTRATION = true;

              oauth2_client.ENABLE_AUTO_REGISTRATION = true;
              oauth2_client.UPDATE_AVATAR = true;

              database = {
                DB_TYPE = "postgres";
              };

              webhook.ALLOWED_HOST_LIST = "ci.vegapunk.cloud";

              actions.ENABLED = false;
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
        };
      };

      templates.app.forgejo.route = {
        hostname = "scarey.dev";
        serviceName = "forgejo-http";
        servicePort = 3000;
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
