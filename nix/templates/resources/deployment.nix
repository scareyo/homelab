{ lib, labels, name, persistence, workload }:

let
  template = {
    metadata = {
      inherit labels;
    };
    spec = {
      containers.${name} = {
        image = "${workload.image}:${workload.version}";

        args = workload.args;

        env = builtins.mapAttrs
          (_: v: {
            value = lib.mkIf (lib.isString v) v;
            valueFrom = lib.mkIf (lib.isAttrs v) v;
          }) workload.env;

        ports.http = lib.mkIf (workload.port != null) {
          containerPort = workload.port;
        };

        securityContext = {
          allowPrivilegeEscalation = false;
          capabilities.drop = [ "ALL" ];
          readOnlyRootFilesystem = true;
        };

        volumeMounts = lib.mapAttrsToList (name: volume: {
          name = name;
          mountPath = volume.path;
        }) persistence;
      };

      securityContext = {
        runAsUser = 1000;
        runAsGroup = 1000;
        fsGroup = 65534;
        fsGroupChangePolicy = "OnRootMismatch";
      };

      volumes = lib.mapAttrsToList (name: volume: {
        name = name;
      }
      // lib.optionalAttrs (volume.type == "cm") {
        configMap.name = name;
      }
      // lib.optionalAttrs (volume.type == "emptyDir") {
        emptyDir = {};
      }
      // lib.optionalAttrs (volume.type == "nfs") {
        nfs = {
          server = volume.config.server;
          path = volume.config.path;
          readOnly = volume.config.readOnly;
        };
      }
      // lib.optionalAttrs (volume.type == "pvc") {
        persistentVolumeClaim.claimName = name;
      }) persistence;
    } // lib.optionalAttrs (workload.type == "cronjob") {
      restartPolicy = "OnFailure";
    };
  };
in {
  metadata = {
    inherit labels;
  };
  spec = {
  } // lib.optionalAttrs (workload.type == "cronjob") {
    schedule = "0 0 * * *";
    jobTemplate = {
      spec.template = template;
    };
  } // lib.optionalAttrs (workload.type == "deployment") {
    replicas = 1;
    selector = {
      matchLabels = {
        "app.kubernetes.io/name" = labels."app.kubernetes.io/name" or name;
        "app.kubernetes.io/instance" = labels."app.kubernetes.io/instance" or name;
      };
    };
    template = template;
  };
}
