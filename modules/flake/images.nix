{ inputs, ... }:

{
  perSystem = { lib, pkgs, system, ... }: let
    inherit (inputs.nix2container.packages.${system}) nix2container;

    user = "user";
    group = "user";
    uid = "1000";
    gid = "1000";

    mkUser = pkgs.runCommand "mkUser" { } ''
      mkdir -p $out/etc/pam.d

      echo "${user}:x:${uid}:${gid}::" > $out/etc/passwd
      echo "${user}:!x:::::::" > $out/etc/shadow

      echo "${group}:x:${gid}:" > $out/etc/group
      echo "${group}:x::" > $out/etc/gshadow

      cat > $out/etc/pam.d/other <<EOF
      account sufficient pam_unix.so
      auth sufficient pam_rootok.so
      password requisite pam_unix.so nullok sha512
      session required pam_unix.so
      EOF

      touch $out/etc/login.defs
    '';

    mkHome = pkgs.runCommand "mkHome" { } "mkdir -p $out/home/${user} $out/tmp $out/run";

    entrypoint = pkgs.writeShellApplication {
      name = "entrypoint";
      text = ''
        (nix --extra-experimental-features nix-command config check && ls -la /nix) >out 2>&1 && cat out
      '';
    };
  in {
    packages.renovate = nix2container.buildImage {
      name = "scarey.dev/scarey/renovate";
      tag = pkgs.renovate.version;

      initializeNixDatabase = true;

      copyToRoot = pkgs.buildEnv {
        name = "root";
        paths = [
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
      };

      config = {
        Cmd = [ "renovate" ];
        Env = [ "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" ];
      };
    };

    packages.forgejo-runner = nix2container.buildImage {
      name = "scarey.dev/scarey/forgejo-runner";
      tag = inputs.nixpkgs.shortRev;

      initializeNixDatabase = true;

      nixUid = lib.toInt uid;
      nixGid = lib.toInt gid;

      copyToRoot = [
        (pkgs.buildEnv {
          name = "root";
          paths = [
            pkgs.attic-client
            pkgs.bash
            pkgs.cacert
            pkgs.coreutils
            pkgs.dockerTools.usrBinEnv
            pkgs.gitMinimal
            pkgs.gnutar
            pkgs.gzip
            pkgs.nix
            pkgs.nodejs_22
            pkgs.skopeo
            mkUser

            (pkgs.writeTextDir "etc/nix/nix.conf" ''
              experimental-features = nix-command flakes
              build-users-group = user
              ssl-cert-file = /etc/ssl/certs/ca-bundle.crt
            '')
          ];
        })
        mkHome
      ];

      perms = [{
        path = mkHome;
        regex = "/home/${user}";
        mode = "0744";
        uid = lib.toInt uid;
        gid = lib.toInt gid;
        uname = user;
        gname = group;
      }
      {
        path = mkHome;
        regex = "/(tmp|run)$";
        mode = "1777";
      }];

      config = {
        Entrypoint = [ "${entrypoint}/bin/entrypoint" ];
        User = "user";
        WorkingDir = "/home/user";
        Env = [
          "HOME=/home/user"
          "NIX_PAGER=cat"
          "USER=user"
          "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        ];
      };
    };
  };
}
