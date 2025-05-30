{
  description = "A scarey homelab";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.amtcli.url = "github:scareyo/amtcli";

  inputs.quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, amtcli, flake-parts, home-manager, nixpkgs, quadlet-nix, sops-nix }:
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
            yq-go

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

            # Update .sops.yaml host keys
            (pkgs.writeShellScriptBin "update-sops" ''
              for ((i=0; i<$(yq '.host_keys | length' .sops.yaml); i++)); do
                host=$(yq ".host_keys | to_entries[$i].key" .sops.yaml)
                ssh-keyscan $host > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                  newKey=$(ssh-keyscan $host | ${pkgs.ssh-to-age}/bin/ssh-to-age)
                  yq -i ".host_keys.$host = \"$newKey\"" .sops.yaml
                fi
              done
              sops updatekeys sops/*
            '')
          ];
        };
      };
        
      flake = {
        nixosConfigurations."nami" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nix/hosts/nami ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}
