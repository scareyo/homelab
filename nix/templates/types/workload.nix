{ lib }:

lib.types.submodule {
  options = {
    image = lib.mkOption {
      type = lib.types.str;
      description = "Workload container image";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "Workload container port";
    };

    env = lib.mkOption {
      type = lib.types.attrsOf (lib.types.oneOf [lib.types.str lib.types.attrs]);
      description = "Workload container env";
    };
  };
}
