{ config, lib, ... }:

let
  cfg = config.vegapunk.tenant-test;
  namespace = "tenant-test";
  project = "system";
in
{
  options = {
    vegapunk.tenant-test.enable = lib.mkEnableOption "Enable Tenant";
  };
  
  config = lib.mkIf cfg.enable {
    applications.tenant-test = {
      inherit namespace project;

      createNamespace = true;

      resources = import ./resources.nix;
    };
  };
}
