{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.pocket-id;
  namespace = "pocket-id";
in
{
  options = {
    vegapunk.pocket-id.enable = lib.mkEnableOption "Enable Pocket ID";
  };

  config = lib.mkIf cfg.enable {
    applications.pocket-id = {
      namespace = namespace;
      createNamespace = true;

      helm.releases.pocket-id = {
        chart = charts.pocket-id;
        values = import ./values.nix;
      };

      templates.httpRoute.pocket-id-int = {
        hostname = "id.vegapunk.cloud";
        serviceName = "pocket-id";
        gateway = "internal";
      };

      templates.postgres.pocket-id = {
        instances = 3;
        size = "32Gi";
      };

      templates.app.pocket-id = {
        inherit namespace;

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
          quarterly = {
            schedule = "0 0 1 1,4,7,10 *";
            ttl = "8760h0m0s"; # 1 year
          };
        };
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
