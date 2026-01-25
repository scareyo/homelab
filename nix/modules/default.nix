let
  entries = builtins.readDir ./.;

  modules = builtins.filter (name:
    entries.${name} == "directory"
    && builtins.pathExists (./. + "/${name}/default.nix")
  ) (builtins.attrNames entries);

  imports = map (name: ./. + "/${name}") modules;
in
{
  imports = imports ++ [
    ../templates
  ];

  nixidy.chartsDir = ../charts;

  nixidy.applicationImports = [
    ../generated/cert-manager.nix
    ../generated/cilium.nix
    ../generated/cnpg.nix
    ../generated/external-secrets.nix
    ../generated/gateway-api.nix
    ../generated/rook.nix
    ../generated/valkey.nix
    ../generated/velero.nix
    ../generated/victoria-metrics.nix
  ];
}
