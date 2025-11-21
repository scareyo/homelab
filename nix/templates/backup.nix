{ lib, ... }:

{
  templates.backup = {
    options = with lib; {
      namespace = mkOption {
        type = lib.types.str;
        default = "velero";
        description = "";
      };
      restore = mkOption {
        type = lib.types.bool;
        default = false;
        description = "";
      };
      schedule = mkOption {
        type = lib.types.str;
        description = "";
      };
      ttl = mkOption {
        type = lib.types.str;
        description = "";
      };
      includedNamespaces = mkOption {
        type = lib.types.listOf lib.types.str;
        description = "";
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
