{
  flake.modules.apps.cilium = { generators, lib, pkgs, ... }: let
    namespace = "kube-system";
    project = "system";
    chart = lib.helm.downloadHelmChart {
      repo = "https://helm.cilium.io";
      chart = "cilium";
      version = "1.20.2";
      chartHash = "sha256-B6yOW8FluRJEF+/bvVvsobW6zUhE2WYE1lprZI/s95U=";
    };
  in {
    nixidy.applicationImports = [
      (generators.fromCRDModule {
        name = "cilium";
        src = pkgs.fetchFromGitHub {
          owner = "cilium";
          repo = "cilium";
          rev = "v1.20.0";
          hash = "sha256-iL41chnyFQIH1i6xHUdtkpwzJxDutw3of+8fvEd4B64=";
        };
        crdFiles = [
          "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpadvertisements.yaml"
          "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpclusterconfigs.yaml"
          "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgppeerconfigs.yaml"
          "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumloadbalancerippools.yaml"
        ];
      })
    ];

    applications.cilium = {
      inherit namespace project;

      helm.releases.cilium = {
        inherit chart;

        values = {
          ipam.mode = "kubernetes";
          kubeProxyReplacement = true;

          k8sServiceHost = "localhost";
          k8sServicePort = 7445;

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

          bgpControlPlane.enabled = true;

          hubble = {
            relay.enabled = true;
            ui.enabled = true;
            tls.auto.method = "cronJob";
          };
        };
      };

      resources = {
        ciliumBGPAdvertisements.default = {
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

        ciliumBGPClusterConfigs.default = {
          metadata = {
            name = "default";
          };
          spec = {
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

        ciliumBGPPeerConfigs.default = {
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

        ciliumLoadBalancerIPPools.default = {
          metadata = {
            name = "default";
            labels.bgp = "default";
          };
          spec = {
            blocks = [{ cidr = "10.10.21.0/24"; }];
            allowFirstLastIPs = "No";
          };
        };
      };
    };
  };
}
