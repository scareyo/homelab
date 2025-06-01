{ config, inputs, lib, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options = {
    homelab.sops.enable = lib.mkEnableOption "sops";
    homelab.sops.file = lib.mkOption {
      type = lib.types.path;
      description = "Path to SOPS file";
    };
    homelab.sops.format = lib.mkOption {
      type = lib.types.str;
      description = "Format of SOPS file";
    };
    homelab.sops.owner = lib.mkOption {
      type = lib.types.str;
      description = "User owner of the secret";
    };
    homelab.sops.group = lib.mkOption {
      type = lib.types.str;
      description = "Group owner of the secret";
    };
    homelab.sops.secrets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of keys to retrieve from SOPS";
    };
  };

  config = lib.mkIf config.homelab.sops.enable {
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    sops.age.generateKey = true;
    sops.secrets = lib.listToAttrs (map (key: {
      name = key;
      value = {
        sopsFile = config.homelab.sops.file;
        format = config.homelab.sops.format;
        owner = config.homelab.sops.owner;
        group = config.homelab.sops.group;
      };
    }) config.homelab.sops.secrets);
  };
}
