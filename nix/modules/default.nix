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
}
