{ lib }:

lib.types.submodule {
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
  };
}
