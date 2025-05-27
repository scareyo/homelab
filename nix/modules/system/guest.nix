{ ... }:

{
  imports = [
    ./base.nix
  ];

  config = {
    system.autoUpgrade.dates = "07:00 UTC";
    services.qemuGuest.enable = true;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
  };
}
