{ lib, ... }:

{
  templates.app = {
    options = {
      workload = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "Enable Deployment";

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
        };
        description = "Deployment configuration";
      };

      persistence = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
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
        });
        description = "Persistence configuration";
      };

      route = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "Enable HTTPRoute";

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
        };
        description = "Route configuration";
      };
    };

    output = { name, config, ...  }: let
      cfg = config;
    in {
      deployments.${name} = lib.mkIf cfg.workload.enable
        (import ./resources/deployment.nix {
          inherit lib;
          inherit name;
          inherit config;
        });

      services.${name} = lib.mkIf cfg.workload.enable
        (import ./resources/service.nix {
          inherit name;
          inherit config;
        });

      core.v1.PersistentVolumeClaim = lib.mapAttrs (name: pvc: lib.mkIf (pvc.type == "pvc") (import ./resources/pvc.nix {
        inherit config;
        inherit lib;
        inherit name;
      })) cfg.persistence;

      "gateway.networking.k8s.io".v1.HTTPRoute.${name} = lib.mkIf cfg.route.enable 
        (import ./resources/httproute.nix {
          inherit name;
          inherit config;
        });
    };
  };
}
