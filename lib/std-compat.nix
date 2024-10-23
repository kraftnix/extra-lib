# many functions from an old https://github.com/divnix/std commit
{ lib, ... }:
with builtins;
with lib;
rec {
  # `stdArgs`: { inputs, cell }
  handleLeaf = _: lib.trivial.id;
  # handles attrSet or cell function
  handlePathCellOrSet = stdArgs: path:
    let imported = import path; in
    if typeOf imported == "set" then
      path
    else if typeOf imported == "lambda" then
      imported stdArgs
    else
      throw "Unsupported path type provided ${typeOf imported}";
  # handles attrSet, cell function, or config module
  handlePathGeneric = stdArgs: path:
    let imported = import path; in
    if typeOf imported == "set" then
      path
    else if typeOf imported == "lambda" then
      (cfg:
        import path (cfg // stdArgs // {
          pkgs = stdArgs.inputs.nixpkgs;
        })
      )
    else
      throw "Unsupported path type provided ${typeOf imported}";
  rakeCells' = dirPath: startPath: pathHandler: stdArgs:
    let
      seive = file: type:
        # skip first default.nix
        ("${dirPath}/${file}" != "${startPath}/default.nix")
        &&
        # Only rake `.nix` files or directories
        (type == "regular" && lib.hasSuffix ".nix" file) || (type == "directory")
      ;

      collect = file: type: {
        name = lib.removeSuffix ".nix" file;
        value =
          let
            path = dirPath + "/${file}";
          in
          if (type == "regular")
            || (type == "directory" && builtins.pathExists (path + "/default.nix"))
          then pathHandler stdArgs path
          # recurse on directories that don't contain a `default.nix`
          else rakeCells' path startPath pathHandler stdArgs;
      };

      files = lib.filterAttrs seive (builtins.readDir dirPath);
    in
    lib.filterAttrs (n: v: v != { }) (lib.mapAttrs' collect files);
  newRakeLeaves = path: rakeCells' path path handleLeaf {};
  rakeCells = path: rakeCells' path path handlePathGeneric;
  rakeCellsPure = path: rakeCells' path path handlePathCellOrSet;

  # Old Digga Compat
  rakeLeaves = dirPath: let
    # Only rake `.nix` files or directories
    seive = file: type: (type == "regular" && lib.hasSuffix ".nix" file) || (type == "directory");
    collect = file: type: {
      name = lib.removeSuffix ".nix" file;
      value =
        let path = dirPath + "/${file}"; in
        if (type == "regular")
          || (type == "directory" && builtins.pathExists (path + "/default.nix"))
        then path
        # recurse on directories that don't contain a `default.nix`
        else rakeLeaves path;
    };
    files = lib.filterAttrs seive (builtins.readDir dirPath);
  in
    lib.filterAttrs (n: v: v != { }) (lib.mapAttrs' collect files);

  # From digga / deployc
  getFqdn = c:
    let
      net = c.config.networking;
      fqdn =
        if (net ? domain) && (net.domain != null)
        then "${net.hostName}.${net.domain}"
        else net.hostName;
    in
    fqdn;
  mkDeployNodes = deploy: systemConfigurations: extraConfig:
    lib.recursiveUpdate
      (lib.mapAttrs (_: c: {
        hostname = getFqdn c;
        profiles.system = {
          user = "root";
          path = deploy.lib.${c.config.nixpkgs.system}.activate.nixos c;
        };
      }) systemConfigurations)
      extraConfig;

  # NOTE: transform `cellBlock -> cellType -> target` -> `cellBlock -> target`
  # NOTE(usage): profiles = "profiles" self.x86_64-linux;
  stdExtractType = cellType: desystemzedOutputs:
    mapAttrs (name: p: p.${cellType})
      (filterAttrs (name: val: hasAttr cellType val) desystemzedOutputs);
  # NOTE: same as `stdExtractType`, but for package sets and outputs overlay compatible object
  pkgsToOverlays = cellType: desystemzedOutputs:
    mapAttrs (_: x: (_: _: x)) (stdExtractType cellType desystemzedOutputs);
  genOverlays = cellType: desystemzedOutputs:
    let
      packages = stdExtractType cellType desystemzedOutputs;
    in
    (mapAttrs (_: x: (_: _: x)) packages) // {
      default = _: _: attrs.recursiveMerge (attrValues packages);
    };
}
