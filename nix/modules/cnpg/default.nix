{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.cnpg;
in
{
  options = {
    vegapunk.cnpg.enable = lib.mkEnableOption "Enable CloudNativePG";
  };

  config = lib.mkIf cfg.enable {
    applications.cnpg = {
      namespace = "cnpg";
      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.cnpg = {
        chart = charts.cloudnative-pg;
      };
    };
  };
}
