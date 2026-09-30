{
  flake.modules.nixidy.argocd = { lib, ... }: let
    namespace = "argocd";
    project = "default";
    chart = lib.helm.downloadHelmChart {
      repo = "https://argoproj.github.io/argo-helm";
      chart = "argo-cd";
      version = "10.9.2";
      chartHash = "sha256-OA7qeOnu6I8q7p1WL5XA0jXdZ+RMb9xQgyvzpJAuDQ0=";
    };
  in {
    applications.argocd = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.argocd = {
        inherit chart;
      };
    };
  };
}
