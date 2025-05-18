{ fetchurl, python312Packages, ... }:

python312Packages.buildPythonPackage {
  pname = "infisicalsdk";
  version = "1.0.8";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/d0/88/0a49dea68015764839f41cb5a5d8128b76e6af530de293fae21c282bb2e8/infisicalsdk-1.0.8-py3-none-any.whl";
    hash = "sha256-EhYPn437y8yK9lEqUYlhyqp4g0dX0RwdmAkjOdPbK7w=";
  };

  dependencies = [
    python312Packages.boto3
    python312Packages.botocore
  ];
}
