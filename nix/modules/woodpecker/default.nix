{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.woodpecker;
  namespace = "woodpecker";
in
{
  options = {
    vegapunk.woodpecker.enable = lib.mkEnableOption "Enable Woodpecker CI";
  };

  config = lib.mkIf cfg.enable {
    applications.woodpecker = {
      namespace = namespace;
      createNamespace = true;

      helm.releases.woodpecker = {
        chart = charts.woodpecker;
        values = import ./values.nix;
      };

      templates.app.woodpecker = {
        inherit namespace;

        route = {
          hostname = "ci.vegapunk.cloud";
          serviceName = "woodpecker-server";
        };
      };

      templates.externalSecret.woodpecker = {
        keys = [
          { type = "password"; length = 64; dest = "agent-secret"; }
        ];
      };

      templates.postgres.woodpecker = {
        instances = 3;
        size = "32Gi";
      };

      #templates.externalSecret.admin = {
      #  keys = [
      #    { source = "/woodpecker/ADMIN_USERNAME"; dest = "username"; }
      #    { source = "/woodpecker/ADMIN_PASSWORD"; dest = "password"; }
      #  ];
      #};

      templates.externalSecret.oidc = {
        keys = [
          { source = "/woodpecker/FORGEJO_CLIENT"; dest = "client"; }
          { source = "/woodpecker/FORGEJO_SECRET"; dest = "secret"; }
        ];
      };
    };
  };
}
