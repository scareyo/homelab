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

      helm.releases.external-dns = {
        chart = charts.external-dns;
        values = import ./values.nix;
      };

      templates.externalSecret.unifi = {
        keys = [
          { source = "/unifi/API_KEY"; dest = "api-key"; }
        ];
      };
    };
  };
}
