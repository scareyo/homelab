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
          env = {
            #S6_YES_I_WANT_A_WORLD_WRITABLE_RUN_BECAUSE_KUBERNETES = "1";
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
          media = {
            type = "nfs";
            path = "/mnt/books";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/books";
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

      resources.deployments.calibre.spec.template.spec.containers.calibre.securityContext = lib.mkForce {};
      resources.deployments.calibre.spec.template.spec.securityContext = lib.mkForce {};

      #templates.externalSecret.oidc = {
      #  keys = [
      #    { source = "/calibre/OIDC_CLIENT_ID"; dest = "client-id"; }
      #    { source = "/calibre/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
      #  ];
      #};
    };
  };
}
