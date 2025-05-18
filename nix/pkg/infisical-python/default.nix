{ fetchurl, python312Packages, system, ... }:

let
  url = {
    x86_64-linux = "https://files.pythonhosted.org/packages/4d/d5/76976935a03e9bda5e8c69e2ed7270a0a0c2f4b203fed5ec3da47d98c30f/infisical_python-2.3.5-cp312-cp312-manylinux_2_28_x86_64.whl";
    aarch64-darwin = "https://files.pythonhosted.org/packages/3e/58/79f6987d1471866231b3e45a5692a4d9f063abcb2291a8afde32cdf2d1f0/infisical_python-2.3.5-cp312-cp312-macosx_11_0_arm64.whl";
  };
  hash = {
    x86_64-linux = "sha256-jUJnExQ+xJ7cd+BZBZ2Xu0fzccVujeirg9YNLTt/I58=";
    aarch64-darwin = "sha256-2Gyfa/yIzEaU4oUNqAyCsFwUeZlTN7plCXF1KqzBwPo=";
  };
in
python312Packages.buildPythonPackage {
  pname = "infisical-python";
  version = "2.3.5";
  format = "wheel";

  src = fetchurl {
    url = url."${system}";
    hash = hash."${system}";
  };
}
