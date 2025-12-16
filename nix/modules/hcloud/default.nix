{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.hcloud;
in
{
  options = {
    vegapunk.hcloud.enable = lib.mkEnableOption "Enable Hetzner Cloud Controller Manager";
  };

  config = lib.mkIf cfg.enable {
    applications.hcloud = {
      namespace = "hcloud";
      createNamespace = true;

      helm.releases.hcloud = {
        chart = charts.hcloud-cloud-controller-manager;
        values = import ./values.nix;
      };

      templates.externalSecret.hcloud = {
        keys = [
          { source = "/hcloud/API_TOKEN"; dest = "token"; }
        ];
      };
    };
  };
}
