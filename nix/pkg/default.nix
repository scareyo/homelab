{ pkgs }:

rec {
  bitwarden-sdk = pkgs.callPackage ./bitwarden-sdk {};
  go-jsonschema = pkgs.callPackage ./go-jsonschema {};
  talm = pkgs.callPackage ./talm {};
  yoke = pkgs.callPackage ./yoke {
    inherit go-jsonschema;
  };
}
