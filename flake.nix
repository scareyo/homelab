{
  description = "A scarey homelab";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.devenv.url = "github:cachix/devenv";

  outputs = inputs@{ self, devenv, flake-parts, nixpkgs }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devenv.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem = { lib, pkgs, ... }: {
        devenv.shells.default = {
          packages = with pkgs; [
            colmena
            git-crypt
            podman
            podman-compose
            qemu
            xz
          ];

          languages = {
            ansible.enable = true;
            opentofu.enable = true;
          };

          starship.enable = true;

          enterShell = lib.mkIf pkgs.stdenv.isDarwin ''
            podman context use podman-machine-default-root
          '';
        };
      };
    };
}
