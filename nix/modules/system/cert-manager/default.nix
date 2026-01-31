{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.cert-manager;
  namespace = "cert-manager";
  project = "system";
in
{
  options = {
    vegapunk.cert-manager.enable = lib.mkEnableOption "Enable cert-manager";
  };
  
  config = lib.mkIf cfg.enable {
    applications.cert-manager = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.cert-manager = {
        chart = charts.cert-manager;
        values = import ./values.nix;
      };

      templates.externalSecret.cloudflare = {
        keys = [
          { source = "/cloudflare/API_TOKEN"; dest = "token"; }
        ];
      };

      resources = import ./resources.nix;
    };
  };
}
