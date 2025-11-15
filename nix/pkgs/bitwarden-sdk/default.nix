{ python3Packages, rustPlatform, ... }:

python3Packages.buildPythonPackage rec {
  pname = "bitwarden_sdk";
  version = "1.0.0";
  pyproject = true;

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-hGvITrwpujJiEeZVLmKM19AAqYbvNVUv/anRC96RPiE=";
  };

  dependencies = [
    python3Packages.dateutils
  ];

  # TODO: Workaround for https://github.com/bitwarden/sdk-sm/issues/1148
  #       Remove once https://github.com/bitwarden/sdk-sm/pull/1221 is merged
  patchPhase = ''
    touch LICENSE
  '';

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit pname version src;
    hash = "sha256-VTJCPmmogjJpH8juP9KhrpeyK2EszFgAKrATyy44nMo=";
  };

  nativeBuildInputs = with rustPlatform; [ cargoSetupHook maturinBuildHook ];
}
