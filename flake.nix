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
        myPkgs = import ./nix/pkgs {
          inherit pkgs;
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            dnsmasq
            git-crypt
            omnictl
            packer
            yq-go

            myPkgs.talm

            # Ansible
            ansible
            ansible-lint
            python3Packages.kubernetes

            infisicalsdk

            # Kubernetes
            argocd
            cilium-cli
            fluxcd
            fluxcd-operator
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

        packages.cert-manager = nixidy.packages.${system}.generators.fromCRD {
          name = "cert-manager";
          src = pkgs.fetchFromGitHub {
            owner = "cert-manager";
            repo = "cert-manager";
            rev = "v1.19.1";
            hash = "sha256-OK6U9QIRYolLBjcNBhzFmZZqfBFoJzY8aUHew2F0MAQ=";
          };
          crds = [
            "deploy/crds/cert-manager.io_clusterissuers.yaml"
          ];
        };

        packages.cilium = nixidy.packages.${system}.generators.fromCRD {
          name = "cilium";
          src = pkgs.fetchFromGitHub {
            owner = "cilium";
            repo = "cilium";
            rev = "v1.18.4";
            hash = "sha256-m7RSxl5gVnPVkw0Ql9YuAl0kCvqnIV5yghFaO+Qje/A=";
          };
          crds = [
            "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpadvertisements.yaml"
            "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpclusterconfigs.yaml"
            "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgppeerconfigs.yaml"
            "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumloadbalancerippools.yaml"
            "pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumgatewayclassconfigs.yaml"
          ];
        };

        packages.external-secrets = nixidy.packages.${system}.generators.fromCRD {
          name = "external-secrets";
          src = pkgs.fetchFromGitHub {
            owner = "external-secrets";
            repo = "external-secrets";
            rev = "v1.0.0";
            hash = "sha256-BRNI2XRbvxn2syN9OaZ3Sgl3oD4g5E+rQR0Npq70IpQ=";
          };
          crds = [
            "deploy/crds/bundle.yaml"
          ];
        };

        packages.gateway-api = nixidy.packages.${system}.generators.fromCRD {
            name = "gateway-api";
            src = pkgs.fetchFromGitHub {
              owner = "kubernetes-sigs";
              repo = "gateway-api";
              rev = "v1.4.0";
              hash = "sha256-osM8BRqFw5he93yTTTQb/q9iVvT6oWkCb731n/C6bq4=";
            };
            crds = [
              "config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml"
              "config/crd/standard/gateway.networking.k8s.io_gateways.yaml"
              "config/crd/standard/gateway.networking.k8s.io_httproutes.yaml"
            ];
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
