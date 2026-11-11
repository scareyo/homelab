{
  flake.modules.apps.external-secrets = { generators, lib, ... }: let
    namespace = "external-secrets";
    project = "system";
    charts.external-secrets = {
      repo = "oci://ghcr.io/external-secrets/charts";
      chart = "external-secrets";
      version = "2.15.0";
      chartHash = "sha256-tno2Wui3wsZSY/edmP+OttKIb/V1dueB5GTIwVaicu0=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.external-secrets;
        name = "external-secrets";
        kindFilter = [ "ClusterSecretStore" "ExternalSecret" "Password" "PushSecret" "SecretStore" ];
      })
    ];

    applications.external-secrets = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.external-secrets = {
        chart = chart.external-secrets;
        values = {
          serviceMonitor.enabled = true;
        };
      };

      resources = {
        # Bound per namespace by the externalSecret template's kubernetes provider
        clusterRoles.external-secrets-kubernetes = {
          rules = [
            {
              apiGroups = [ "" ];
              resources = [ "secrets" ];
              verbs = [ "get" "list" "watch" ];
            }
            {
              apiGroups = [ "authorization.k8s.io" ];
              resources = [ "selfsubjectrulesreviews" ];
              verbs = [ "create" ];
            }
          ];
        };

        clusterSecretStores.infisical = {
          spec = {
            provider.infisical = {
              auth = {
                universalAuthCredentials = {
                  clientId = {
                    key = "client-id";
                    namespace = "external-secrets";
                    name = "infisical";
                  };
                  clientSecret = {
                    key = "client-secret";
                    namespace = "external-secrets";
                    name = "infisical";
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
