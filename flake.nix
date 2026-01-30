{
  description = "A scarey homelab";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  inputs.amtcli.url = "github:scareyo/amtcli";

  inputs.nixidy = {
    url = "github:arnarg/nixidy";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, amtcli, flake-parts, nixidy, nixpkgs }:
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
            attic-client
            attic-server
            dnsmasq
            gitleaks
            infisicalsdk
            omnictl
            packer
            pre-commit
            trufflehog
            yq-go

            # Ansible
            ansible
            ansible-lint
            python3Packages.kubernetes

            # Kubernetes
            argocd
            cilium-cli
            k9s
            kubectl
            kubectl-rook-ceph
            kubelogin-oidc
            kubernetes-helm
            talosctl
            velero

            nixidy.packages.${system}.default
            amtcli.packages.${system}.default
          ];
        };

        # Renovate
        apps.renovate = {
          type = "app";
          program = "${pkgs.renovate}/bin/renovate";
        };

        apps.generate-manifests = {
          type = "app";
          program = pkgs.writeShellApplication {
            name = "generate-manifests";

            runtimeInputs = [
              pkgs.gitleaks
              pkgs.trufflehog
              nixidy.packages.${system}.default
            ];

            text = builtins.readFile ./scripts/generate-manifests.sh;
          };
        };

        apps.update-hash = {
          type = "app";
          program = pkgs.writeShellApplication {
            name = "update-hash";

            runtimeInputs = [
              pkgs.gnused
              pkgs.kubernetes-helm
            ];

            text = builtins.readFile ./scripts/update-hash.sh;
          };
        };

        packages.crds = pkgs.callPackage ./nix/crds {
          generators = nixidy.packages.${system}.generators;
        };

        legacyPackages = {
          nixidyEnvs.${system}.seraphim = nixidy.lib.mkEnv {
            inherit pkgs;

            modules = [
              ./nix/clusters/seraphim/prod.nix
            ];
          };
        };
      };
    };
}
