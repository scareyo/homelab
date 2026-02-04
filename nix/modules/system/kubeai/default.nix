{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.kubeai;
  namespace = "kubeai";
  project = "system";
in
{
  options = {
    vegapunk.kubeai.enable = lib.mkEnableOption "Enable kubeai";
  };

  config = lib.mkIf cfg.enable {
    applications.kubeai = {
      inherit namespace project;

      helm.releases.kubeai = {
        chart = charts.kubeai;
      };
    };
  };
}
