{
  "cilium.io".v2alpha1.CiliumGatewayClassConfig.internal = {
    metadata = {
      name = "internal";
    };
    spec = {
      service.loadBalancerClass = "io.cilium/bgp-control-plane";
    };
  };
  "gateway.networking.k8s.io".v1.GatewayClass.internal = {
    metadata = {
      name = "internal";
    };
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
}
