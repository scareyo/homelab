let
  entries = builtins.readDir ./.;

  templates = builtins.filter (name:
    entries.${name} == "regular"
    && name != "default.nix"
    && builtins.match ".*.nix" name != null
  ) (builtins.attrNames entries);

  imports = map (name: ./. + "/${name}") templates;
in
{
  imports = imports;
}
