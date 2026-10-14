{
  flake.modules.templates.externalSecret = { lib, ... }: {
    templates.externalSecret = {
      options = {
        provider = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "infisical" ]);
          default = "infisical";
          description = "External Secrets ClusterSecretStore to use";
        };

        secrets = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
            options = {
              key = lib.mkOption {
                type = lib.types.str;
                description = "Remote key on the secret provider";
              };

              property = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Remote property on the secret provider";
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

        generatorName = dest: lib.toLower (builtins.replaceStrings [ "_" ] [ "-" ] "${name}-${dest}");
      in {
        externalSecrets.${name} = {
          spec = {
            secretStoreRef = {
              kind = "ClusterSecretStore";
              name = cfg.provider;
            };
            target.creationPolicy = lib.mkIf cfg.merge "Merge";
            target.template = lib.mkIf (cfg.templates != null) {
              engineVersion = "v2";
              data = cfg.templates;
            };
            data = lib.mkIf (cfg.secrets != {}) (lib.mapAttrsToList (dest: x: {
              secretKey = dest;
              remoteRef = {
                key = x.key;
                property = x.property;
              };
            }) cfg.secrets);
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
