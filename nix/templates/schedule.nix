{ lib, ... }:

{
  templates.schedule = {
    options = with lib; {
      namespace = mkOption {
        type = lib.types.str;
        default = "velero";
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
        type = lib.listOf lib.types.str;
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
          schedule = cfg.ttl;
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
    };
  };
}
