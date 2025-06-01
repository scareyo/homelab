{ config, inputs, ... }:

{
  imports = [
    ../../modules/system/guest.nix
    ../../modules/sops

    inputs.authentik.nixosModules.default
  ];

  networking.hostName = "authentik";

  homelab.sops = {
    enable = true;
    file = ../../../sops/authentik.env;
    format = "dotenv";
    owner = config.users.users.scarey.name;
    group = config.users.users.scarey.group;
    secrets = [
      "authentik.env"
    ];
  };

  services.authentik = {
    enable = true;
    environmentFile = "/run/secrets/authentik.env";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
