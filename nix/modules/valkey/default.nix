{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.valkey;
  namespace = "valkey";
in
{
  options = {
    vegapunk.valkey.enable = lib.mkEnableOption "Enable Valkey Operator";
  };
  
  config = lib.mkIf cfg.enable {
    applications.valkey = {
      inherit namespace;
      createNamespace = true;

      helm.releases.valkey-operator = {
        chart = charts.valkey-operator;
      };
    };
  };
}
