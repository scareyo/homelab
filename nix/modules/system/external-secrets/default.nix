{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.external-secrets;
  namespace = "external-secrets";
  project = "system";
in
{
  options = {
    vegapunk.external-secrets.enable = lib.mkEnableOption "Enable External Secrets";
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-secrets = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.external-secrets = {
        chart = charts.external-secrets;
      };

      resources = import ./resources.nix;
    };
  };
}
