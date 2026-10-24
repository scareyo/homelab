{
  flake.modules.apps.redis-operator = { generators, lib, pkgs, ... }: let
    namespace = "redis-operator";
    project = "system";
    charts.redis-operator = {
      repo = "oci://ghcr.io/ot-container-kit/charts";
      chart = "redis-operator";
      version = "0.27.0";
      chartHash = "sha256-ngNmB9+jZ/ABlgbMRA7P5EU/sw+fA1gbLFgXQZSZLb0=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.redis-operator;
        name = "redis-operator";
        kindFilter = [ "RedisCluster" ];
      })
    ];

    applications.redis-operator = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.redis-operator = {
        chart = chart.redis-operator;
      };

      resources.configMaps.redis-operator-dashboard = {
        metadata.labels.grafana_dashboard = "1";
        data."dashboard.json" = builtins.readFile (
          pkgs.fetchurl {
            url = "https://grafana.com/api/dashboards/16056/revisions/1/download";
            hash = "sha256-11KzX7vvpMrjKklXGSb67rTVAZ9U7R1bJMpgc/EJx88="; 
          }
        );
      };
    };
  };
}
