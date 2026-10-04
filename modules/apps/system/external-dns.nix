{
  flake.modules.apps.external-dns = { generators, lib, ... }: let
    namespace = "external-dns";
    project = "system";
    chart = lib.helm.downloadHelmChart {
      repo = "https://kubernetes-sigs.github.io/external-dns";
      chart = "external-dns";
      version = "1.23.0";
      chartHash = "sha256-y7TE41d3QkpRYrRBWXyfr3oP4JfSAxB5rMoAwuu6Z2k=";
    };
  in {
    applications.external-dns = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.external-dns = {
        inherit chart;
        values = {
          provider = {
            name = "webhook";
            webhook = {
              image = {
                repository = "ghcr.io/home-operations/external-dns-unifi-webhook";
                tag = "0.10.12";
              };
              env = [
                {
                  name = "UNIFI_HOST";
                  value = "https://10.10.20.1";
                }
                {
                  name = "UNIFI_API_KEY";
                  valueFrom.secretKeyRef = {
                    name = "unifi";
                    key = "api-key";
                  };
                }
              ];
              livenessProbe = {
                httpGet = {
                  path = "/healthz";
                  port = "http-webhook";
                };
                initialDelaySeconds = 10;
                timeoutSeconds = 5;
              };
              readinessProbe = {
                httpGet = {
                  path = "/readyz";
                  port = "http-webhook";
                };
                initialDelaySeconds = 10;
                timeoutSeconds = 5;
              };
            };
          };
          extraArgs = [
            "--gateway-name=internal"
            "--ignore-ingress-tls-spec"
          ];
          policy = "sync";
          sources = ["gateway-httproute"];
          domainFilters = ["vegapunk.cloud"];
        };
      };

      templates.externalSecret.unifi = {
        keys = [
          { source-key = "external-dns"; source-property = "unifi-api-key"; dest = "api-key"; }
        ];
      };
    };
  };
}
