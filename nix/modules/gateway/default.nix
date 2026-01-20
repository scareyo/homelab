{ config, lib, ... }:

let
  cfg = config.vegapunk.gateway;
  namespace = "gateway";
in
{
  options = {
    vegapunk.gateway.enable = lib.mkEnableOption "Enable Gateway";
  };
  
  config = lib.mkIf cfg.enable {
    applications.gateway = {
      inherit namespace;
      createNamespace = true;

      resources = import ./resources.nix;
    };
  };
}
