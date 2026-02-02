{ lib, ... }:

{
  templates.app = {
    options = {
      namespace = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Application namespace";
      };

      workload = lib.mkOption {
        type = lib.types.nullOr (import ./types/workload.nix { inherit lib; });
        default = null;
        description = "Deployment configuration";
      };

      persistence = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf (import ./types/persistence.nix { inherit lib; }));
        default = null;
        description = "Persistence configuration";
      };

      route = lib.mkOption {
        type = lib.types.nullOr (import ./types/route.nix { inherit lib; });
        default = null;
        description = "Route configuration";
      };

      backup = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf (import ./types/backup.nix { inherit lib; }));
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

      oauth2-proxy = import ./resources/oauth2-proxy.nix {
        inherit lib; inherit name; inherit namespace; inherit route;
      };

      anubis = import ./resources/anubis.nix {
        inherit lib; inherit name; inherit namespace; inherit route;
      };

      labels = lib.mkIf (workload != null) {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" =  name;
        "app.kubernetes.io/version" = workload.version;
        "app.kubernetes.io/component" = "main";
        "app.kubernetes.io/part-of" = namespace;
      };
    in {
      deployments = {
        ${name} = lib.mkIf (workload != null && workload.type == "deployment")
          (import ./resources/deployment.nix {
            inherit lib;
            inherit labels;
            inherit name;
            inherit persistence;
            inherit workload;
          });
      } // lib.optionalAttrs (route != null && route.auth.enable) {
        oauth2-proxy = oauth2-proxy.deployment;
      } // lib.optionalAttrs (route != null && route.anubis.enable) {
        anubis = anubis.deployment;
      };

      cronJobs = {
        ${name} = lib.mkIf (workload != null && workload.type == "cronjob")
          (import ./resources/deployment.nix {
            inherit lib;
            inherit labels;
            inherit name;
            inherit persistence;
            inherit workload;
          });
      };

      services = {
        ${name} = lib.mkIf (workload != null && workload.port != null)
          (import ./resources/service.nix {
            inherit name;
            inherit labels;
          });
      } // lib.optionalAttrs (route != null && route.auth.enable) {
        oauth2-proxy = oauth2-proxy.service;
      } // lib.optionalAttrs (route != null && route.anubis.enable) {
        anubis = anubis.service;
      };
      
      configMaps = lib.mkMerge [(lib.mkIf (persistence != null)
        ((lib.mapAttrs (name: persistence: lib.mkIf (persistence.type == "cm")
          (import ./resources/configmap.nix {
            inherit labels;
            inherit persistence;
          })) persistence)))
      (lib.optionalAttrs (route != null && route.auth.enable) {
        oauth2-proxy = oauth2-proxy.configMap;
      })];

      core.v1.PersistentVolume = lib.mkIf (persistence != null)
        (lib.mapAttrs (name: p: lib.mkIf (p.type == "pvc" && p.config.nfs.enable)
          (import ./resources/pv.nix {
            inherit lib;
            inherit labels;
            inherit name;
            inherit persistence;
          })) persistence);

      core.v1.PersistentVolumeClaim = lib.mkIf (persistence != null)
        (lib.mapAttrs (name: p: lib.mkIf (p.type == "pvc")
          (import ./resources/pvc.nix {
            inherit lib;
            inherit labels;
            inherit name;
            inherit persistence;
          })) persistence);

      "gateway.networking.k8s.io".v1.HTTPRoute.${name} = lib.mkIf (route != null) 
        (import ./resources/httproute.nix {
          inherit lib;
          inherit labels;
          inherit name;
          inherit route;
        });

      "velero.io".v1.Restore = lib.mkIf (backup != null)
        (lib.mapAttrs (name: backup: lib.mkIf (backup.restore)
          (import ./resources/restore.nix {
            inherit labels;
            inherit name;
            inherit namespace;
            inherit backup;
          })) backup);

      "velero.io".v1.Schedule = lib.mkIf (backup != null)
        (lib.mapAttrs (name: backup:
          (import ./resources/schedule.nix {
            inherit labels;
            inherit name;
            inherit namespace;
            inherit backup;
          })) backup);
    };
  };
}
