{
  flake.modules.apps.argocd = { lib, ... }: let
    namespace = "argocd";
    project = "system";
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

      resources.appProjects = {
        system.spec = {
          sourceRepos = [ "*" ];
          destinations = [{ namespace = "*"; server = "*"; }];
          clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
        };
      };
    };
  };
}
