{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.cilium;
  namespace = "kube-system";
  project = "system";
in
{
  options = {
    vegapunk.cilium.enable = lib.mkEnableOption "Enable Cilium";
  };
  
  config = lib.mkIf cfg.enable {
    applications.cilium = {
      inherit namespace project;

      helm.releases.cilium = {
        chart = charts.cilium;
        values = import ./values.nix;
      };

      templates.app.hubble.route = {
        serviceName = "hubble-ui";
      };

      resources = import ./resources.nix;
    };
  };
}
