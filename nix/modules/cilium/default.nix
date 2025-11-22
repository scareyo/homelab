{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.cilium;
in
{
  options = with lib; {
    scarey.k8s.cilium.enable = mkEnableOption "Enable Cilium";
  };
  
  config = lib.mkIf cfg.enable {
    applications.cilium = {
      namespace = "kube-system";

      syncPolicy.autoSync.enable = true;

      helm.releases.cilium = {
        chart = charts.cilium.cilium;
        values = {
          ipam.mode = "kubernetes";
          kubeProxyReplacement = true;
          securityContext.capabilities = {
            ciliumAgent = [
              "CHOWN" "KILL" "NET_ADMIN" "NET_RAW" "IPC_LOCK" "SYS_ADMIN" "SYS_RESOURCE" "DAC_OVERRIDE" "FOWNER" "SETGID" "SETUID"
            ];
            cleanCiliumState = [
              "NET_ADMIN" "SYS_ADMIN" "SYS_RESOURCE"
            ];
          };
          cgroup = {
            autoMount.enabled = false;
            hostRoot = "/sys/fs/cgroup";
          };
          k8sServiceHost = "localhost";
          k8sServicePort = 7445;
          defaultLBServiceIPAM = "none";
          bgpControlPlane.enabled = true;
          gatewayAPI.enabled = true;
          hubble = {
            relay.enabled = true;
            ui.enabled = true;
          };
        };
      };

      templates.httpRoute.hubble = {
        hostname = "hubble.vegapunk.cloud";
        serviceName = "hubble-ui";
      };

      resources = lib.mkMerge [
        (import ./bgp-config.nix)
        (import ./gateway-config.nix)
      ];
    };
  };
}
