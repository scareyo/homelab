{ config, generators, lib, pkgs, ... }:

let
  cfg = config.vegapunk.kubevirt;
  namespace = "kubevirt-hyperconverged";
  project = "system";
in
{
  options = {
    vegapunk.kubevirt.enable = lib.mkEnableOption "Enable Kubevirt";
  };

  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromCRDModule {
        name = "kubevirt";
        src = pkgs.fetchFromGitHub {
          owner = "kubevirt";
          repo = "hyperconverged-cluster-operator";
          rev = "v1.17.1";
          hash = "sha256-YY2NduCIF01JZ7dVgw4F6+IdyL5jXEEdlwDVcAvikjM=";
        };
        crdFiles = [
          "deploy/crds/containerized-data-importer00.crd.yaml"
          "deploy/crds/kubevirt00.crd.yaml"
        ];
      })
    ];

    applications.kubevirt = {
      inherit namespace project;

      createNamespace = true;

      resources.subscriptions.kubevirt.spec = {
        channel = "stable";
        name = "community-kubevirt-hyperconverged";
        source = "operatorhubio-catalog";
        sourceNamespace = "olm";
      };

      resources.operatorGroups.kubevirt = {};

      resources.cdis.cdi = {};

      resources.kubeVirts.kubevirt = {};

      resources = {
        namespaces.${namespace} = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
