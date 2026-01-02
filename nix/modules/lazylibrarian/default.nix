{ config, lib, ... }:

let
  cfg = config.vegapunk.lazylibrarian;
  namespace = "lazylibrarian";
in
{
  options = {
    vegapunk.lazylibrarian.enable = lib.mkEnableOption "Enable LazyLibrarian";
  };

  config = lib.mkIf cfg.enable {
    applications.lazylibrarian = {
      namespace = namespace;
      createNamespace = true;

      templates.app.lazylibrarian = {
        inherit namespace;

        workload = {
          image = "ghcr.io/linuxserver/lazylibrarian";
          version = "f42cfc3f-ls233";
          port = 5299;
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
            path = "/mnt/media";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media";
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

      resources.deployments.lazylibrarian.spec.template.spec.containers.lazylibrarian.securityContext = lib.mkForce {};
      resources.deployments.lazylibrarian.spec.template.spec.securityContext = lib.mkForce {};

      #templates.externalSecret.oidc = {
      #  keys = [
      #    { source = "/lazylibrarian/OIDC_CLIENT_ID"; dest = "client-id"; }
      #    { source = "/lazylibrarian/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
      #  ];
      #};
    };
  };
}
