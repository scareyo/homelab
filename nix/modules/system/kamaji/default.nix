{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.kamaji;
  namespace = "kamaji-system";
  project = "system";
in
{
  options = {
    vegapunk.kamaji.enable = lib.mkEnableOption "Enable Kamaji";
  };

  config = lib.mkIf cfg.enable {
    applications.kamaji = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.kamaji = {
        chart = charts.kamaji;
      };
    };
  };
}
