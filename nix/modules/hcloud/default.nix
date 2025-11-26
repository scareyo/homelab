{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.hcloud;
in
{
  options = with lib; {
    scarey.k8s.hcloud.enable = mkEnableOption "Enable Hetzner Cloud Controller Manager";

    scarey.k8s.hcloud.syncWave = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Argo CD application sync wave";
    };
  };

  config = lib.mkIf cfg.enable {
    applications.hcloud = {
      namespace = "hcloud";
      createNamespace = true;

      annotations = lib.mkIf (cfg.syncWave != null) {
        "argocd.argoproj.io/sync-wave" = "${cfg.syncWave}";
      };

      helm.releases.hcloud = {
        chart = charts.hcloud.hcloud-cloud-controller-manager;
        values = {
          nodeSelector."kubernetes.io/hostname" = "zeus";
          additionalTolerations = [
            { key = "hcloud"; operator = "Equal"; effect = "NoSchedule"; }
          ];
        };
      };

      templates.externalSecret.hcloud = {
        keys = [
          { source = "/hcloud/API_TOKEN"; dest = "token"; }
        ];
      };
    };
  };
}
