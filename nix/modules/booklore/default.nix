{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.booklore;
  namespace = "booklore";
in
{
  options = {
    vegapunk.booklore.enable = lib.mkEnableOption "Enable Komga";
  };

  config = lib.mkIf cfg.enable {
    applications.booklore = {
      namespace = namespace;
      createNamespace = true;

      helm.releases.booklore-db = {
        chart = charts.mariadb-cluster;
        values = {
          mariadb = {
            storage.size = "64Gi";
            replicas = 3;
            replication.enabled = true;
            galera.enabled = false;
          };
          databases = [
            {
              name = "booklore";
              characterSet = "utf8";
              collate = "utf8_general_ci";
              cleanupPolicy = "Delete";
              requeueInterval = "10h";
              retryInterval = "30s";
            }
          ];
          users = [
            {
              name = "booklore";
              passwordSecretKeyRef = {
                name = "mariadb";
                key = "password";
              };
              host = "%";
              cleanupPolicy = "Delete";
              requeueInterval = "10h";
              retryInterval = "30s";
            }
          ];
          grants = [
            {
              name = "booklore";
              username = "booklore";
              database = "booklore";
              privileges = ["ALL PRIVILEGES"];
              grantOption = true;
              host = "%";
              cleanupPolicy = "Delete";
              requeueInterval = "10h";
              retryInterval = "30s";
            }
          ];
        };
      };

      templates.app.booklore = {
        inherit namespace;

        workload = {
          image = "ghcr.io/booklore-app/booklore";
          version = "v1.16.3";
          port = 6060;
          env = {
            TZ = "America/New_York";
            BOOKLORE_PORT = "6060";
            DATABASE_URL = "jdbc:mariadb://booklore-db-mariadb-cluster:3306/booklore";
            DATABASE_USERNAME = "booklore";
            DATABASE_PASSWORD = {
              secretKeyRef = {
                key = "password";
                name = "mariadb";
              };
            };
          };
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/app/data";
            config = {
              size = "4Gi";
            };
          };
          books = {
            type = "nfs";
            path = "/mnt/books";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/books";
              readOnly = false;
            };
          };
          downloads = {
            type = "nfs";
            path = "/bookdrop";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/downloads";
              readOnly = false;
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

      templates.externalSecret.mariadb = {
        keys = [
          { source = "/booklore/DB_PASSWORD"; dest = "password"; }
          { source = "/booklore/DB_ROOT_PASSWORD"; dest = "root-password"; }
        ];
      };

      # FIXME: Remove this once BookLore removes nginx
      resources.deployments.booklore.spec.template.spec.containers.booklore.securityContext = lib.mkForce {};
      resources.deployments.booklore.spec.template.spec.securityContext = lib.mkForce {};
    };
  };
}
