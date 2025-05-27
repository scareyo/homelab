{ config, lib, nixvirt, guests, ... }:

let
  vmTypes = import ./types.nix { inherit lib; };

  imageDir = "/var/lib/libvirt/images";
in
{
  imports = [
    nixvirt.nixosModules.default
  ];

  options = {
    homelab.vm.enable = lib.mkEnableOption "virtual machines";
    homelab.vm.vms = lib.mkOption {
      description = "Definition of virtual machines";
      type = lib.types.listOf vmTypes.vm;
      default = {};
    };
  };

  config = lib.mkIf config.homelab.vm.enable {
    system.activationScripts = lib.listToAttrs (map (vm: {
      name = vm.name;
      value = let
        image = guests.${vm.name};
      in
      {
        text = ''
          echo "Creating ${vm.name} image"
          mkdir -p ${imageDir}
          if [ ! -f ${imageDir}/${vm.name}.qcow2 ]; then
            cp ${image}/nixos.qcow2 ${imageDir}/${vm.name}.qcow2
          fi
        '';
      };
    }) config.homelab.vm.vms);

    virtualisation.libvirt = {
      enable = true;
      connections."qemu:///system".domains = map (vm: {
        active = true;
        definition = import ./domain.nix {
          inherit nixvirt;
          name = vm.name;
          uuid = vm.uuid;
          memory = vm.memory;
          vcpus = vm.vcpus;
          mac = vm.mac;
          disk = "${imageDir}/${vm.name}.qcow2";
        };
      }) config.homelab.vm.vms;
    };
  };
}
