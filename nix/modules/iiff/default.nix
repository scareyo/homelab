{ config, lib, ... }:

let
  cfg = config.vegapunk.iiff;
  namespace = "iiff";
in
{
  options = {
    vegapunk.iiff.enable = lib.mkEnableOption "Enable IIFF";
  };

  config = lib.mkIf cfg.enable {
    applications.iiff = {
      namespace = namespace;
      createNamespace = true;

      templates.app.iiff = {
        inherit namespace;

        workload = {
          image = "dev.vegapunk.cloud/scarey/is-it-frieren-friday";
          version = "dev";
          port = 8080;
          env = {
            IIFF_TMDB_API_KEY = {
              secretKeyRef = {
                key = "api-key";
                name = "iiff";
              };
            };
          };
        };

        route = {};
      };

      templates.externalSecret.iiff = {
        keys = [
          { source = "/iiff/TMDB_API_KEY"; dest = "api-key"; }
        ];
      };
    };
  };
}
