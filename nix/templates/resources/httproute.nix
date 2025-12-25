{ lib, labels, name, route }:

{
  metadata = {
    inherit labels;

    annotations = {
      "argocd.argoproj.io/sync-wave" = "10";
    };
  };
  spec = {
    parentRefs = [
      {
        group = "gateway.networking.k8s.io";
        kind = "Gateway";
        name = route.gateway;
        namespace = "gateway";
      }
    ];
    hostnames = [
      (if route.hostname == null then "${name}.vegapunk.cloud" else route.hostname)
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
          ({
            group = "";
            kind = "Service";
            name = route.serviceName;
            port = route.servicePort;
            weight = 1;
          } // lib.optionalAttrs (route.serviceName == null) {
            name = name;
          } // lib.optionalAttrs route.auth.enable {
            name = "oauth2-proxy";
          })
        ];
      }
    ];
  };
}
