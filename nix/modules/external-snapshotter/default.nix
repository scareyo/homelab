{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.external-snapshotter;
in
{
  options = with lib; {
    scarey.k8s.external-snapshotter.enable = mkEnableOption "Enable CSI Snapshotter";

    scarey.k8s.external-snapshotter.syncWave = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Argo CD application sync wave";
    };
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-snapshotter = {
      namespace = "kube-system";

      annotations = lib.mkIf (cfg.syncWave != null) {
        "argocd.argoproj.io/sync-wave" = "${cfg.syncWave}";
      };

      helm.releases.snapshot-controller = {
        chart = charts.piraeus.snapshot-controller;
      };
    };
  };
}
