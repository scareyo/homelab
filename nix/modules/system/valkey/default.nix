{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.valkey;
  namespace = "valkey";
  project = "system";
in
{
  options = {
    vegapunk.valkey.enable = lib.mkEnableOption "Enable Valkey Operator";
  };
  
  config = lib.mkIf cfg.enable {
    applications.valkey = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.valkey-operator = {
        chart = charts.valkey-operator;
      };
    };
  };
}
