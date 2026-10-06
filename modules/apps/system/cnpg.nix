{
  flake.modules.apps.cnpg = { generators, lib, ... }: let
    namespace = "cnpg";
    project = "system";
    charts.cnpg = {
      repo = "oci://ghcr.io/cloudnative-pg/charts";
      chart = "cloudnative-pg";
      version = "0.29.1";
      chartHash = "sha256-VWDikb5gw9s35yZYk3BqcojQtEE/b3gdDN6TCcJXzZ4=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.cnpg;
        name = "cnpg";
        kindFilter = [ "Cluster" "Database" ];
      })
    ];

    applications.cnpg = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.cnpg = {
        chart = chart.cnpg;
        values = {
          monitoring = {
            podMonitorEnabled = true;
            grafanaDashboard = {
              create = true;
            };
          };
        };
      };
    };
  };
}
