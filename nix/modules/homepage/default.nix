{ config, lib, ... }:

let
  cfg = config.vegapunk.homepage;
  namespace = "homepage";
in
{
  options = {
    vegapunk.homepage.enable = lib.mkEnableOption "Enable Homepage";
  };

  config = lib.mkIf cfg.enable {
    applications.homepage = {
      namespace = namespace;
      createNamespace = true;

      templates.app.homepage = {
        inherit namespace;

        workload = {
          image = "ghcr.io/gethomepage/homepage";
          version = "v1.8.0";
          port = 3000;
          env = {
            HOMEPAGE_ALLOWED_HOSTS = "home.vegapunk.cloud";
          };
        };

        persistence = {
          config = {
            type = "cm";
            path = "/app/config";
            config = {
              data = {
                "kubernetes.yaml" = ''
                  mode: cluster
                '';
                "bookmarks.yaml" = ''
                  - Developer:
                      - Github:
                        - abbr: GH
                          href: https://github.com/
                '';
                "services.yaml" = ''
                  - My First Group:
                      - My First Service:
                          href: http://localhost/
                          description: Homepage is awesome

                  - My Second Group:
                      - My Second Service:
                          href: http://localhost/
                          description: Homepage is the best

                  - My Third Group:
                      - My Third Service:
                          href: http://localhost/
                          description: Homepage is 😎
                '';
                "widgets.yaml" = ''
                  - kubernetes:
                      cluster:
                        show: true
                        cpu: true
                        memory: true
                        showLabel: true
                        label: "cluster"
                      nodes:
                        show: true
                        cpu: true
                        memory: true
                        showLabel: true
                  - resources:
                      backend: resources
                      expanded: true
                      cpu: true
                      memory: true
                      network: default
                  - search:
                      provider: duckduckgo
                      target: _blank
                '';
                "docker.yaml" = "";
                "custom.css" = "";
                "custom.js" = "";
                "proxmox.yaml" = "";
                "settings.yaml" = "";
              };
            };
          };
          logs = {
            type = "emptyDir";
            path = "/app/config/logs";
          };
        };

        route = {
          hostname = "home.vegapunk.cloud";
        };
      };
      resources = {
        deployments.homepage.spec.template.spec.serviceAccountName = "homepage";
        secrets.homepage = {
          type = "kubernetes.io/service-account-token";
          metadata = {
            labels."app.kubernetes.io/name" = "homepage";
            annotations."kubernetes.io/service-account.name" = "homepage";
          };
        };
        serviceAccounts.homepage = {
          metadata = {
            labels."app.kubernetes.io/name" = "homepage";
          };
          secrets = [{ name = "homepage"; }];
        };
        clusterRoles.homepage = {
          metadata = {
            labels."app.kubernetes.io/name" = "homepage";
          };
          rules = [
            {
              apiGroups = [ "" ];
              resources = [ "namespaces" "pods" "nodes" ];
              verbs = [ "get" "list" ];
            }
            {
              apiGroups = [ "extensions" "networking.k8s.io" ];
              resources = [ "ingresses" ];
              verbs = [ "get" "list" ];
            }
            {
              apiGroups = [ "gateway.networking.k8s.io" ];
              resources = [ "httproutes" "gateways" ];
              verbs = [ "get" "list" ];
            }
            {
              apiGroups = [ "metrics.k8s.io" ];
              resources = [ "nodes" "pods" ];
              verbs = [ "get" "list" ];
            }
          ];
        };
        clusterRoleBindings.homepage = {
          metadata = {
            labels."app.kubernetes.io/name" = "homepage";
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            name = "homepage";
          };
          subjects = [
            {
              kind = "ServiceAccount";
              name = "homepage";
              namespace = namespace;
            }
          ];
        };
      };
    };
  };
}
