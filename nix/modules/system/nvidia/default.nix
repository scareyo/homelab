{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.nvidia;
  namespace = "kube-system";
  project = "system";
in
{
  options = {
    vegapunk.nvidia.enable = lib.mkEnableOption "Enable NVIDIA";
  };

  config = lib.mkIf cfg.enable {
    applications.nvidia = {
      inherit namespace project;

      helm.releases.nvdp = {
        chart = charts.nvidia-device-plugin;
        values = {
          runtimeClassName = "nvidia";
        };
      };

      resources = {
        "node.k8s.io".v1.RuntimeClass.nvidia = {
          handler = "nvidia";
          scheduling.nodeSelector = {
            "kubernetes.io/hostname" = "s-flamingo";
          };
        };
      };
    };
  };
}
