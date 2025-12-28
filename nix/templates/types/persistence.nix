{ lib }:

lib.types.submodule {
  options = {
    type = lib.mkOption {
      type = lib.types.enum [
        "configMap"
        "emptyDir"
        "nfs"
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

    nfs = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          server = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "NFS server";
          };
          path = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "NFS remote path";
          };
          readOnly = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "NFS share read only";
          };
        };
      });
    };
  };
}
