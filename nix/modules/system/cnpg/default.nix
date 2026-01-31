{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.cnpg;
  namespace = "cnpg";
  project = "system";
in
{
  options = {
    vegapunk.cnpg.enable = lib.mkEnableOption "Enable CloudNativePG";
  };

  config = lib.mkIf cfg.enable {
    applications.cnpg = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.cnpg = {
        chart = charts.cloudnative-pg;
      };
    };
  };
}
