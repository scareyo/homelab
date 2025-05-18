{ inputs, ... }:

let
  createVM = args: (import ../../lib/create-vm.nix) (args // { inherit inputs; });
in
{
  imports = [
    ../.
    ./hardware-configuration.nix

    (createVM {
      name = "authentik";
      uuid = "99a2210e-5a65-406d-8548-000000000001";
      vcpus = 4;
      memory = 8;
      mac = "52:54:00:20:20:61";
      diskSize = 32;
    })

    (createVM {
      name = "omni";
      uuid = "99a2210e-5a65-406d-8548-000000000002";
      vcpus = 4;
      memory = 8;
      mac = "52:54:00:20:20:62";
      diskSize = 32;
    })

    (createVM {
      name = "newt";
      uuid = "99a2210e-5a65-406d-8548-000000000003";
      vcpus = 4;
      memory = 8;
      mac = "52:54:00:20:20:63";
      diskSize = 32;
    })
  ];

  networking = {
    hostName = "nami";
    useDHCP = false;
    bridges = {
      "br0" = {
        interfaces = [ "eno1" ];
      };
    };
    interfaces.br0.useDHCP = true;
    interfaces.eno1.useDHCP = false;
  };

  virtualisation.libvirt = {
    enable = true;
  };

  system.autoUpgrade = {
    dates = "07:30 UTC";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
