{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.kgateway;
  namespace = "kgateway-system";
in
{
  options = {
    vegapunk.kgateway.enable = lib.mkEnableOption "Enable kgateway";
  };

  config = lib.mkIf cfg.enable {
    applications.kgateway = {
      inherit namespace;
      createNamespace = true;

      helm.releases.kgateway-crds = {
        chart = charts.kgateway-crds;
      };

      helm.releases.kgateway = {
        chart = charts.kgateway;
        values = import ./values.nix;
      };
    };
  };
}
