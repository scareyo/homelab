{
  flake.modules.templates.privileged = { lib, ... }: {
    templates.privileged = {
      output = { name, ... }: {
        namespaces."${name}" = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
