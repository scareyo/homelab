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

      createNamespace = true;

      helm.releases.kubeai = {
        chart = charts.kubeai;
      };

      templates.app.kubeai.route = {
        serviceName = "kubeai";
      };

      templates.app.chat.route = {
        serviceName = "open-webui";
      };
    };
  };
}
