{ config, generators, lib, pkgs, ... }:

let
  cfg = config.vegapunk.gateway;
  namespace = "gateway";
  project = "system";
in
{
  options = {
    vegapunk.gateway.enable = lib.mkEnableOption "Enable Gateway";
  };
  
  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromCRDModule {
        name = "gateway-api";
        src = pkgs.fetchFromGitHub {
          owner = "kubernetes-sigs";
          repo = "gateway-api";
          rev = "v1.5.0";
          hash = "sha256-Zl0U1mIcVMq1bcfINLMFRU3XlWCOalHzsl5hELWbkcY=";
        };
        crdFiles = [
          "config/crd/standard/gateway.networking.k8s.io_gateways.yaml"
          "config/crd/standard/gateway.networking.k8s.io_httproutes.yaml"
          "config/crd/experimental/gateway.networking.k8s.io_tcproutes.yaml"
        ];
      })
    ];

    applications.gateway = {
      inherit namespace project;

      createNamespace = true;

      resources = import ./resources.nix;
    };
  };
}
