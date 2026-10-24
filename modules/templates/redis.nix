let
  images = {
    redis = {
      image = "quay.io/opstree/redis";
      version = "v7.4.11";
    };
  };
in {
  flake.modules.templates.redis = { lib, ... }: {
    templates.redis = {
      options = {
        clusterSize = lib.mkOption {
          type = lib.types.int;
          default = 3;
          description = "Number of leaders and followers";
        };

        image = lib.mkOption {
          type = lib.types.str;
          default = "${images.redis.image}:${images.redis.version}";
          description = "Redis image";
        };

        size = lib.mkOption {
          type = lib.types.str;
          default = "1Gi";
          description = "Size of the storage";
        };
      };

      output = { name, config, ... }: let
        volumeClaimTemplate = size: {
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            resources.requests.storage = size;
          };
        };
      in {
        redisClusters.${name} = {
          spec = {
            clusterSize = config.clusterSize;
            clusterVersion = "v7";
            persistenceEnabled = true;
            podSecurityContext = {
              runAsUser = 1000;
              fsGroup = 1000;
            };
            kubernetesConfig.image = config.image;
            storage = {
              volumeClaimTemplate = volumeClaimTemplate config.size;
              nodeConfVolume = true;
              nodeConfVolumeClaimTemplate = volumeClaimTemplate "1Gi";
            };
          };
        };
      };
    };
  };
}
