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

        additionalResources = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Additional resources to backup";
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
          };
        };
      };
    };
  };
}
