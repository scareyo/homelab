{ lib, ... }:

{
  templates.valkey = {
    options = {
      instances = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Number of instances";
      };

      replicas = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Number of instances";
      };

      size = lib.mkOption {
        type = lib.types.str;
        default = "1Gi";
        description = "Size of the storage";
      };
    };

    output = { name, config, ...  }: let
      cfg = config;
    in {
      "hyperspike.io".v1.Valkey.${name} = {
        spec = {
          nodes = cfg.instances;
          replicas = cfg.replicas;
          storage.spec = {
            accessModes = [
              "ReadWriteOnce"
            ];
            volumeMode = "Filesystem";
            storageClassName = "ceph-block";
            resources.requests.storage = cfg.size;
          };
          volumePermissions = true;
          tls = false;
          anonymousAuth = false;
          clusterDomain = "cluster.local";
          prometheus = true;
          serviceMonitor = true;
        };
      };
    };
  };
}
