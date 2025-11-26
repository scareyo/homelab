{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.external-dns;
in
{
  options = with lib; {
    scarey.k8s.external-dns.enable = mkEnableOption "Enable ExternalDNS";

    scarey.k8s.external-dns.syncWave = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Argo CD application sync wave";
    };
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-dns = {
      namespace = "external-dns";
      createNamespace = true;

      annotations = lib.mkIf (cfg.syncWave != null) {
        "argocd.argoproj.io/sync-wave" = "${cfg.syncWave}";
      };

      helm.releases.external-dns-cloudflare = {
        chart = charts.external-dns.external-dns;
        values = {
          gatewayNamespace = "gateway";
          extraArgs = [
            "--gateway-name=external"
          ];
          sources = [
            "gateway-httproute"
          ];
          provider.name = "cloudflare";
          env = [
            {
              name = "CF_API_TOKEN";
              valueFrom.secretKeyRef = {
                name = "cloudflare";
                key = "token";
              };
            }
          ];
          policy = "sync";
        };
      };

      helm.releases.external-dns-unifi = {
        chart = charts.external-dns.external-dns;
        values = {
          provider = {
            name = "webhook";
            webhook = {
              image = {
                repository = "ghcr.io/kashalls/external-dns-unifi-webhook";
                tag = "v0.7.0";
              };
              env = [
                {
                  name = "UNIFI_HOST";
                  value = "https://10.10.20.1";
                }
                {
                  name = "UNIFI_EXTERNAL_CONTROLLER";
                  value = "false";
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

      templates.externalSecret.cloudflare = {
        keys = [
          { source = "/cloudflare/API_TOKEN"; dest = "token"; }
        ];
      };

      templates.externalSecret.unifi = {
        keys = [
          { source = "/unifi/API_KEY"; dest = "api-key"; }
        ];
      };
    };
  };
}
