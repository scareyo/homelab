{ config, lib, ... }:

let
  cfg = config.vegapunk.adventurelog;
  namespace = "adventurelog";
in
{
  options = {
    vegapunk.adventurelog.enable = lib.mkEnableOption "Enable AdventureLog";
  };

  config = lib.mkIf cfg.enable {
    applications.adventurelog = {
      namespace = namespace;
      createNamespace = true;

      templates.app.adventurelog-backend = {
        inherit namespace;

        workload = {
          image = "ghcr.io/seanmorley15/adventurelog-backend";
          version = "v0.11.0";
          port = 8000;
          env = {
            PUBLIC_URL = "https://adventurelog-backend.vegapunk.cloud";
            FRONTEND_URL = "https://adventurelog.vegapunk.cloud";
            CSRF_TRUSTED_ORIGINS = "https://adventurelog.vegapunk.cloud,https://adventurelog-backend.vegapunk.cloud";
            DISABLE_REGISTRATION = "True";
            DEBUG = "True";

            DJANGO_ADMIN_USERNAME = {
              secretKeyRef = {
                key = "django-admin-username";
                name = "adventurelog";
              };
            };
            DJANGO_ADMIN_PASSWORD = {
              secretKeyRef = {
                key = "django-admin-password";
                name = "adventurelog";
              };
            };
            DJANGO_ADMIN_EMAIL = {
              secretKeyRef = {
                key = "django-admin-email";
                name = "adventurelog";
              };
            };
            SECRET_KEY = {
              secretKeyRef = {
                key = "password";
                name = "adventurelog-app";
              };
            };

            PGHOST = {
              secretKeyRef = {
                key = "host";
                name = "adventurelog-app";
              };
            };
            POSTGRES_DB = {
              secretKeyRef = {
                key = "dbname";
                name = "adventurelog-app";
              };
            };
            POSTGRES_USER = {
              secretKeyRef = {
                key = "username";
                name = "adventurelog-app";
              };
            };
            POSTGRES_PASSWORD = {
              secretKeyRef = {
                key = "password";
                name = "adventurelog-app";
              };
            };
          };
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/code/media";
            config = {
              size = "16Gi";
            };
          };
        };

        route = {};

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
        };
      };

      templates.app.adventurelog = {
        inherit namespace;

        workload = {
          image = "ghcr.io/seanmorley15/adventurelog-frontend";
          version = "v0.11.0";
          port = 3000;
          env = {
            PUBLIC_SERVER_URL = "https://adventurelog-backend.vegapunk.cloud";
            ORIGIN = "https://adventurelog.vegapunk.cloud";
            FORCE_SOCIALACCOUNT_LOGIN = "True";
          };
        };

        route = {};
      };

      templates.postgres.adventurelog = {
        instances = 3;
        image = "ghcr.io/cloudnative-pg/postgis:18-3.6-system-trixie";
        size = "64Gi";
        database.extensions = [
          "postgis"
        ];
      };

      templates.externalSecret.adventurelog = {
        keys = [
          { source = "/adventurelog/DJANGO_ADMIN_USERNAME"; dest = "django-admin-username"; }
          { source = "/adventurelog/DJANGO_ADMIN_PASSWORD"; dest = "django-admin-password"; }
          { source = "/adventurelog/DJANGO_ADMIN_EMAIL"; dest = "django-admin-email"; }
        ];
      };

      #templates.externalSecret.oidc = {
      #  keys = [
      #    { source = "/adventurelog/OIDC_CLIENT_ID"; dest = "client-id"; }
      #    { source = "/adventurelog/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
      #  ];
      #};

      # FIXME: remove if AdventureLog ever supports running rootless
      resources.deployments.adventurelog-backend.spec.template.spec.containers.adventurelog-backend.securityContext = lib.mkForce {};
      resources.deployments.adventurelog-backend.spec.template.spec.securityContext = lib.mkForce {};
    };
  };
}
