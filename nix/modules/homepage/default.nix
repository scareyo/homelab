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

      templates.externalSecret.integrations = {
        keys = [
          { source = "/homepage/JELLYFIN_API_KEY"; dest = "jellyfin-api-key"; }
          { source = "/homepage/SEERR_API_KEY"; dest = "seerr-api-key"; }
          { source = "/sonarr/API_KEY"; dest = "sonarr-api-key"; }
          { source = "/radarr/API_KEY"; dest = "radarr-api-key"; }
        ];
      };

      templates.app.homepage = {
        inherit namespace;

        workload = {
          image = "ghcr.io/gethomepage/homepage";
          version = "v1.8.0";
          port = 3000;
          env = {
            HOMEPAGE_ALLOWED_HOSTS = "home.vegapunk.cloud";
            HOMEPAGE_VAR_JELLYFIN_API_KEY = {
              secretKeyRef = {
                name = "integrations";
                key = "jellyfin-api-key";
              };
            };
            HOMEPAGE_VAR_RADARR_API_KEY = {
              secretKeyRef = {
                name = "integrations";
                key = "radarr-api-key";
              };
            };
            HOMEPAGE_VAR_SEERR_API_KEY = {
              secretKeyRef = {
                name = "integrations";
                key = "seerr-api-key";
              };
            };
            HOMEPAGE_VAR_SONARR_API_KEY = {
              secretKeyRef = {
                name = "integrations";
                key = "sonarr-api-key";
              };
            };
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
                "settings.yaml" = ''
                  title: vegapunk.cloud
                  headerStyle: underlined
                  theme: dark
                  #background:
                  #  image: https://images.alphacoders.com/134/thumb-1920-1344005.jpeg
                  #  blur: sm
                  layout:
                    Media:
                      style: row
                      columns: 4
                '';
                "bookmarks.yaml" = ''
                  - Developer:
                      - scareyo/homelab:
                          - icon: github
                            description: My k8s homelab infrastructure
                            href: https://github.com/scareyo/homelab
                '';
                "services.yaml" = ''
                  - Media:
                      - Jellyfin:
                          icon: jellyfin
                          description: Watch movies and shows
                          href: https://jellyfin.vegapunk.cloud
                          siteMonitor: http://jellyfin.jellyfin
                          widget:
                            type: jellyfin
                            url: http://jellyfin.jellyfin
                            key: "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}"
                            enableBlocks: true
                            enableNowPlaying: true
                            enableUser: true
                            enableMediaControl: false
                            showEpisodeNumber: true
                            expandOneStreamToTwoRows: false
                      - Seerr:
                          icon: jellyseerr
                          description: Requeset movies and shows
                          href: https://seerr.vegapunk.cloud
                          siteMonitor: http://seerr.seerr
                          widget:
                            type: jellyseerr
                            url: http://seerr.seerr
                            key: "{{HOMEPAGE_VAR_SEERR_API_KEY}}"
                      - Sonarr:
                          icon: sonarr
                          description: Monitor show releases
                          href: https://sonarr.vegapunk.cloud
                          siteMonitor: http://sonarr.sonarr
                          widget:
                            type: sonarr
                            url: http://sonarr.sonarr
                            key: "{{HOMEPAGE_VAR_SONARR_API_KEY}}"
                            enableQueue: true
                      - Radarr:
                          icon: radarr
                          description: Monitor movie releases
                          href: https://radarr.vegapunk.cloud
                          siteMonitor: http://radarr.radarr
                          widget:
                            type: radarr
                            url: http://radarr.radarr
                            key: "{{HOMEPAGE_VAR_RADARR_API_KEY}}"
                            enableQueue: true
                '';
                "widgets.yaml" = ''
                  - logo:
                      icon: google
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
                  - datetime:
                      text_size: xl
                      format:
                        timeStyle: short
                        hourCycle: h23
                  - openmeteo:
                      label: Boston
                      latitude: 42.361145
                      longitude: -71.057083
                      timezone: America/New_York
                      units: imperial
                      cache: 5
                      format:
                        maximumFractionDigits: 0
                '';
                "docker.yaml" = "";
                "custom.css" = "";
                "custom.js" = "";
                "proxmox.yaml" = "";
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
