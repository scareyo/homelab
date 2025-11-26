{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.cnpg;
in
{
  options = with lib; {
    scarey.k8s.cnpg.enable = mkEnableOption "Enable CloudNativePG";

    scarey.k8s.cnpg.syncWave = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Argo CD application sync wave";
    };
  };

  config = lib.mkIf cfg.enable {
    applications.cnpg = {
      namespace = "cnpg";
      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      annotations = lib.mkIf (cfg.syncWave != null) {
        "argocd.argoproj.io/sync-wave" = "${cfg.syncWave}";
      };

      helm.releases.cnpg = {
        chart = charts.cloudnative-pg.cloudnative-pg;
      };
    };
  };
}
