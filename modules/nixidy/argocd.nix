{
  flake.modules.nixidy.argocd = { lib, ... }: {
    applications.argocd = {
      namespace = "argocd";
      project = "default";

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.argocd = {
        chart = lib.helm.downloadHelmChart {
          repo = "https://argoproj.github.io/argo-helm";
          chart = "argo-cd";
          version = "10.9.2";
          chartHash = "sha256-OA7qeOnu6I8q7p1WL5XA0jXdZ+RMb9xQgyvzpJAuDQ0=";
        };
      };
    };
  };
}
