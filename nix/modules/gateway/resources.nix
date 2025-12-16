{
  "gateway.networking.k8s.io".v1.Gateway.internal = {
    metadata = {
      name = "internal";
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-production";
      };
    };
    spec = {
      gatewayClassName = "internal";
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

  "gateway.networking.k8s.io".v1.Gateway.external = {
    metadata = {
      name = "external";
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-production";
      };
    };
    spec = {
      gatewayClassName = "cilium";
      infrastructure.annotations."load-balancer.hetzner.cloud/location" = "ash";
      listeners = [
        {
          protocol = "HTTPS";
          port = 443;
          name = "me-scarey-apps-https";
          hostname = "*.scarey.me";
          allowedRoutes.namespaces.from = "All";
          tls = {
            mode = "Terminate";
            certificateRefs = [
              {
                name = "me-scarey-apps-tls";
              }
            ];
          };
        }
        {
          protocol = "HTTPS";
          port = 443;
          name = "me-scarey-https";
          hostname = "scarey.me";
          allowedRoutes.namespaces.from = "All";
          tls = {
            mode = "Terminate";
            certificateRefs = [
              {
                name = "me-scarey-tls";
              }
            ];
          };
        }
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
        {
          protocol = "HTTPS";
          port = 443;
          name = "cloud-vegapunk-https";
          hostname = "vegapunk.cloud";
          allowedRoutes.namespaces.from = "All";
          tls = {
            mode = "Terminate";
            certificateRefs = [
              {
                name = "cloud-vegapunk-tls";
              }
            ];
          };
        }
      ];
    };
  };
}
