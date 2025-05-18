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
  };

  config = lib.mkIf config.homelab.sops.enable {
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    sops.age.generateKey = true;
    sops.secrets.host = {
      sopsFile = config.homelab.sops.file;
      format = "json";
    };

    #environment.etc."secrets.json".source = config.sops.secrets.host.path;
  };
}

