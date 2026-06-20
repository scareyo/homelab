{ charts, config, generators, lib, ... }:

let
  cfg = config.vegapunk.external-secrets;
  namespace = "external-secrets";
  project = "system";
  chart = charts.external-secrets;
in
{
  options = {
    vegapunk.external-secrets.enable = lib.mkEnableOption "Enable External Secrets";
  };
  
  config = lib.mkIf cfg.enable {
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

      resources = import ./resources.nix;
    };
  };
}
