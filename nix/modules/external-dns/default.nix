{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.external-dns;
in
{
  options = with lib; {
    scarey.k8s.external-dns.enable = mkEnableOption "Enable ExternalDNS";
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-dns = {
      namespace = "external-dns";
      createNamespace = true;

      helm.releases.external-dns = {
        chart = charts.external-dns.external-dns;
        values = {
          gatewayNamespace = "gateway";
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
        };
      };

      templates.externalSecret.cloudflare = {
        keys = [
          { source = "/cloudflare/API_TOKEN"; dest = "token"; }
        ];
      };
    };
  };
}
