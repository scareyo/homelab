{ lib, labels, name, persistence, workload }:

{
  metadata = {
    inherit labels;
  };
  spec = {
    replicas = 1;
    selector = {
      matchLabels = {
        "app.kubernetes.io/name" = labels."app.kubernetes.io/name" or name;
        "app.kubernetes.io/instance" = labels."app.kubernetes.io/instance" or name;
      };
    };
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

          ports.http.containerPort = workload.port;
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

        dnsPolicy = workload.dnsPolicy;

        volumes = lib.mapAttrsToList (name: volume: {
          name = name;
        }
        // lib.optionalAttrs (volume.type == "emptyDir") {
          emptyDir = {};
        }
        // lib.optionalAttrs (volume.type == "pvc") {
          persistentVolumeClaim.claimName = name;
        }
        // lib.optionalAttrs (volume.type == "configMap") {
          configMap.name = name;
        }) persistence;
      };
    };
  };
}
