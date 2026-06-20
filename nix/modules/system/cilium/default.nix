{ charts, config, generators, lib, pkgs, ... }:

let
  cfg = config.vegapunk.cilium;
  namespace = "kube-system";
  project = "system";
  chart = charts.cilium;
in
{
  options = {
    vegapunk.cilium.enable = lib.mkEnableOption "Enable Cilium";
  };
  
  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromCRDModule {
        name = "cilium";
        src = pkgs.fetchFromGitHub {
          owner = "cilium";
          repo = "cilium";
          rev = "v1.19.3";
          hash = "sha256-KnKGzAEe5K3SA16sNUzFC+bLNOKiKLw1Nwuli1kWTnc=";
        };
        crdFiles = [
          "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpadvertisements.yaml"
          "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpclusterconfigs.yaml"
          "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgppeerconfigs.yaml"
          "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumloadbalancerippools.yaml"
        ];
      })
    ];

    applications.cilium = {
      inherit namespace project;

      helm.releases.cilium = {
        inherit chart;
        values = import ./values.nix;
      };

      templates.app.hubble.route = {
        serviceName = "hubble-ui";
      };

      resources = import ./resources.nix;
    };
  };
}
