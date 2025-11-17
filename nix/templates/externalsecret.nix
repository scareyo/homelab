{ lib, ... }:

{
  templates.externalSecret = {
    options = with lib; {
      keys = mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              description = "";
            };
            dest = lib.mkOption {
              type = lib.types.str;
              description = "";
            };
          };
        });
        description = "";
      };
    };
    output = { name, config, ...  }: let
      cfg = config;
    in {
      "external-secrets.io".v1.ExternalSecret.${name} = {
        metadata = {
          name = "${name}";
        };
        spec = {
          secretStoreRef = {
            kind = "ClusterSecretStore";
            name = "infisical";
          };
          data = map (x: {
            secretKey = "${x.dest}";
            remoteRef = {
              conversionStrategy = "Default";
              decodingStrategy = "None";
              key = "${x.source}";
              metadataPolicy = "None";
            };
          }) cfg.keys;
        };
      };
    };
  };
}
