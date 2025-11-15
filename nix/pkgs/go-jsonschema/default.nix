{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "go-jsonschema";
  version = "0.20.0";

  src = fetchFromGitHub {
    owner = "omissis";
    repo = "go-jsonschema";
    rev = "v${version}";
    sha256 = "sha256-e1eL5Blf9l4cSR7Tg740eTFza3ViJEiwLaoUsUZzQu4=";
  };

  excludedPackages = [
    "./tests"
  ];

  vendorHash = "sha256-sWN5oAkHRbxwb0Y+EmxtdrfZcYKM1NE5H3FQTjvHRIg=";

  doCheck = false;
  proxyVendor = true;

  buildInputs = [
  ];

  #propagatedBuildInputs = [ go ];

  #allowGoReference = true;

  meta = {
    description = "A tool to generate Go data types from JSON Schema definitions";
    homepage = "https://github.com/omissis/go-jsonschema";
    license = lib.licenses.mit;
  };
}
