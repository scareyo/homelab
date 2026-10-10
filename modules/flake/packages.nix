{ inputs, ... }:

{
  perSystem = { pkgs, system, ... }: {
    packages.update-hash = pkgs.writeShellApplication {
      name = "update-hash";
      runtimeInputs = with pkgs; [ gawk gnugrep gnused coreutils kubernetes-helm nix ];
      text = builtins.readFile ../../scripts/update-hash.sh;    };

    packages.generate-manifests = pkgs.writeShellApplication {
      name = "generate-manifests";
      runtimeInputs = with pkgs; [ bash coreutils git gitleaks trufflehog inputs.nixidy.packages.${system}.default ];
      text = builtins.readFile ../../scripts/generate-manifests.sh;
    };
  };
}
