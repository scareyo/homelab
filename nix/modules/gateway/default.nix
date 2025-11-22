{ config, lib, ... }:

let
  cfg = config.scarey.k8s.gateway;
in
{
  options = with lib; {
    scarey.k8s.gateway.enable = mkEnableOption "Enable Gateway";
  };
  
  config = lib.mkIf cfg.enable {
    applications.gateway = {
      namespace = "gateway";
      createNamespace = true;

      resources = {
        "gateway.networking.k8s.io".v1.Gateway.internal = {
          metadata = {
            name = "internal";
            annotations = {
              "cert-manager.io/cluster-issuer" = "letsencrypt-staging";
            };
          };
          spec = {
            gatewayClassName = "internal";
            infrastructure.annotations."lbipam.cilium.io/ips" = "10.10.21.11";
            listeners = [
              {
                protocol = "HTTPS";
                port = 443;
                name = "apps-vegapunk-cloud-https";
                hostname = "*.vegapunk.cloud";
                allowedRoutes.namespaces.from = "All";
                tls = {
                  mode = "Terminate";
                  certificateRefs = [
                    {
                      name = "apps-vegapunk-cloud-tls";
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
              "cert-manager.io/cluster-issuer" = "letsencrypt-staging";
            };
          };
          spec = {
            gatewayClassName = "cilium";
            infrastructure.annotations."load-balancer.hetzner.cloud/location" = "ash";
            listeners = [
              {
                protocol = "HTTPS";
                port = 443;
                name = "apps-scarey-me-https";
                hostname = "*.scarey.me";
                allowedRoutes.namespaces.from = "All";
                tls = {
                  mode = "Terminate";
                  certificateRefs = [
                    {
                      name = "apps-scarey-me-tls";
                    }
                  ];
                };
              }
              {
                protocol = "HTTPS";
                port = 443;
                name = "scarey-me-https";
                hostname = "scarey.me";
                allowedRoutes.namespaces.from = "All";
                tls = {
                  mode = "Terminate";
                  certificateRefs = [
                    {
                      name = "scarey-me-tls";
                    }
                  ];
                };
              }
            ];
          };
        };
      };
    };
  };
}
