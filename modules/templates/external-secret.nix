{
  flake.modules.templates.externalSecret = { lib, ... }: {
    templates.externalSecret = {
      options = {
        data = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
            options = {
              sourceKey = lib.mkOption {
                type = lib.types.str;
                description = "Source key on the secret provider";
              };

              sourceProperty = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Source property on the secret provider";
              };
            };
          }));
          default = {};
          description = "Secrets fetched from the secret provider, keyed by destination key on the generated Secret";
        };

        passwords = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              length = lib.mkOption {
                type = lib.types.int;
                default = 32;
                description = "Password length";
              };
            };
          });
          default = {};
          description = "Generated passwords, keyed by destination key on the generated Secret";
        };

        merge = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Merge with existing secret";
        };

        templates = lib.mkOption {
          type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
          default = null;
          description = "Templated secrets";
        };
      };

      output = { name, config, ... }: let
        cfg = config;

        generatorName = dest: "${name}-${dest}";
      in {
        externalSecrets.${name} = {
          spec = {
            secretStoreRef = {
              kind = "ClusterSecretStore";
              name = "openbao";
            };
            target.creationPolicy = lib.mkIf cfg.merge "Merge";
            target.template = lib.mkIf (cfg.templates != null) {
              engineVersion = "v2";
              data = cfg.templates;
            };
            data = lib.mkIf (cfg.data != {}) (lib.mapAttrsToList (dest: x: {
              secretKey = dest;
              remoteRef = {
                key = x.sourceKey;
                property = x.sourceProperty;
              };
            }) cfg.data);
            dataFrom = lib.mkIf (cfg.passwords != {}) (lib.mapAttrsToList (dest: _: {
              sourceRef.generatorRef = {
                apiVersion = "generators.external-secrets.io/v1alpha1";
                kind = "Password";
                name = generatorName dest;
              };
              rewrite = [
                {
                  regexp = {
                    source = "password";
                    target = dest;
                  };
                }
              ];
            }) cfg.passwords);
          };
        };

        passwords = lib.mapAttrs' (dest: x: lib.nameValuePair (generatorName dest) {
          spec = {
            inherit (x) length;
            allowRepeat = true;
            noUpper = false;
          };
        }) cfg.passwords;
      };
    };
  };
}
