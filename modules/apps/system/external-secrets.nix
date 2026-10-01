{
  flake.modules.apps.external-secrets = { generators, lib, ... }: let
    namespace = "external-secrets";
    project = "system";
    chart = lib.helm.downloadHelmChart {
      repo = "https://external-secrets.io";
      chart = "external-secrets";
      version = "2.3.0";
      chartHash = "sha256-T5URYFJr3BY3eNZYPAhbEzc2cs9rZRoG8sruETguwiQ=";
    };
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        inherit chart;
        name = "external-secrets";
        kindFilter = [ "ClusterSecretStore" "ExternalSecret" "Password" ];
      })
    ];

    applications.external-secrets = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.external-secrets = {
        inherit chart;
        values = {
          serviceMonitor.enabled = true;
        };
      };

      resources.clusterSecretStores.openbao = {
        spec = {
          provider.vault = {
            server = "http://openbao.openbao.svc.cluster.local:8200";
            namespace = "seraphim";
            path = "secret";
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
