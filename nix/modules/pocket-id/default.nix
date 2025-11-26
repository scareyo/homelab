{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.pocket-id;
in
{
  options = with lib; {
    scarey.k8s.pocket-id.enable = mkEnableOption "Enable Pocket ID";

    scarey.k8s.pocket-id.syncWave = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Argo CD application sync wave";
    };
  };

  config = lib.mkIf cfg.enable {
    applications.pocket-id = {
      namespace = "pocket-id";
      createNamespace = true;

      annotations = lib.mkIf (cfg.syncWave != null) {
        "argocd.argoproj.io/sync-wave" = "${cfg.syncWave}";
      };

      helm.releases.pocket-id = {
        chart = charts.anza-labs.pocket-id;
        values = {
          host = "id.vegapunk.cloud";
          timeZone = "America/New_York";
          database = {
            provider = "postgres";
            connectionString = "postgres://";
          };
        };
      };

      templates.httpRoute.pocket-id-int = {
        hostname = "id.vegapunk.cloud";
        serviceName = "pocket-id";
        gateway = "internal";
      };

      templates.httpRoute.pocket-id-ext = {
        hostname = "id.vegapunk.cloud";
        serviceName = "pocket-id";
        gateway = "external";
      };

      templates.postgres.pocket-id = {
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

      ignoreDifferences.maxUnavailable = {
        group = "apps";
        kind = "StatefulSet";
        jqPathExpressions = [ ".spec.updateStrategy.rollingUpdate.maxUnavailable" ];
      };

      resources.apps.v1.StatefulSet.pocket-id.spec.template.spec.containers = [
        {
          name = "pocket-id";
          env = [
            {
              name = "DB_CONNECTION_STRING";
              valueFrom.secretKeyRef = {
                name = "pocket-id-app";
                key = "uri";
              };
            }
          ];
        }
      ];
    };
  };
}
