{
  description = "A scarey homelab";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.amtcli.url = "github:scareyo/amtcli";

  outputs = inputs@{ self, amtcli, flake-parts, nixpkgs }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem = { lib, pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            dnsmasq
            git-crypt
            
            # Ansible
            ansible
            ansible-lint

            # Podman
            podman
            qemu
            virtiofsd

            # Terraform
            opentofu

            amtcli.packages.${system}.default
          ];
        };
      };
    };
}
