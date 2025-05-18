{ config, inputs, pkgs, ... }:

{
  imports = [
    ../.
  ];

  networking.hostName = "newt";

  services.qemuGuest.enable = true;

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
      ExecStart = ''sh -c "newt --id $(jq -r .newt_id /etc/secrets.json) --secret $(jq -r .newt_secret /etc/secrets.json) --endpoint https://scarey.me"'';
      Restart = "always";
    };
  };

  # This will add secrets.yml to the nix store
  # You can avoid this by adding a string to the full path instead, i.e.
  # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
  #sops.defaultSopsFile = ../../../sops/newt.json;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  # This is using an age key that is expected to already be in the filesystem
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  # This will generate a new key if the key specified above does not exist
  sops.age.generateKey = true;
  # This is the actual specification of the secrets.
  sops.secrets.newt = {
    sopsFile = ../../../sops/newt.json;
    format = "json";
  };

  environment.etc."secrets.json".source = config.sops.secrets.newt.path;

  system.autoUpgrade = {
    dates = "07:00 UTC";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
