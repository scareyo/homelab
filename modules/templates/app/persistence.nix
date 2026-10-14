{
  flake.modules.templates.app = { lib, ... }: {
    templates.app = let
      cm = {
        options = {
          data = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            description = "ConfigMap data";
          };
        };
      };

      pvc = {
        options = {
          accessModes = lib.mkOption {
            type = lib.types.listOf (lib.types.enum [
              "ReadWriteOnce"
              "ReadOnlyMany"
              "ReadWriteMany"
              "ReadWriteOncePod"
            ]);
            default = [ "ReadWriteOnce" ];
            description = "Persistence access modes";
          };

          size = lib.mkOption {
            type = lib.types.str;
            description = "Persistence PVC storage size";
          };

          storageClass = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Persistence PVC storage class";
          };
        };
      };
    in {
      options.persistence = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [
                "cm"
                "emptyDir"
                "pvc"
              ];
              default = "emptyDir";
              description = "Persistence type";
            };

            path = lib.mkOption {
              type = lib.types.str;
              description = "Persistence mount path";
            };

            config = lib.mkOption {
              type = lib.types.submoduleWith {
                modules =
                  lib.optionals (config.type == "cm") [ cm ] ++
                  lib.optionals (config.type == "pvc") [ pvc ];
              };
              default = {};
              description = "Persistence type specific options";
            };

            volume = lib.mkOption {
              type = lib.types.attrs;
              internal = true;
              readOnly = true;
              description = "Pod volume source";
            };
          };

          config.volume = {
            cm.configMap.name = name;
            emptyDir.emptyDir = {};
            pvc.persistentVolumeClaim.claimName = name;
          }.${config.type};
        }));
        default = {};
      };
      output = { name, config, options, ...  }: let
        labels = import ./_labels.nix { inherit lib name config options; };
      in {
        configMaps = lib.mapAttrs (vol: p: lib.mkIf (p.type == "cm") {
          metadata = { inherit labels; };
          data = p.config.data;
        }) config.persistence;

        persistentVolumeClaims = lib.mapAttrs (vol: p: lib.mkIf (p.type == "pvc") {
          metadata = { inherit labels; };
          spec = {
            accessModes = p.config.accessModes;
            resources.requests.storage = p.config.size;
          }
          // lib.optionalAttrs (p.config.storageClass != null) {
            storageClassName = p.config.storageClass;
          };
        }) config.persistence;
      };
    };
  };
}
