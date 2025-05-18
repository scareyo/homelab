{ pkgs, ... }:

{
  imports = [
    ../../modules/system/guest.nix
    ../../modules/sops
  ];

  networking.hostName = "newt";

  homelab.sops = {
    enable = true;
    file = ../../../sops/newt.json;
  };

  environment.systemPackages = with pkgs; [
    jq
    newt-go
  ];

  users.users.newt = {
    isSystemUser = true;
    description = "Newt system user";
    group = "newt";
  };

  users.groups.newt = {};

  systemd.services.newt = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    description = "Newt";
    serviceConfig = {
      Type = "notify";
      User = "newt";
      ExecStart = "newt --id $(jq -r .newt_id /run/secrets/host) --secret $(jq -r .newt_secret /run/secrets/host) --endpoint https://scarey.me";
      Restart = "always";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
