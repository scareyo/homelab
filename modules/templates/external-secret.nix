{
  flake.modules.templates.externalSecret = { lib, ... }: {
    templates.externalSecret = {
      options = {
        secrets = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
            options = {
              provider = lib.mkOption {
                type = lib.types.enum [ "infisical" "kubernetes" ];
                default = "infisical";
                description = "Secret provider to use. kubernetes reads existing Secrets in the same namespace (key = Secret name, property = Secret key)";
              };

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

              encoding = lib.mkOption {
                type = lib.types.enum [ "raw" "base64" "base64url" "base32" "hex" ];
                default = "raw";
                description = "Password encoding";
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

      output = { name, config, options, ... }: let
        cfg = config;
        namespace = options.namespace.value;
        kubernetes = lib.any (x: x.provider == "kubernetes") (lib.attrValues cfg.secrets);
        kubernetesName = "external-secrets-kubernetes";

        generatorName = dest: lib.toLower (builtins.replaceStrings [ "_" ] [ "-" ] "${name}-${dest}");
      in {
        externalSecrets.${name} = {
          spec = {
            refreshPolicy = lib.mkIf (cfg.passwords != {}) "CreatedOnce";
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
              sourceRef.storeRef = if x.provider == "kubernetes" then {
                kind = "SecretStore";
                name = kubernetesName;
              } else {
                kind = "ClusterSecretStore";
                name = x.provider;
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

        secretStores.${kubernetesName} = lib.mkIf kubernetes {
          spec.provider.kubernetes = {
            remoteNamespace = namespace;
            server.caProvider = {
              type = "ConfigMap";
              name = "kube-root-ca.crt";
              key = "ca.crt";
            };
            auth.serviceAccount.name = kubernetesName;
          };
        };

        serviceAccounts.${kubernetesName} = lib.mkIf kubernetes {};

        roleBindings.${kubernetesName} = lib.mkIf kubernetes {
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            name = kubernetesName;
          };
          subjects = [
            {
              kind = "ServiceAccount";
              name = kubernetesName;
              inherit namespace;
            }
          ];
        };

        passwords = lib.mapAttrs' (dest: x: lib.nameValuePair (generatorName dest) {
          spec = {
            inherit (x) length encoding;
            allowRepeat = true;
            noUpper = false;
          };
        }) cfg.passwords;
      };
    };
  };
}
