{ ... }:

{
  imports = [
    ./base.nix
  ];

  config = {
    system.autoUpgrade.dates = "07:30 UTC";
  };
}
