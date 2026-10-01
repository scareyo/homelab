{
  flake.modules.apps.openbao = { lib, ... }: let
    namespace = "openbao";
    project = "default";
    chart = lib.helm.downloadHelmChart {
      repo = "https://openbao.github.io/openbao-helm";
      chart = "openbao";
      version = "0.30.0";
      chartHash = "sha256-R6qWSFTtsbpdlu3mDLZCJfk1qLKUTidYOmM+QVxyRoY=";
    };
  in {
    applications.openbao = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.openbao = {
        inherit chart;
      };
    };
  };
}
