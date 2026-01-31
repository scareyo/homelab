let
  projects = builtins.readDir ./.;

  imports =
    builtins.concatLists (
      map (project:
        let
          projectDir = ./. + "/${project}";
        in
          if projects.${project} == "directory" then
            let
              apps = builtins.readDir projectDir;
            in
              map (app: projectDir + "/${app}") (
                builtins.filter (app:
                  apps.${app} == "directory"
                  && builtins.pathExists (projectDir + "/${app}/default.nix")
                ) (builtins.attrNames apps)
              )
          else
            []
      ) (builtins.attrNames projects)
    );
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
