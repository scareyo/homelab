{ flake-parts-lib, lib, config, inputs, ... }:

{
  imports = [(flake-parts-lib.mkTransposedPerSystemModule {
    name = "nixidyEnvs";
    file = ./nixidy.nix;
    option = lib.mkOption { type = lib.types.raw; default = { }; };
  })];

  perSystem = { pkgs, ... }: {
    nixidyEnvs = inputs.nixidy.lib.mkEnvs {
      inherit pkgs;

      envs = {
        seraphim.modules = [ ../../clusters/seraphim.nix ]
          ++ builtins.attrValues config.flake.modules.apps
          ++ builtins.attrValues config.flake.modules.templates;
      };
    };
  };
}
