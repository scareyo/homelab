{ config, lib, ... }:

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
    applications.gateway = {
      inherit namespace project;

      createNamespace = true;

      resources = import ./resources.nix;
    };
  };
}
