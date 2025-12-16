{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.velero;
in
{
  options = {
    vegapunk.velero.enable = lib.mkEnableOption "Enable Velero";
  };
  
  config = lib.mkIf cfg.enable {
    applications.velero = {
      namespace = "velero";
      createNamespace = true;

      helm.releases.velero = {
        chart = charts.velero;
        values = import ./values.nix;
      };

      templates.externalSecret.backblaze = {
        keys = [
          { source = "/velero/BACKBLAZE_KEY"; dest = "key"; }
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
