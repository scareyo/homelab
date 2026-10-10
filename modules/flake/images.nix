{
  perSystem = { pkgs, ... }: {
    packages.renovate = pkgs.dockerTools.buildLayeredImageWithNixDb {
      name = "scarey.dev/scarey/renovate";
      tag = pkgs.renovate.version;

      contents = [
        pkgs.bash
        pkgs.cacert
        pkgs.dockerTools.usrBinEnv
        pkgs.gitMinimal
        pkgs.nix
        pkgs.renovate

        (pkgs.writeTextDir "etc/nix/nix.conf" ''
          experimental-features = nix-command flakes
          build-users-group =
          ssl-cert-file = /etc/ssl/certs/ca-bundle.crt
        '')
      ];

      config = {
        Cmd = [ "renovate" ];
        Env = [ "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" ];
      };
    };
  };
}
