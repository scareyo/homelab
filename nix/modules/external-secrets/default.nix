{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.external-secrets;
in
{
  options = with lib; {
    scarey.k8s.external-secrets.enable = mkEnableOption "Enable External Secrets";

    scarey.k8s.external-secrets.syncWave = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Argo CD application sync wave";
    };
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-secrets = {
      namespace = "external-secrets";
      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      annotations = lib.mkIf (cfg.syncWave != null) {
        "argocd.argoproj.io/sync-wave" = "${cfg.syncWave}";
      };

      helm.releases.external-secrets = {
        chart = charts.external-secrets.external-secrets;
      };

      resources = {
        "external-secrets.io".v1.ClusterSecretStore.infisical = {
          metadata = {
            name = "infisical";
            annotations = {
              "argocd.argoproj.io/sync-wave" = "10";
            };
          };
          spec = {
            provider.infisical = {
              auth = {
                universalAuthCredentials = {
                  clientId = {
                    key = "clientId";
                    namespace = "external-secrets";
                    name = "infisical-credentials";
                  };
                  clientSecret = {
                    key = "clientSecret";
                    namespace = "external-secrets";
                    name = "infisical-credentials";
                  };
                };
              };
              secretsScope = {
                projectSlug = "homelab";
                environmentSlug = "prod";
              };
            };
          };
        };
      };
    };
  };
}
