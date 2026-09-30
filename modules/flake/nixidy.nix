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
        seraphim.modules = [
          ../../clusters/seraphim.nix
          config.flake.modules.nixidy.argocd
          config.flake.modules.nixidy.cilium
          config.flake.modules.nixidy.cnpg
          config.flake.modules.nixidy.openbao
          config.flake.modules.nixidy.openebs
          config.flake.modules.nixidy.rook
        ];
      };
    };
  };
}
