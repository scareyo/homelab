{ lib, ... }:

{
  templates.postgres = {
    options = {
      instances = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Number of instances";
      };

      image = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/cloudnative-pg/postgresql:18";
        description = "PostgreSQL image";
      };

      size = lib.mkOption {
        type = lib.types.str;
        default = "32Gi";
        description = "Size of the storage";
      };

      database = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule ({
          options = {
            extensions = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Database extensions";
            };
          };
        }));
        default = null;
        description = "Database to create";
      };

      sharedPreloadLibraries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of shared_preload_libraries";
      };
    };

    output = { name, config, ...  }: let
      cfg = config;
    in {
      "postgresql.cnpg.io".v1.Cluster.${name} = {
        metadata = {
          name = name;
        };
        spec = {
          instances = cfg.instances;
          storage.size = cfg.size;
          imageName = cfg.image;
        } // lib.optionalAttrs (cfg.sharedPreloadLibraries != []) {
          postgresql.shared_preload_libraries = cfg.sharedPreloadLibraries;
        };
      };
      "postgresql.cnpg.io".v1.Database.${name} = lib.mkIf (cfg.database != null) {
        metadata = {
          name = name;
        };
        spec = {
          name = "app";
          owner = "app";
          cluster.name = name;
          extensions = lib.genAttrs cfg.database.extensions (_: {});
        };
      };
    };
  };
}
