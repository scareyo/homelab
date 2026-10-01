{
  flake.modules.apps.cnpg = { generators, lib, ... }: let
    namespace = "cnpg";
    project = "system";
    chart = lib.helm.downloadHelmChart {
      repo = "oci://ghcr.io/cloudnative-pg/charts";
      chart = "cloudnative-pg";
      version = "0.29.1";
      chartHash = "sha256-VWDikb5gw9s35yZYk3BqcojQtEE/b3gdDN6TCcJXzZ4=";
    };
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        inherit chart;
        name = "cnpg";
        kindFilter = [ "Cluster" "Database" ];
      })
    ];

    applications.cnpg = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.cnpg = {
        inherit chart;
        values = {
          #monitoring = {
          #  podMonitorEnabled = true;
          #  grafanaDashboard = {
          #    create = true;
          #  };
          #};
        };
      };
    };
  };
}
