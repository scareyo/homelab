{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.external-snapshotter;
in
{
  options = {
    vegapunk.external-snapshotter.enable = lib.mkEnableOption "Enable CSI Snapshotter";
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-snapshotter = {
      namespace = "kube-system";

      helm.releases.snapshot-controller = {
        chart = charts.snapshot-controller;
      };
    };
  };
}
