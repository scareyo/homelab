{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.nvidia;
  namespace = "nvidia";
  project = "system";
in
{
  options = {
    vegapunk.nvidia.enable = lib.mkEnableOption "Enable NVIDIA";
  };

  config = lib.mkIf cfg.enable {
    applications.nvidia = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.nvdp = {
        chart = charts.nvidia-device-plugin;
        values = {
          runtimeClassName = "nvidia";
          gfd.enabled = true;
        };
      };

      resources = {
        namespaces.${namespace} = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };

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
