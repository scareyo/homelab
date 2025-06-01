{ lib }:

let
  vm = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Virtual machine name";
      };
      uuid = lib.mkOption {
        type = lib.types.str;
        description = "Virtual machine UUID";
      };
      vcpus = lib.mkOption {
        type = lib.types.number;
        description = "Virtual machine vCPUs";
      };
      memory = lib.mkOption {
        type = lib.types.number;
        description = "Virtual machine memory";
      };
      mac = lib.mkOption {
        type = lib.types.str;
        description = "Virtual machine MAC address";
      };
      diskSize = lib.mkOption {
        type = lib.types.number;
        description = "Virtual machine disk size";
      };
      config = lib.mkOption {
        type = lib.types.path;
        description = "Virtual machine system configuration path";
      };
    };
  };
in
{
  inherit vm;
}
