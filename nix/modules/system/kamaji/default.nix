{ config, generators, lib, pkgs, ... }:

let
  cfg = config.vegapunk.kamaji;
  namespace = "kamaji-system";
  project = "system";

  commit = "81df5c6747672499c90af9f630237e4f8c11bb52";

  # Since this chart does not pin releases, we will download the archive
  chart = pkgs.fetchzip {
    url = "https://github.com/clastix/charts/raw/${commit}/kamaji-0.0.0+latest.tgz";
    hash = "sha256-RI0vKRQjFb6X1qmyfLYvpDBdBZxwZZXanvIgAv1CRdw=";
  };
in
{
  options = {
    vegapunk.kamaji.enable = lib.mkEnableOption "Enable Kamaji";
  };

  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        inherit chart;
        name = "kamaji";
        kindFilter = [ "TenantControlPlane" ];
      })
    ];

    applications.kamaji = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.kamaji = {
        inherit chart;
      };
    };
  };
}
