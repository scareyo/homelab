{
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
}
