{ config, generators, lib, pkgs, ... }:

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
    nixidy.applicationImports = [
      (generators.fromCRDModule {
        name = "olm";
        src = pkgs.fetchFromGitHub {
          owner = "operator-framework";
          repo = "operator-lifecycle-manager";
          rev = "v0.45.0";
          hash = "sha256-xPRyxOe3VDf6GjDy1iQ1hQFoKWHAW6qcrOGxY0XemP8=";
        };
        crdFiles = [
          "deploy/chart/crds/0000_50_olm_00-subscriptions.crd.yaml"
        ];
      })
    ];

    applications.operators = {
      inherit namespace project;

      resources.subscriptions = {
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
