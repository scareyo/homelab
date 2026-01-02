{ config, lib, ... }:

let
  cfg = config.vegapunk.calibre;
  namespace = "calibre";
in
{
  options = {
    vegapunk.calibre.enable = lib.mkEnableOption "Enable Calibre-Web-Automated";
  };

  config = lib.mkIf cfg.enable {
    applications.calibre = {
      namespace = namespace;
      createNamespace = true;

      templates.app.calibre = {
        inherit namespace;

        workload = {
          image = "ghcr.io/crocodilestick/calibre-web-automated";
          version = "dev";
          port = 8083;
          env = {
            TZ = "America/New_York";
            NETWORK_SHARE_MODE = "true";
            HARDCOVER_TOKEN = {
              secretKeyRef = {
                key = "hardcover-api-key";
                name = "calibre";
              };
            };
          };
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/config";
            config = {
              size = "4Gi";
            };
          };
          library = {
            type = "nfs";
            path = "/calibre-library";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/books/calibre";
              readOnly = false;
            };
          };
          ingest = {
            type = "nfs";
            path = "/cwa-book-ingest";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/books/incoming";
              readOnly = false;
            };
          };
        };

        route = {};

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
        };
      };

      templates.app.calibre-import = {
        inherit namespace;

        workload = {
          type = "cronjob";
          image = "debian";
          version = "12";
          command = ["find"];
          args = [
            "/mnt/downloads"
            "-name"
            "*.epub"
            "-exec"
            "mv" "{}" "/mnt/incoming" "\;"
          ];
        };

        persistence = {
          downloads = {
            type = "nfs";
            path = "/mnt/downloads";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/downloads";
              readOnly = false;
            };
          };
          incoming = {
            type = "nfs";
            path = "/mnt/incoming";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/books/incoming";
              readOnly = false;
            };
          };
        };
      };

      resources.deployments.calibre.spec.template.spec.containers.calibre.securityContext = lib.mkForce {};
      resources.deployments.calibre.spec.template.spec.securityContext = lib.mkForce {};

      templates.externalSecret.calibre = {
        keys = [
          { source = "/calibre/HARDCOVER_API_KEY"; dest = "hardcover-api-key"; }
          #{ source = "/calibre/OIDC_CLIENT_ID"; dest = "client-id"; }
          #{ source = "/calibre/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
        ];
      };
    };
  };
}
