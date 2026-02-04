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
          resourceProfiles = {
            rtx3080 = {
              imageName = "nvidia-gpu";
              nodeSelector = {
                "kubernetes.io/hostname" = "s-flamingo";
              };
              limits."nvidia.com/gpu" = "1";
              requests = {
                "nvidia.com/gpu" = "1";
              };
              runtimeClassName = "nvidia";
            };
          };
        };
      };

      helm.releases.models = {
        chart = charts.kubeai-models;
        values = {
          catalog."deepseek-r1-distill-qwen-1.5b-rtx4070" = {
            enabled = true;
            resourceProfile = "rtx3080:1";
          };
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
