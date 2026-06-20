{ charts, config, generators, lib, ... }:

let
  cfg = config.vegapunk.cnpg;
  namespace = "cnpg";
  project = "system";
  chart = charts.cloudnative-pg;
in
{
  options = {
    vegapunk.cnpg.enable = lib.mkEnableOption "Enable CloudNativePG";
  };

  config = lib.mkIf cfg.enable {
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
