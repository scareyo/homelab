{ charts, config, generators, lib, ... }:

let
  cfg = config.vegapunk.cert-manager;
  namespace = "cert-manager";
  project = "system";
  chart = charts.cert-manager;
in
{
  options = {
    vegapunk.cert-manager.enable = lib.mkEnableOption "Enable cert-manager";
  };
  
  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        inherit chart;
        name = "cert-manager";
        kindFilter = [ "ClusterIssuer" "Issuer" ];
        extraOpts = [ "--set" "crds.enabled=true"];
      })
    ];

    applications.cert-manager = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.cert-manager = {
        inherit chart;
        values = import ./values.nix;
      };

      templates.externalSecret.cloudflare = {
        keys = [
          { source = "/cloudflare/API_TOKEN"; dest = "token"; }
        ];
      };

      resources = import ./resources.nix;
    };
  };
}
