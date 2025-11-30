{ lib, ... }:

{
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
        example = "12h30m45s";
      };

      ttl = lib.mkOption {
        type = lib.types.str;
        description = "Duration to keep backups";
        example = "12h30m45s";
      };

      includedNamespaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Namespace to backup";
      };
    };

    output = { name, config, ...  }: let
      cfg = config;
    in {
      "velero.io".v1.Schedule.${name} = {
        metadata = {
          name = "${name}";
          namespace = "${cfg.namespace}";
        };
        spec = {
          schedule = cfg.schedule;
          template = {
            ttl = cfg.ttl;
            includedNamespaces = cfg.includedNamespaces;
            includedResources = [
              "pv"
              "pvc"
            ];
            snapshotVolumes = true;
            snapshotMoveData = true;
          };
        };
      };

      "velero.io".v1.Restore.${name} = lib.mkIf cfg.restore {
        metadata = {
          name = "${name}";
          namespace = "${cfg.namespace}";
          annotations = {
            "argocd.argoproj.io/sync-wave" = "-10";
          };
        };
        spec = {
          scheduleName = "${name}";
          restorePVs = true;
          includedResources = [
            "pvc"
          ];
        };
      };
    };
  };
}
