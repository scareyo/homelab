{ config, lib, ... }:

let
  cfg = config.vegapunk.operators;
  namespace = "operators";
  project = "system";
in
{
  options = {
    vegapunk.operators.enable = lib.mkEnableOption "Enable Operators";
    vegapunk.operators.kubevirt.enable = lib.mkEnableOption "Enable KubeVirt Operator";
  };

  config = lib.mkIf cfg.enable {
    applications.operators = {
      inherit namespace project;

      resources."operators.coreos.com".v1alpha1.Subscription = {
        kubevirt = lib.mkIf cfg.kubevirt.enable {
          spec = {
            channel = "stable";
            name = "community-kubevirt-hyperconverged";
            source = "operatorhubio-catalog";
            sourceNamespace = "olm";
          };
        };
      };
    };
  };
}
