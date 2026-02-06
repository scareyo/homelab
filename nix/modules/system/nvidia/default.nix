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

      helm.releases.gpu-operator = {
        chart = charts.nvidia-gpu-operator;
        values = {
          driver.enabled = false;
          dcgmExporter.serviceMonitor.enabled = true;
        };
      };

      resources = {
        namespaces.${namespace} = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
