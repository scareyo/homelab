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
        cfg = config;
      in {
        redis.${name} = {
          spec = {
            podSecurityContext = {
              runAsUser = 1000;
              fsGroup = 1000;
            };
            kubernetesConfig.image = cfg.image;
            storage.volumeClaimTemplate.spec = {
              accessModes = [ "ReadWriteOnce" ];
              resources.requests.storage = cfg.size;
            };
          };
        };
      };
    };
  };
}
