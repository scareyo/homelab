{
  flake.modules.templates.backup = { lib, ... }: {
    templates.backup = {
      options = {
        namespace = lib.mkOption {
          type = lib.types.str;
          default = "velero";
          description = "Namespace of the Velero resources";
        };

        restore = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable automatic volume restoration";
        };

        schedule = lib.mkOption {
          type = lib.types.str;
          description = "Backup schedule";
          example = "0 7 * * *";
        };

        ttl = lib.mkOption {
          type = lib.types.str;
          description = "Duration to keep backups";
          example = "12h30m45s";
        };

        location = lib.mkOption {
          type = lib.types.str;
          default = "default";
          description = "Location to store backups";
        };

        resourcePolicy = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Name of the resource policy ConfigMap in the Velero namespace";
          example = "ignore-openebs-zfs-dataset";
        };

        additionalResources = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Additional resources to backup";
        };

        selector = lib.mkOption {
          type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
          default = null;
          description = "Only backup and restore resources matching these labels";
          example = { "app.kubernetes.io/instance" = "sonarr"; };
        };
      };
      output = { name, config, options, ...  }: {
        schedules.${name} = {
          metadata = {
            name = "${options.namespace.value}-${name}";
            namespace = config.namespace;
          };
          spec = {
            schedule = config.schedule;
            template = {
              ttl = config.ttl;
              includedNamespaces = [
                options.namespace.value
              ];
              includedResources = [
                "pv"
                "pvc"
              ] ++ config.additionalResources;
              snapshotVolumes = true;
              snapshotMoveData = true;

              storageLocation = config.location;
            } // lib.optionalAttrs (config.selector != null) {
              labelSelector.matchLabels = config.selector;
            } // lib.optionalAttrs (config.resourcePolicy != null) {
              resourcePolicy = { kind = "configmap"; name = config.resourcePolicy; };
            };
          };
        };
        restores.${name} = lib.mkIf (config.restore) {
          metadata = {
            name = "${options.namespace.value}-${name}";
            namespace = config.namespace;
            annotations = {
              "argocd.argoproj.io/sync-wave" = "-10";
            };
          };
          spec = {
            scheduleName = "${options.namespace.value}-${name}";
            restorePVs = true;
            includedResources = [
              "pvc"
            ] ++ config.additionalResources;
          } // lib.optionalAttrs (config.selector != null) {
            labelSelector.matchLabels = config.selector;
          };
        };
      };
    };
  };
}
