{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.mariadb;
  namespace = "mariadb";
  project = "system";
in
{
  options = {
    vegapunk.mariadb.enable = lib.mkEnableOption "Enable MariaDB Operator";
  };

  config = lib.mkIf cfg.enable {
    applications.mariadb = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.mariadb-operator-crds = {
        chart = charts.mariadb-operator-crds;
      };

      helm.releases.mariadb-operator = {
        chart = charts.mariadb-operator;
        values = {
          metrics.enabled = true;
          webhook.cert.certManager.enabled = true;
        };
      };
    };
  };
}
