{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.cnpg;
in
{
  options = with lib; {
    scarey.k8s.cnpg.enable = mkEnableOption "Enable CloudNativePG";
  };

  config = lib.mkIf cfg.enable {
    applications.cnpg = {
      namespace = "cnpg";
      createNamespace = true;

      syncPolicy.autoSync.enable = true;
      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.cnpg = {
        chart = charts.cloudnative-pg.cloudnative-pg;
      };
    };
  };
}
