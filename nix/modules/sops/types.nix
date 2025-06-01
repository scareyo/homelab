{ lib }:

let
  secret = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Secret name";
      };
      file = lib.mkOption {
        type = lib.types.path;
        description = "Secret filepath";
      };
      format = lib.mkOption {
        type = lib.types.str;
        description = "Secret file format";
      };
      owner = lib.mkOption {
        type = lib.types.str;
        description = "Secret permissions owner";
      };
      group = lib.mkOption {
        type = lib.types.str;
        description = "Secret permissions group";
      };
    };
  };
in
{
  inherit secret;
}
