{
  flake.modules.apps.cilium = { generators, lib, pkgs, ... }: let
    namespace = "kube-system";
    project = "system";
    charts.cilium = {
      repo = "oci://quay.io/cilium/charts";
      chart = "cilium";
      version = "1.20.3";
      chartHash = "sha256-Z2McaGxaJnEw+jyI/bljUOj7f5Cg3XDbiFkVqcCWzkQ=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromCRDModule {
        name = "cilium";
        src = pkgs.fetchFromGitHub {
          name = "cilium-crds-${charts.cilium.version}";
          owner = "cilium";
          repo = "cilium";
          rev = "v${charts.cilium.version}";
          hash = "sha256-3pGgJjCYmN6tC7emy7inlxl+6ydV3LhFO+FtQ7HCUnQ=";
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
        chart = chart.cilium;

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
