{ lib, ... }@args:
let
  inherit (import ./std-compat.nix { inherit lib; }) rakeLeaves;
  rakedLib = lib.mapAttrs
    (_: v: import v args)
    (lib.filterAttrs (n: _: n != "default") (rakeLeaves ./.));
in
rakedLib // {
  mkDefaults = lib.mapAttrs (_: val: lib.mkDefault val);

  prependPath = pre: main:
    if (pre != null) || (pre != "") then
      "${pre}/${main}"
    else
      main;

  # TODO: this is copied from nixpkgs `nixos/lib/utils.nix`
  escapeSystemdPath = s:
    lib.replaceStrings [ "/" "-" " " ] [ "-" "\\x2d" "\\x20" ]
      (lib.removePrefix "/" s);
}
