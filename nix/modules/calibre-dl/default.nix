{ config, lib, ... }:

let
  cfg = config.vegapunk.calibre-dl;
  namespace = "calibre-dl";
in
{
  options = {
    vegapunk.calibre-dl.enable = lib.mkEnableOption "Enable Calibre-Web-Automated Downloader";
  };

  config = lib.mkIf cfg.enable {
    applications.calibre-dl = {
      namespace = namespace;
      createNamespace = true;

      templates.app.calibre-dl = {
        inherit namespace;

        workload = {
          image = "ghcr.io/calibrain/calibre-web-automated-book-downloader";
          version = "dev";
          port = 8084;
          env = {
            TZ = "America/New_York";
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

      resources.deployments.calibre-dl.spec.template.spec.containers.calibre-dl.securityContext = lib.mkForce {};
      resources.deployments.calibre-dl.spec.template.spec.securityContext = lib.mkForce {};

      #templates.externalSecret.calibre = {
      #  keys = [
      #    #{ source = "/calibre/OIDC_CLIENT_ID"; dest = "client-id"; }
      #    #{ source = "/calibre/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
      #  ];
      #};
    };
  };
}
