{
  description = "A scarey homelab";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.amtcli.url = "github:scareyo/amtcli";

  outputs = inputs@{ self, amtcli, flake-parts, nixpkgs }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem = { lib, pkgs, system, ... }: let 
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        myPkgs = import ./nix/pkg {
          inherit pkgs;
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bws
            dnsmasq
            omnictl
            packer
            yq-go

            # Ansible
            ansible
            ansible-lint
            python3Packages.kubernetes

            myPkgs.bitwarden-sdk 

            # Kubernetes
            cilium-cli
            fluxcd
            k9s
            kubectl
            kubelogin-oidc
            kubernetes-helm
            talosctl
            velero

            amtcli.packages.${system}.default
          ];
        };
      };
    };
}
