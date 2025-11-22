{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.pocket-id;
in
{
  options = with lib; {
    scarey.k8s.pocket-id.enable = mkEnableOption "Enable Pocket ID";
  };

  config = lib.mkIf cfg.enable {
    applications.pocket-id = {
      namespace = "pocket-id";
      createNamespace = true;

      helm.releases.pocket-id = {
        chart = charts.anza-labs.pocket-id;
        values = {
          host = "id.scarey.me";
          timeZone = "America/New_York";
          database = {
            provider = "postgres";
            connectionString = "postgres://";
          };
        };
      };

      templates.httpRoute.pocket-id = {
        hostname = "id.scarey.me";
        serviceName = "pocket-id";
        gateway = "external";
      };

      templates.postgres.postgres = {
        instances = 3;
        size = "32Gi";
      };

      templates.backup.pocket-id-daily = {
        restore = true;
        schedule = "0 4 * * *";
        ttl = "168h0m0s"; # 1 week
        includedNamespaces = [
          "pocket-id"
        ];
      };

      templates.backup.pocket-id-quarterly = {
        schedule = "0 0 1 1,4,7,10 *";
        ttl = "8760h0m0s"; # 1 year
        includedNamespaces = [
          "pocket-id"
        ];
      };

      resources.apps.v1.StatefulSet.pocket-id.spec.template.spec.containers = [
        {
          name = "pocket-id";
          env = [
            {
              name = "DB_CONNECTION_STRING";
              valueFrom.secretKeyRef = {
                name = "postgres-app";
                key = "uri";
              };
            }
          ];
        }
      ];
    };
  };
}
