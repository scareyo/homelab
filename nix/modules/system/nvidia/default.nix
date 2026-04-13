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
          toolkit.enabled = false;
          #toolkit.env = [ 
          #  { name = "CONTAINERD_CONFIG"; value = "/var/lib/rancher/k3s/agent/etc/containerd/config.toml"; }
          #  { name = "CONTAINERD_SOCKET"; value = "/run/k3s/containerd/containerd.sock"; }
          #];
          dcgmExporter.serviceMonitor.enabled = true;
          operator = {
            repository = "dev.vegapunk.cloud/scarey";
            image = "gpu-operator";
            version = "4485e9d4b589089370819bddb2cfa396cdd12b78";
          };
          validator = {
            repository = "dev.vegapunk.cloud/scarey";
            image = "gpu-operator";
            version = "4485e9d4b589089370819bddb2cfa396cdd12b78";
            driver.env = [
              { name = "DISABLE_DEV_CHAR_SYMLINK_CREATION"; value = "true"; }
            ];
          };
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
