{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.forgejo;
  namespace = "forgejo";
in
{
  options = {
    vegapunk.forgejo.enable = lib.mkEnableOption "Enable Forgejo";
  };

  config = lib.mkIf cfg.enable {
    applications.forgejo = {
      namespace = namespace;
      createNamespace = true;

      helm.releases.forgejo = {
        chart = charts.forgejo;
        values = import ./values.nix;
      };

      templates.app.forgejo = {
        inherit namespace;

        route = {
          hostname = "dev.vegapunk.cloud";
          serviceName = "forgejo-http";
          servicePort = 3000;
        };

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
          quarterly = {
            schedule = "0 0 1 1,4,7,10 *";
            ttl = "8760h0m0s"; # 1 year
          };
        };
      };

      templates.postgres.forgejo = {
        instances = 3;
        size = "256Gi";
      };

      templates.externalSecret.admin = {
        keys = [
          { source = "/forgejo/ADMIN_USERNAME"; dest = "username"; }
          { source = "/forgejo/ADMIN_PASSWORD"; dest = "password"; }
        ];
      };

      templates.externalSecret.oidc = {
        keys = [
          { source = "/forgejo/OIDC_CLIENT_ID"; dest = "key"; }
          { source = "/forgejo/OIDC_CLIENT_SECRET"; dest = "secret"; }
        ];
      };
    };
  };
}
