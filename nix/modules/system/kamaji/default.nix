{ charts, config, generators, lib, ... }:

let
  cfg = config.vegapunk.kamaji;
  namespace = "kamaji-system";
  project = "system";
  chart = charts.kamaji;
in
{
  options = {
    vegapunk.kamaji.enable = lib.mkEnableOption "Enable Kamaji";
  };

  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        inherit chart;
        name = "kamaji";
        kindFilter = [ "TenantControlPlane" ];
      })
    ];

    applications.kamaji = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.kamaji = {
        inherit chart;
      };
    };
  };
}
