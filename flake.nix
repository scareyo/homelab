{
  description = "A scarey homelab";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  inputs.amtcli.url = "github:scareyo/amtcli";

  inputs.nixhelm = {
    url = "github:farcaller/nixhelm";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.nixidy = {
    url = "github:arnarg/nixidy";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, amtcli, flake-parts, nixhelm, nixidy, nixpkgs }:
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
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            dnsmasq
            git-crypt
            omnictl
            packer
            pre-commit
            yq-go

            # Ansible
            ansible
            ansible-lint
            python3Packages.kubernetes

            infisicalsdk

            # Kubernetes
            argocd
            cilium-cli
            k9s
            kubectl
            kubelogin-oidc
            kubernetes-helm
            kubernetes-helmPlugins.helm-diff
            talosctl
            velero

            nixidy.packages.${system}.default
            amtcli.packages.${system}.default
          ];
        };

        packages.nixidy = nixidy.packages.${system}.default;

        packages.crds = pkgs.callPackage ./nix/crds {
          generators = nixidy.packages.${system}.generators;
        };

        legacyPackages = {
          nixidyEnvs.${system}.seraphim = nixidy.lib.mkEnv {
            inherit pkgs;

            charts = nixhelm.chartsDerivations.${system};
            modules = [
              ./nix/clusters/seraphim/prod.nix
            ];
          };
        };
      };
    };
}
