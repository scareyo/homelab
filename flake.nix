{
  description = "A scarey homelab";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.amtcli.url = "github:scareyo/amtcli";

  inputs.authentik = {
    url = "github:nix-community/authentik-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.nixos-generators = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.nixvirt =
  {
    url = "github:AshleyYakeley/NixVirt";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, amtcli, authentik, flake-parts, nixos-generators, nixpkgs, nixvirt, sops-nix }:
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
            sops
            
            # Ansible
            ansible
            ansible-lint
            python312Packages.kubernetes
            
            (callPackage ./nix/pkg/infisical-python {
              inherit buildPythonPackage;
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
        
      flake = let
        mkGuestSystem = name: nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nix/hosts/${name} ];
        };
        mkGuestImage = name: nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "qcow-efi";
          modules = [ ./nix/hosts/${name} ];
          specialArgs = {
            sops-nix = inputs.sops-nix;
          };
        };
      in
      {
        nixosConfigurations."nami" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nix/hosts/nami
          ];
          specialArgs = {
            nixvirt = inputs.nixvirt;
            guests = {
              newt = self.packages.x86_64-linux.newt;
            };
          };
        };

        nixosConfigurations."newt" = mkGuestSystem "newt";

        packages.x86_64-linux = {
          newt = mkGuestImage "newt";
        };
        #nixosConfigurations."authentik" = nixpkgs.lib.nixosSystem {
        #  system = "x86_64-linux";
        #  modules = [ ./nix/hosts/authentik ];
        #  specialArgs = { inherit inputs; };
        #};
        #nixosConfigurations."omni" = nixpkgs.lib.nixosSystem {
        #  system = "x86_64-linux";
        #  modules = [ ./nix/hosts/omni ];
        #  specialArgs = { inherit inputs; };
        #};
        #nixosConfigurations."newt" = nixpkgs.lib.nixosSystem {
        #  system = "x86_64-linux";
        #  modules = [
        #    ./nix/hosts/newt
        #  ];
        #  specialArgs = { inherit inputs; };
        #};
      };
    };
}
