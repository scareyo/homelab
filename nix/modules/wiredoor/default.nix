{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.wiredoor;
  namespace = "wiredoor";
in
{
  options = {
    vegapunk.wiredoor.enable = lib.mkEnableOption "Enable Wiredoor";
  };

  config = lib.mkIf cfg.enable {
    applications.wiredoor = {
      namespace = namespace;
      createNamespace = true;

      helm.releases.wiredoor = {
        chart = charts.wiredoor;
      };

      templates.externalSecret.wiredoor = {
        keys = [
          { source = "/wiredoor/URL"; dest = "WIREDOOR_URL"; }
          { source = "/wiredoor/TOKEN"; dest = "TOKEN"; }
        ];
      };

      resources = {
        namespaces.${namespace} = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };

        deployments."wiredoor-wiredoor-gateway" = {
          spec = {
            template.spec.containers.wiredoor-gateway.envFrom = [
              {
                secretRef.name = "wiredoor";
              }
            ];
          };
        };
      };
    };
  };
}
