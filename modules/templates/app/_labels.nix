{ lib, name, config, options }:

lib.mkIf (config.workload != null) {
  "app.kubernetes.io/name" = name;
  "app.kubernetes.io/instance" = name;
  "app.kubernetes.io/version" = lib.head (lib.splitString "@" config.workload.version);
  "app.kubernetes.io/component" = "main";
  "app.kubernetes.io/part-of" = options.namespace.value;
}
