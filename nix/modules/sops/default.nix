{ config, lib, sops-nix, ... }:

{
  imports = [
    sops-nix.nixosModules.sops
  ];

  options = {
    homelab.sops.enable = lib.mkEnableOption "sops";
    homelab.sops.file = lib.mkOption {
      type = lib.types.path;
      description = "Path to SOPS JSON file";
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
    #sops.secrets."" = {
    #  sopsFile = config.homelab.sops.file;
    #  format = "json";
    #};
    sops.secrets = lib.listToAttrs (map (key: {
      name = key;
      value = {
        sopsFile = config.homelab.sops.file;
        format = "json";
      };
    }) config.homelab.sops.secrets);

    #environment.etc."secrets.json".source = config.sops.secrets.host.path;
  };
}
