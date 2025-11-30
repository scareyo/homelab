{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.external-dns;
in
{
  options = {
    vegapunk.external-dns.enable = lib.mkEnableOption "Enable ExternalDNS";
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-dns = {
      namespace = "external-dns";
      createNamespace = true;

      helm.releases.external-dns-cloudflare = {
        chart = charts.external-dns;
        values = (import ./values.nix).cloudflare;
      };

      helm.releases.external-dns-unifi = {
        chart = charts.external-dns;
        values = (import ./values.nix).unifi;
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
