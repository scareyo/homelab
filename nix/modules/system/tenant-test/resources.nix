{
  tenantControlPlanes.tenant-test = {
    metadata.labels."tenant.clastix.io" = "tenant-test";
    spec = {
      dataStore = "default";
      controlPlane = {
        deployment = {
          replicas = 3;
          additionalMetadata.labels."tenant.clastix.io" = "tenant-test";
        };
        service = {
          additionalMetadata = {
            labels."tenant.clastix.io" = "tenant-test";
            annotations."lbipam.cilium.io/ips" = "10.10.21.20";
          };
          serviceType = "LoadBalancer";
        };
      };
      kubernetes = {
        version = "v1.35.0";
        kubelet.cgroupfs = "systemd";
      };
      networkProfile = {
        port = 6443;
      };
    };
  };
}
