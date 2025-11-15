{ buildGoModule, fetchFromGitHub, go, go-jsonschema, lib, nodejs_24 }:

buildGoModule rec {
  pname = "yoke";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "yokecd";
    repo = "yoke";
    rev = "v${version}";
    sha256 = "sha256-AesSDxyl1mfsJhmUsJtXk4xPKDmjWpdipbyK70IDlb4=";
  };

  subPackages = [
    "cmd/yoke"
    "cmd/helm2go"
  ];

  vendorHash = "sha256-YgF7NHSs1L1w3yD0ssIH11yQr7nAIQ4xXAH5XpdorjA=";

  doCheck = false;

  buildInputs = [
    nodejs_24 go-jsonschema
  ];

  propagatedBuildInputs = [ go go-jsonschema ];

  allowGoReference = true;

  meta = {
    description = "A Helm-inspired infrastructure-as-code (IaC) package deployer";
    homepage = "https://github.com/yokecd/yoke";
    license = lib.licenses.mit;
  };
}
