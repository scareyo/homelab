{ lib, name, persistence, workload }:

{
  metadata = {
    labels = {
      "app.kubernetes.io/name" = name;
      "app.kubernetes.io/instance" = name;
    };
  };
  spec = {
    replicas = 1;
    selector = {
      matchLabels = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      };
    };
    template = {
      metadata = {
        labels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = name;
        };
      };
      spec = {
        containers.${name} = {
          image = workload.image;

          env = builtins.mapAttrs
            (_: v: { value = v; }) workload.env;

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

        dnsPolicy = "Default";

        volumes = lib.mapAttrsToList (name: volume: {
          name = name;
        }
        // lib.optionalAttrs (volume.type == "emptyDir") {
          emptyDir = {};
        }
        // lib.optionalAttrs (volume.type == "pvc") {
          persistentVolumeClaim.claimName = name;
        }) persistence;
      };
    };
  };
}
