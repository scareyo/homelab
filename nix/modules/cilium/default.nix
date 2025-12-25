{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.cilium;
in
{
  options = {
    vegapunk.cilium.enable = lib.mkEnableOption "Enable Cilium";
  };
  
  config = lib.mkIf cfg.enable {
    applications.cilium = {
      namespace = "kube-system";

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
