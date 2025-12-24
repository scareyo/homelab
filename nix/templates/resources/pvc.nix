{ config, lib, name }:

{
  spec = {
    accessModes = config.persistence.${name}.accessMode;
    resources.requests.storage = config.persistence.${name}.size;
  }
  // lib.optionalAttrs (config.persistence.${name}.storageClass != null) {
      storageClassName = config.persistence.${name}.storageClass;
  };
}
