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

      resources.clusterSecretStores.openbao = {
        spec = {
          provider.vault = {
            server = "http://openbao.openbao.svc.cluster.local:8200";
            namespace = "seraphim";
            path = "kv";
            version = "v2";
            auth.kubernetes = {
              mountPath = "kubernetes";
              role = "external-secrets";
              serviceAccountRef = {
                name = "openbao";
                namespace = "external-secrets";
              };
            };
          };
        };
      };

      resources.serviceAccounts.openbao = {};
    };
  };
}
