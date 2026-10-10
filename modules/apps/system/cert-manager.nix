{
  flake.modules.apps.cert-manager = { generators, lib, ... }: let
    namespace = "cert-manager";
    project = "system";
    charts.cert-manager = {
      repo = "oci://quay.io/jetstack/charts";
      chart = "cert-manager";
      version = "1.21.2";
      chartHash = "sha256-AsbUc4Q9aVfTmENGPPmjOwC6V6v3MpTN1cKIl8csi10=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.cert-manager;
        name = "cert-manager";
        kindFilter = [ "ClusterIssuer" "Issuer" ];
        extraOpts = [ "--set" "crds.enabled=true"];
      })
    ];

    applications.cert-manager = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.cert-manager = {
        chart = chart.cert-manager;
        values = {
          crds.enabled = true;

          config = {
            apiVersion = "controller.config.cert-manager.io/v1alpha1";
            kind = "ControllerConfiguration";
            enableGatewayAPI = true;
          };

          extraArgs = [
            "--enable-gateway-api"
          ];
        };
      };

      templates.externalSecret.cloudflare.secrets = {
        api-token.key = "/cert-manager/CLOUDFLARE_API_TOKEN";
      };

      resources.clusterIssuers = {
        letsencrypt-staging = {
          metadata = {
            name = "letsencrypt-staging";
            annotations = {
              "argocd.argoproj.io/sync-wave" = "10";
            };
          };
          spec = {
            acme = {
              server = "https://acme-staging-v02.api.letsencrypt.org/directory";
              email = "sam@scarey.me";
              privateKeySecretRef.name = "letsencrypt-staging";
              solvers = [
                {
                  dns01.cloudflare.apiTokenSecretRef = {
                    name = "cloudflare";
                    key = "api-token";
                  };
                }
              ];
            };
          };
        };

        letsencrypt-production = {
          metadata = {
            name = "letsencrypt-production";
            annotations = {
              "argocd.argoproj.io/sync-wave" = "10";
            };
          };
          spec = {
            acme = {
              server = "https://acme-v02.api.letsencrypt.org/directory";
              email = "sam@scarey.me";
              privateKeySecretRef.name = "letsencrypt-production";
              solvers = [
                {
                  dns01.cloudflare.apiTokenSecretRef = {
                    name = "cloudflare";
                    key = "api-token";
                  };
                }
              ];
            };
          };
        };
      };
    };
  };
}
