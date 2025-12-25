{ lib, name, persistence }:

{
  spec = {
    accessModes = persistence.${name}.accessMode;
    resources.requests.storage = persistence.${name}.size;
  }
  // lib.optionalAttrs (persistence.${name}.storageClass != null) {
      storageClassName = persistence.${name}.storageClass;
  };
}
