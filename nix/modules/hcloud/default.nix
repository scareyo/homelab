{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.hcloud;
in
{
  options = with lib; {
    scarey.k8s.hcloud.enable = mkEnableOption "Enable Hetzner Cloud Controller Manager";
  };

  config = lib.mkIf cfg.enable {
    applications.hcloud = {
      namespace = "hcloud";
      createNamespace = true;

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
