{ generators, pkgs, ... }:

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
    (generators.fromCRDModule {
      name = "olm";
      src = pkgs.fetchFromGitHub {
        owner = "operator-framework";
        repo = "operator-lifecycle-manager";
        rev = "v0.45.0";
        hash = "sha256-xPRyxOe3VDf6GjDy1iQ1hQFoKWHAW6qcrOGxY0XemP8=";
      };
      crdFiles = [
        "deploy/chart/crds/0000_50_olm_00-operatorgroups.crd.yaml"
        "deploy/chart/crds/0000_50_olm_00-subscriptions.crd.yaml"
      ];
    })
  ];
}
