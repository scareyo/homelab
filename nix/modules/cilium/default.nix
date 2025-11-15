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

      resources = {
        "cilium.io".v2.CiliumBGPAdvertisement.default = {
          metadata = {
            name = "default";
            labels = {
              advertise = "bgp";
            };
          };
          spec = {
            advertisements = [
              {
                advertisementType = "Service";
                service.addresses = [
                  "LoadBalancerIP"
                ];
                selector.matchExpressions = [
                  { key = "somekey"; operator = "NotIn"; values = ["never-used-value"]; }
                ];
              }
            ];
          };
        };
        "cilium.io".v2.CiliumBGPClusterConfig.default = {
          metadata = {
            name = "default";
          };
          spec = {
            nodeSelector.matchLabels.platform = "metal";
            bgpInstances = [
              {
                name = "default";
                localASN = 65001;
                peers = [
                  {
                    name = "stella";
                    peerASN = 65000;
                    peerAddress = "10.10.20.1";
                    peerConfigRef.name = "default";
                  }
                ];
              }
            ];
          };
        };
        "cilium.io".v2.CiliumBGPPeerConfig.default = {
          metadata = {
            name = "default";
          };
          spec = {
            gracefulRestart = {
              enabled = true;
              restartTimeSeconds = 15;
            };
            families = [
              {
                afi = "ipv4";
                safi = "unicast";
                advertisements.matchLabels.advertise = "bgp";
              }
            ];
          };
        };
        "cilium.io".v2.CiliumLoadBalancerIPPool.default = {
          metadata = {
            name = "default";
            labels.bgp = "default";
          };
          spec = {
            blocks = [{ cidr = "10.10.21.0/24"; }];
            allowFirstLastIPs = "No";
          };
        };
        "cilium.io".v2alpha1.CiliumGatewayClassConfig.internal = {
          metadata.name = "internal";
          spec.service.loadBalancerClass = "io.cilium/bgp-control-plane";
        };
        "gateway.networking.k8s.io".v1.GatewayClass.internal = {
          metadata.name = "internal";
          spec = {
            controllerName = "io.cilium/gateway-controller";
            description = "The internal Cilium GatewayClass";
            parametersRef = {
              group = "cilium.io";
              kind = "CiliumGatewayClassConfig";
              name = "internal";
              namespace = "kube-system";
            };
          };
        };
      };
    };
  };
}
