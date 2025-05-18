{ ... }:

{
  imports = [
    ./base.nix
  ];

  config = {
    system.autoUpgrade.dates = "07:00 UTC";
    services.qemuGuest.enable = true;
  };
}
