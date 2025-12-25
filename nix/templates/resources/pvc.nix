{ lib, labels, name, persistence }:

{
  metadata = {
    inherit labels;
  };
  spec = {
    accessModes = persistence.${name}.accessMode;
    resources.requests.storage = persistence.${name}.size;
  }
  // lib.optionalAttrs (persistence.${name}.storageClass != null) {
      storageClassName = persistence.${name}.storageClass;
  };
}
