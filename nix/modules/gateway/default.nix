{ config, lib, ... }:

let
  cfg = config.vegapunk.gateway;
in
{
  options = {
    vegapunk.gateway.enable = lib.mkEnableOption "Enable Gateway";
  };
  
  config = lib.mkIf cfg.enable {
    applications.gateway = {
      namespace = "gateway";
      createNamespace = true;

      resources = import ./resources.nix;
    };
  };
}
