{
  flake.modules.apps.gateway = { generators, lib, pkgs, ... }: let
    namespace = "gateway";
    project = "system";
  in {
    nixidy.applicationImports = [
      (generators.fromCRDModule {
        name = "gateway-api";
        src = pkgs.fetchFromGitHub {
          owner = "kubernetes-sigs";
          repo = "gateway-api";
          rev = "v1.6.0";
          hash = "sha256-Cu6yYwLaY24fmiMfHZ0AsGfAH8MnnIzHvzvne4V5/k4=";
        };
        crdFiles = [
          "config/crd/standard/gateway.networking.k8s.io_gateways.yaml"
          "config/crd/standard/gateway.networking.k8s.io_httproutes.yaml"
        ];
      })
    ];

    applications.gateway = {
      inherit namespace project;

      createNamespace = true;

      resources.gateways.internal = {
        metadata = {
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-staging";
          };
        };
        spec = {
          gatewayClassName = "agentgateway";
          infrastructure.annotations."lbipam.cilium.io/ips" = "10.10.21.11";
          listeners = [
            {
              protocol = "HTTPS";
              port = 443;
              name = "cloud-vegapunk-apps-https";
              hostname = "*.vegapunk.cloud";
              allowedRoutes = {
                namespaces.from = "All";
                kinds = [
                  { kind = "HTTPRoute"; }
                ];
              };
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
    };
  };
}
