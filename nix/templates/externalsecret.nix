{ lib, ... }:

{
  templates.externalSecret = {
    options = with lib; {
      keys = mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.str;
              default = "provider";
              description = "Secret type";
            };
            source = lib.mkOption {
              type = lib.types.str;
              description = "Source key on the secret provider";
            };
            length = lib.mkOption {
              type = lib.types.int;
              description = "Password length";
            };
            dest = lib.mkOption {
              type = lib.types.str;
              description = "Destination key on the generated Secret";
            };
          };
        });
        description = "A list of secrets to include in the generated Secret";
      };
      merge = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Merge with existing secret";
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
          target.creationPolicy = lib.mkIf cfg.merge "Merge";
          data = map (x: {
            secretKey = "${x.dest}";
            remoteRef = {
              conversionStrategy = "Default";
              decodingStrategy = "None";
              key = "${x.source}";
              metadataPolicy = "None";
            };
          }) (builtins.filter (x: x.type == "provider") cfg.keys);
          dataFrom = map (x: {
            sourceRef.generatorRef = {
              apiVersion = "generators.external-secrets.io/v1alpha1";
              kind = "Password";
              name = "${x.dest}";
            };
            rewrite = [
              {
                regexp = {
                  source = "password";
                  target = "${x.dest}";
                };
              }
            ];
          }) (builtins.filter (x: x.type == "password") cfg.keys);
        };
      };
      "generators.external-secrets.io".v1alpha1.Password = builtins.listToAttrs (map (x: {
        name = x.dest;
        value = {
          metadata.name = x.dest;
          spec = {
            length = x.length;
            allowRepeat = true;
            noUpper = false;
          };
        };
      }) (builtins.filter (x: x.type == "password") cfg.keys));
    };
  };
}
