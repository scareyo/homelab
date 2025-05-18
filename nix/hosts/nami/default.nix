{ inputs, ... }:

let
  createVM = { name, uuid, memory, diskSize }: let
    imageDir = "/var/lib/libvirt/images";
    image = inputs.nixos-generators.nixosGenerate {
      system = "x86_64-linux";
      modules = [
        {
          virtualisation.diskSize = diskSize * 1024;
        }
        ../${name}
      ];
      format = "qcow-efi";
    };
  in
  {
    system.activationScripts."${name}".text = ''
      echo "Creating ${name} image"
      mkdir -p ${imageDir}
      if [ ! -f ${imageDir}/${name}.qcow2 ]; then
        cp ${image}/nixos.qcow2 ${imageDir}/${name}.qcow2
      fi
    '';

    virtualisation.libvirt = {
      enable = true;
      connections."qemu:///system".domains = [
        {
          active = true;
          definition = inputs.nixvirt.lib.domain.writeXML (inputs.nixvirt.lib.domain.templates.linux {
            name = name;
            uuid = uuid;
            memory = {
              count = memory;
              unit = "GiB";
            };
            storage_vol = "${imageDir}/${name}.qcow2";
            virtio_video = false;
          });
        }
      ];
    };
  };
in
{
  imports = [
    ../.
    ./hardware-configuration.nix

    (createVM {
      name = "authentik";
      uuid = "99a2210e-5a65-406d-8548-000000000001";
      memory = 8;
      diskSize = 32;
    })

    (createVM {
      name = "omni";
      uuid = "99a2210e-5a65-406d-8548-000000000002";
      memory = 8;
      diskSize = 32;
    })

    inputs.nixvirt.nixosModules.default
  ];

  networking = {
    hostName = "nami"; # Define your hostname.
    useDHCP = false;
    bridges = {
      "br0" = {
        interfaces = [ "eno1" ];
      };
    };
    interfaces.br0.useDHCP = true;
  };

  virtualisation.libvirt.connections."qemu:///system".networks = [
    {
      active = true;
      definition = inputs.nixvirt.lib.network.writeXML {
        name = "default";
        uuid = "99a2210e-5a65-406d-8549-000000000001";
        forward = {
          mode = "bridge";
        };
        bridge = { name = "br0"; };
      };
    }
  ];

  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;
    #settings = {
    #  WebService = {
    #    AllowUnencrypted = true;
    #  };
    #};
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
