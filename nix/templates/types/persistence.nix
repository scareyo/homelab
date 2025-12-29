{ lib }:

let
  cm = {
    options = {
      data = lib.mkOption {
        type = lib.types.str;
        description = "ConfigMap data";
      };
    };
  };

  nfs = {
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
  };

  pvc = {
    options = {
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

      size = lib.mkOption {
        type = lib.types.str;
        description = "Persistence PVC storage size";
      };

      storageClass = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Persistence PVC storage class";
      };
    };
  };
in lib.types.submodule ({ config, ... }: {
  options = {
    type = lib.mkOption {
      type = lib.types.enum [
        "cm"
        "emptyDir"
        "nfs"
        "pvc"
      ];
      default = "emptyDir";
      description = "Persistence type";
    };

    path = lib.mkOption {
      type = lib.types.str;
      description = "Persistence mount path";
    };

    config = lib.mkOption {
      type = lib.types.submoduleWith {
        modules =
          lib.optionals (config.type == "cm") [ cm ] ++
          lib.optionals (config.type == "nfs") [ nfs ] ++
          lib.optionals (config.type == "pvc") [ pvc ];
      };
      default = {};
      description = "Persistence type specific options";
    };
  };
})
