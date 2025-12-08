{
  cloudflare = {
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

  unifi = {
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
}
