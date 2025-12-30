{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.newt;
  namespace = "newt";
in
{
  options = {
    vegapunk.newt.enable = lib.mkEnableOption "Enable Newt";
  };

  config = lib.mkIf cfg.enable {
    applications.newt = {
      namespace = namespace;
      createNamespace = true;

      helm.releases.newt = {
        chart = charts.newt;
        values = {
          newtInstances = [
            {
              name = "main";
              enabled = true;
              auth = {
                existingSecretName = "newt";
                keys = {
                  endpointKey = "pangolin-url";
                  idKey = "newt-id";
                  secretKey = "newt-secret";
                };
              };
            }
          ];
        };
      };

      templates.externalSecret.newt = {
        keys = [
          { source = "/fossorial/PANGOLIN_URL"; dest = "pangolin-url"; }
          { source = "/fossorial/NEWT_ID"; dest = "newt-id"; }
          { source = "/fossorial/NEWT_SECRET"; dest = "newt-secret"; }
        ];
      };

      resources = {
        namespaces.${namespace} = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
