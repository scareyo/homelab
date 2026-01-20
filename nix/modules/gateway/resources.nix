{
  "gateway.networking.k8s.io".v1.Gateway.internal = {
    metadata = {
      name = "internal";
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-production";
      };
    };
    spec = {
      gatewayClassName = "kgateway";
      infrastructure.annotations."lbipam.cilium.io/ips" = "10.10.21.11";
      listeners = [
        {
          protocol = "HTTPS";
          port = 443;
          name = "cloud-vegapunk-apps-https";
          hostname = "*.vegapunk.cloud";
          allowedRoutes.namespaces.from = "All";
          tls = {
            mode = "Terminate";
            certificateRefs = [
              {
                name = "cloud-vegapunk-apps-tls";
              }
            ];
          };
        }
      ];
    };
  };
}
