{ lib, ... }:

{
  templates.app = {
    options = {
      namespace = lib.mkOption {
        type = lib.types.str;
        description = "Application namespace";
      };

      workload = lib.mkOption {
        type = lib.types.nullOr (import ./types/workload.nix { inherit lib; });
        default = null;
        description = "Deployment configuration";
      };

      persistence = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf (lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [
                "emptyDir"
                "pvc"
              ];
              default = "emptyDir";
              description = "Persistence type";
            };

            accessMode = lib.mkOption {
              type = lib.types.listOf (lib.types.enum [
                "ReadWriteOnce"
                "ReadOnlyMany"
                "ReadWriteMany"
                "ReadWriteOncePod"
              ]);
              default = [ "ReadWriteOnce" ];
              description = "Persistence access modes";
            };

            path = lib.mkOption {
              type = lib.types.str;
              description = "Persistence path";
            };

            size = lib.mkOption {
              type = lib.types.str;
              description = "Persistence storage size";
            };

            storageClass = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Persistence storage class";
            };
          };
        }));
        default = null;
        description = "Persistence configuration";
      };

      route = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            gateway = lib.mkOption {
              type = lib.types.str;
              default = "internal";
              description = "Gateway of the HTTPRoute";
            };

            hostname = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Hostname of the HTTPRoute";
            };

            serviceName = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Name of the referenced service";
            };

            servicePort = lib.mkOption {
              type = lib.types.int;
              default = 80;
              description = "Port of the referenced service";
            };

            enableAuth = lib.mkEnableOption "Enable OAuth2-Proxy";
          };
        });
        default = null;
        description = "Route configuration";
      };

      backup = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf (lib.types.submodule {
          options = {
            namespace = lib.mkOption {
              type = lib.types.str;
              default = "velero";
              description = "Namespace of the Velero resources";
            };

            restore = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable automatic volume restoration";
            };

            schedule = lib.mkOption {
              type = lib.types.str;
              description = "Backup schedule";
              example = "12h30m45s";
            };

            ttl = lib.mkOption {
              type = lib.types.str;
              description = "Duration to keep backups";
              example = "12h30m45s";
            };
          };
        }));
        default = null;
        description = "Backup configuration";
      };
    };

    output = { name, config, ...  }: let
      backup = config.backup;
      namespace = config.namespace;
      persistence = config.persistence;
      route = config.route;
      workload = config.workload;
    in {
      deployments.${name} = lib.mkIf (workload != null)
        (import ./resources/deployment.nix {
          inherit lib;
          inherit name;
          inherit persistence;
          inherit workload;
        });

      services.${name} = lib.mkIf (workload != null)
        (import ./resources/service.nix {
          inherit name;
          inherit workload;
        });

      core.v1.PersistentVolumeClaim = lib.mkIf (persistence != null)
        (lib.mapAttrs (name: pvc: lib.mkIf (pvc.type == "pvc")
          (import ./resources/pvc.nix {
            inherit lib;
            inherit name;
            inherit persistence;
          })) persistence);

      "gateway.networking.k8s.io".v1.HTTPRoute.${name} = lib.mkIf (route != null) 
        (import ./resources/httproute.nix {
          inherit lib;
          inherit name;
          inherit route;
        });

      "velero.io".v1.Restore = lib.mkIf (backup != null)
        (lib.mapAttrs (name: backup: lib.mkIf (backup.restore)
          (import ./resources/restore.nix {
            inherit name;
            inherit namespace;
            inherit backup;
          })) backup);

      "velero.io".v1.Schedule = lib.mkIf (backup != null)
        (lib.mapAttrs (name: backup:
          (import ./resources/schedule.nix {
            inherit name;
            inherit namespace;
            inherit backup;
          })) backup);

      deployments.oauth2-proxy = lib.mkIf (route != null && route.enableAuth)
        (import ./resources/deployment.nix {
          inherit lib;

          name = "oauth2-proxy";
          persistence = {};
          workload = {
            image = "quay.io/oauth2-proxy/oauth2-proxy:v7.13.0";
            port = 4180;
            env = {
              OAUTH2_PROXY_CLIENT_ID = {
                secretKeyRef = {
                  key = "client-id";
                  name = "oidc";
                };
              };
              OAUTH2_PROXY_CLIENT_SECRET = {
                secretKeyRef = {
                  key = "client-secret";
                  name = "oidc";
                };
              };
              OAUTH2_PROXY_COOKIE_SECRET = {
                secretKeyRef = {
                  key = "cookie-secret";
                  name = "oidc";
                };
              };
            };
          };
        });
    };
  };
}
