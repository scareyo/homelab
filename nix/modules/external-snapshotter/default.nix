{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.external-snapshotter;
in
{
  options = with lib; {
    scarey.k8s.external-snapshotter.enable = mkEnableOption "Enable CSI Snapshotter";
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-snapshotter = {
      namespace = "kube-system";

      helm.releases.snapshot-controller = {
        chart = charts.piraeus.snapshot-controller;
      };
    };
  };
}
