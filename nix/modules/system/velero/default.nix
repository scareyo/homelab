{ charts, config, generators, lib, ... }:

let
  cfg = config.vegapunk.velero;
  namespace = "velero";
  project = "system";
  chart = charts.velero;
in
{
  options = {
    vegapunk.velero.enable = lib.mkEnableOption "Enable Velero";
  };
  
  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        inherit chart;
        name = "velero";
        kindFilter = [ "Restore" "Schedule" ];
      })
    ];

    applications.velero = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.velero = {
        inherit chart;
        values = import ./values.nix;
      };

      templates.externalSecret.backblaze = {
        keys = [
          { source = "/velero/BACKBLAZE_KEY"; dest = "key"; }
        ];
      };

      templates.externalSecret.garage = {
        keys = [
          { source = "/velero/GARAGE_KEY"; dest = "key"; }
        ];
      };

      resources = {
        namespaces.velero = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
