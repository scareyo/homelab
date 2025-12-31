{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.homarr;
  namespace = "homarr";
in
{
  options = {
    vegapunk.homarr.enable = lib.mkEnableOption "Enable Homarr";
  };

  config = lib.mkIf cfg.enable {
    applications.homarr = {
      namespace = namespace;
      createNamespace = true;

      helm.releases.homarr = {
        chart = charts.homarr;
        values = import ./values.nix;
      };

      templates.postgres.homarr = {
        instances = 3;
        size = "32Gi";
      };

      templates.app.homarr = {
        inherit namespace;

        route = {
          hostname = "home.vegapunk.cloud";
          serviceName = "homarr";
          servicePort = 7575;
        };

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
        };
      };

      templates.externalSecret.db-encryption = {
        keys = [
          { type = "password"; length = 64; noUpper = true; symbols = 0; dest = "db-encryption-key"; }
        ];
      };
    };
  };
}
