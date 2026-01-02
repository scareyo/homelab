{ config, lib, ... }:

let
  cfg = config.vegapunk.calibre;
  namespace = "calibre";
in
{
  options = {
    vegapunk.calibre.enable = lib.mkEnableOption "Enable Calibre-Web";
  };

  config = lib.mkIf cfg.enable {
    applications.calibre = {
      namespace = namespace;
      createNamespace = true;

      templates.app.calibre = {
        inherit namespace;

        workload = {
          image = "ghcr.io/linuxserver/calibre-web";
          version = "0.6.25";
          port = 8083;
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/config";
            config = {
              size = "4Gi";
            };
          };
          media = {
            type = "nfs";
            path = "/mnt/books";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/books";
              readOnly = true;
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
          image = "ghcr.io/linuxserver/calibre";
          version = "8.16.2";
          command = ["/bin/bash"];
          args = [
            "-c"
            ''
              find /mnt/media/downloads -name '*.epub' -exec calibredb add --with-library /mnt/media/books/metadata.db {} \;
            ''
          ];
        };

        persistence = {
          media = {
            type = "nfs";
            path = "/mnt/media";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media";
              readOnly = false;
            };
          };
        };
      };

      resources.deployments.calibre.spec.template.spec.containers.calibre.securityContext = lib.mkForce {};
      resources.deployments.calibre.spec.template.spec.securityContext = lib.mkForce {};
      resources.cronJobs.calibre-import.spec.jobTemplate.spec.template.spec.containers.calibre-import.securityContext = lib.mkForce {};
      resources.cronJobs.calibre-import.spec.jobTemplate.spec.template.spec.securityContext = lib.mkForce {};

      #templates.externalSecret.oidc = {
      #  keys = [
      #    { source = "/calibre/OIDC_CLIENT_ID"; dest = "client-id"; }
      #    { source = "/calibre/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
      #  ];
      #};
    };
  };
}
