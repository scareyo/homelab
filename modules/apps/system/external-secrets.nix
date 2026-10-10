{
  flake.modules.apps.external-secrets = { generators, lib, ... }: let
    namespace = "external-secrets";
    project = "system";
    charts.external-secrets = {
      repo = "https://external-secrets.io";
      chart = "external-secrets";
      version = "2.3.0";
      chartHash = "sha256-T5URYFJr3BY3eNZYPAhbEzc2cs9rZRoG8sruETguwiQ=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.external-secrets;
        name = "external-secrets";
        kindFilter = [ "ClusterSecretStore" "ExternalSecret" "Password" ];
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
