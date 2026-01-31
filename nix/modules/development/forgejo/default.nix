{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.forgejo;
  namespace = "forgejo";
  project = "development";
in
{
  options = {
    vegapunk.forgejo.enable = lib.mkEnableOption "Enable Forgejo";
  };

  config = lib.mkIf cfg.enable {
    applications.forgejo = {
      inherit namespace project;

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
          anubis.enable = true;
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

      templates.externalSecret.anubis = {
        keys = [
          { source = "/forgejo/ANUBIS_ED25519_PRIVATE_KEY_HEX"; dest = "key"; }
        ];
      };

      templates.externalSecret.oidc = {
        keys = [
          { source = "/forgejo/OIDC_CLIENT_ID"; dest = "key"; }
          { source = "/forgejo/OIDC_CLIENT_SECRET"; dest = "secret"; }
        ];
      };

      resources."gateway.networking.k8s.io".v1alpha2.TCPRoute.forgejo-ssh = {
        spec = {
          parentRefs = [
            {
              name = "internal";
              namespace = "gateway";
              sectionName = "cloud-vegapunk-dev-ssh";
            }
          ];
          rules = [
            {
              backendRefs = [
                { group = ""; kind = "Service"; name = "forgejo-ssh"; port = 22; }
              ];
            }
          ];
        };
      };
    };
  };
}
