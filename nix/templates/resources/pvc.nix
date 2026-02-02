{ lib, labels, name, persistence }:

{
  metadata = {
    inherit labels;
  };
  spec = {
    accessModes = persistence.${name}.config.accessMode;
    resources.requests.storage = persistence.${name}.config.size;
  }
  // lib.optionalAttrs (persistence.${name}.config.storageClass != null) {
      storageClassName = persistence.${name}.config.storageClass;
  }
  // lib.optionalAttrs (persistence.${name}.config.nfs.enable) {
      storageClassName = "nfs-static";
  };
}
