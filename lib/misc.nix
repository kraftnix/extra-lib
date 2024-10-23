{ lib, ... }:
let
  inherit (builtins)
    concatStringsSep
    hasAttr
    typeOf
    ;
in
rec {
  prependPath = pre: main:
    if (pre != null) || (pre != "") then
      "${pre}/${main}"
    else
      main;

  toLua' = val: (
    if typeOf val == "bool" then (if val then "true" else "false")
    else if typeOf val == "int" then (builtins.toString val)
    else if typeOf val == "float" then (builtins.toString val)
    else if typeOf val == "string" then "\"${val}\""
    else if typeOf val == "list" then
      ''{ ${concatStringsSep ",\n" (map (v: (toLua' v)) val)} }''
    else if typeOf val == "set" then
      (
        if hasAttr "_code" val then val.str
        else
          ''{ ${concatStringsSep ",\n" (lib.mapAttrsToList (n: v: "${n} = ${toLua' v}") val)} }''
      )
    else throw "unsupported type ${typeOf val}:\n${val} "
  );

  toLua = settings:
    lib.concatStringsSep ",\n" (lib.mapAttrsToList
      (name: value:
        "${name} = ${toLua' value}"
      )
      settings
    );

  writeNu = { nushell, configFile ? null, configCmds ? "", extra ? "", pkgs, ... }:
    let
      base = "${nushell}/bin/nu";
      interpreter =
        if configFile != null then
          "${base} --config ${configFile} ${extra}"
        else if configCmds != "" then
          "${base} -c ${builtins.concatStringSep "; " configCmds} ${extra}"
        else
          "${base} ${extra}"
      ;
    in
    pkgs.writers.makeScriptWriter {
      inherit interpreter;
    };

}
