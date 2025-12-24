{ config, name }:

{
  metadata = {
    annotations = {
      "argocd.argoproj.io/sync-wave" = "10";
    };
  };
  spec = {
    parentRefs = [
      {
        group = "gateway.networking.k8s.io";
        kind = "Gateway";
        name = config.route.gateway;
        namespace = "gateway";
      }
    ];
    hostnames = [
      (if config.route.hostname == null then "${name}.vegapunk.cloud" else config.route.hostname)
    ];
    rules = [
      {
        matches = [
          {
            path = {
              type = "PathPrefix";
              value = "/";
            };
          }
        ];
        backendRefs = [
          {
            group = "";
            kind = "Service";
            name = config.route.serviceName;
            port = config.route.servicePort;
            weight = 1;
          }
        ];
      }
    ];
  };
}
