{ config, inputs, lib, ... }:

let
  sopsTypes = import ./types.nix { inherit lib; };
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options = {
    homelab.sops.enable = lib.mkEnableOption "sops";
    homelab.sops.secrets = lib.mkOption {
      type = lib.types.listOf sopsTypes.secret;
      description = "List of keys to retrieve from SOPS";
    };
  };

  config = lib.mkIf config.homelab.sops.enable {
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    sops.age.generateKey = true;
    sops.secrets = lib.listToAttrs (map (key: {
      name = key.name;
      value = {
        sopsFile = key.file;
        format = key.format;
        owner = key.owner;
        group = key.group;
      };
    }) config.homelab.sops.secrets);
  };
}
