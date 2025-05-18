{
  description = "A scarey homelab";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.amtcli.url = "github:scareyo/amtcli";

  inputs.nixos-generators = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.nixvirt =
  {
    url = "github:AshleyYakeley/NixVirt";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, amtcli, flake-parts, nixpkgs, nixos-generators, nixvirt }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem = { lib, pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            dig
            dnsmasq
            git-crypt
            
            # Ansible
            ansible
            ansible-lint
            python312Packages.kubernetes
            
            (callPackage ./nix/pkg/infisical-python {
              buildPythonPackage = python312Packages.buildPythonPackage;
            })

            # Kubernetes
            argocd
            cilium-cli
            istioctl
            k9s
            kubectl
            kubernetes-helm
            talosctl
            velero

            # Podman
            podman
            qemu
          
            (if (system == "x86_64-linux") then 
              [
                traceroute
                virtiofsd
              ]
            else null)

            amtcli.packages.${system}.default
          ];
        };
      };
        
      flake = {
        nixosConfigurations."nami" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nix/hosts/nami ];
          specialArgs = { inherit inputs nixos-generators; };
        };
        nixosConfigurations."authentik" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nix/hosts/authentik ];
          specialArgs = { inherit self; };
        };
        nixosConfigurations."omni" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nix/hosts/omni ];
          specialArgs = { inherit self; };
        };
      };
    };
}
