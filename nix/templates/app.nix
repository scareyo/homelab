{ lib, ... }:

{
  templates.app = {
    options = {
      namespace = lib.mkOption {
        type = lib.types.str;
        description = "Application namespace";
      };

      workload = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            image = lib.mkOption {
              type = lib.types.str;
              description = "Deployment container image";
            };

            port = lib.mkOption {
              type = lib.types.int;
              description = "Deployment container port";
            };

            env = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "Deployment container env";
            };
          };
        });
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
          };
        });
        default = null;
        description = "Route configuration";
      };
      backup = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
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
        });
        description = "Backup configuration";
      };
    };

    output = { name, config, ...  }: let
      cfg = config;
    in {
      deployments.${name} = lib.mkIf (cfg.workload != null)
        (import ./resources/deployment.nix {
          inherit config;
          inherit lib;
          inherit name;
        });

      services.${name} = lib.mkIf (cfg.workload != null)
        (import ./resources/service.nix {
          inherit config;
          inherit name;
        });

      core.v1.PersistentVolumeClaim = lib.mkIf (cfg.persistence != null)
        (lib.mapAttrs (name: pvc: lib.mkIf (pvc.type == "pvc")
          (import ./resources/pvc.nix {
            inherit config;
            inherit lib;
            inherit name;
          })) cfg.persistence);

      "gateway.networking.k8s.io".v1.HTTPRoute.${name} = lib.mkIf (cfg.route != null) 
        (import ./resources/httproute.nix {
          inherit config;
          inherit name;
        });

      "velero.io".v1.Restore = lib.mapAttrs (name: backup: lib.mkIf (backup.restore)
        (import ./resources/restore.nix {
          inherit config;
          inherit name;
        })) cfg.backup;

      "velero.io".v1.Schedule = lib.mapAttrs (name: backup:
        (import ./resources/schedule.nix {
          inherit config;
          inherit name;
        })) cfg.backup;
    };
  };
}
