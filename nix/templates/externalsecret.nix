{ lib, ... }:

{
  templates.externalSecret = {
    options = {
      keys = lib.mkOption {
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

      providerKeys = builtins.filter(x: x.type == "provider") cfg.keys;
      passwordKeys = builtins.filter(x: x.type == "password") cfg.keys;
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
          data =
            if builtins.length providerKeys == 0 then 
              null 
            else map (x: {
              secretKey = "${x.dest}";
              remoteRef = {
                conversionStrategy = "Default";
                decodingStrategy = "None";
                key = "${x.source}";
                metadataPolicy = "None";
              };
            }) providerKeys;
          dataFrom = 
            if builtins.length passwordKeys == 0 then 
              null 
            else map (x: {
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
            }) passwordKeys;
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
