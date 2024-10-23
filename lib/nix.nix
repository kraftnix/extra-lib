top@{ lib, ... }:
rec {
  inherit (import ./std-compat.nix top) rakeLeaves;

  kebabCaseToCamelCase =
    builtins.replaceStrings (map (s: "-${s}") lib.lowerChars) lib.upperChars;

  # from https://sourcegraph.com/github.com/terlar/nix-config/-/blob/flake-parts/lib/default.nix
  importDirToAttrsList = dir:
    lib.pipe dir [
      lib.filesystem.listFilesRecursive
      (builtins.filter (lib.hasSuffix ".nix"))
      (map (path: {
        name = lib.pipe path [
          toString
          (lib.removePrefix "${toString dir}/")
          (lib.removeSuffix "/default.nix")
          (lib.removeSuffix ".nix")
          kebabCaseToCamelCase
          (builtins.replaceStrings ["/"] ["-"])
        ];
        value = import path;
      }))
      builtins.listToAttrs
    ];

  filteredDirList = dir:
    lib.pipe dir [
      lib.filesystem.listFilesRecursive
      (builtins.filter (lib.hasSuffix ".nix"))
      (map (path: {
        inherit path;
        name = lib.pipe path [
          toString
          (lib.removePrefix "${toString dir}/")
          (lib.removeSuffix "/default.nix")
          (lib.removeSuffix ".nix")
          kebabCaseToCamelCase
          (builtins.replaceStrings ["/"] ["-"])
        ];
      }))
    ];

  nameToAttrs = { name, path }:
    lib.setAttrByPath (lib.splitString [ "-" ] name) path;

  importDirToAttrs' = files:
    lib.pipe files [
      (map nameToAttrs)
      (lib.foldAttrs (item: acc: lib.recursiveUpdate acc item) {})
    ];

  # returns an attrSet of all paths imported
  # directory structure is maintained as attrSets
  # Path -> { Path = import Path; }
  # e.g. importDirToAttrs ./lib
  #   ->  { network = { core = import ./lib/network/core.nix; }; basic = import ./lib/basic.nix; }
  importDirToAttrs = dir:
    lib.pipe dir [
      filteredDirList
      importDirToAttrs'
    ];

}
