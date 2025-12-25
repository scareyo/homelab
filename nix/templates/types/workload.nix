{ lib }:

lib.types.submodule {
  options = {
    image = lib.mkOption {
      type = lib.types.str;
      description = "Workload container image";
    };

    version = lib.mkOption {
      type = lib.types.str;
      description = "Workload container image version";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "Workload container port";
    };

    args = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "Workload container args";
    };

    env = lib.mkOption {
      type = lib.types.attrsOf (lib.types.oneOf [lib.types.str lib.types.attrs]);
      description = "Workload container env";
    };

    dnsPolicy = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [
        "ClusterFirst"
        "Default"
      ]);
      default = null;
      description = "Workload DNS policy";
    };
  };
}
