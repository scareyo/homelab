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
        values = {
          secrets.huggingface.name = "huggingface";
        };
      };

      helm.releases.models = {
        chart = charts.kubeai-models;
        values = {
          catalog."deepseek-r1-distill-qwen-1.5b-rtx4070".enabled = true;
        };
      };

      templates.app.kubeai.route = {
        serviceName = "kubeai";
      };

      templates.app.chat.route = {
        serviceName = "open-webui";
      };

      templates.externalSecret.huggingface = {
        keys = [
          { source = "/kubeai/HUGGING_FACE_TOKEN"; dest = "token"; }
        ];
      };
    };
  };
}
