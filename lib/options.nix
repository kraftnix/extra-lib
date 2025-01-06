{ lib }:
lib.makeExtensible (self:
let
  inherit (lib)
    mkOption
    mkEnableOption
    recursiveUpdate
    types
    ;
in
{
  # option types
  overlayType = lib.mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    descriptionClass = "noun";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };

  ## nicer names
  mk = lib.mkOption;
  stringList = self.mkStringListOption;
  string = self.optionString;
  stringNull = self.optionStringNullable;
  int = self.optionInt;
  intNull = self.optionIntNullable;
  enable = lib.mkEnableOption;
  enableTrue = self.mkTrueOption;
  enable' = self.mkEnableOption';
  raw = self.mkConfigOption';
  port = self.mkPortOption;
  portList = self.mkPortListOption;
  enum = args@{
    enums ? [],
    ...
  }: mkOption ({
    type = types.enum enums;
  } // (removeAttrs ["enums"] args));

  package = default: description: mkOption {
    inherit description default;
    type = types.package;
  };
  packageList = default: description: mkOption {
    inherit description default;
    type = with types; listOf package;
  };


  # marginally lower priority
  mkDefault' = lib.mkOverride 900;

  optionString = default: description: mkOption {
    inherit description default;
    type = types.str;
  };
  optionStringNullable = description: mkOption {
    inherit description;
    type = with types; nullOr str;
    default = null;
  };

  optionInt = default: description: mkOption {
    inherit description default;
    type = types.int;
  };
  optionIntNullable = description: mkOption {
    inherit description;
    type = with types; nullOr int;
    default = null;
  };

  recursiveMkOption = prev: final: mkOption (recursiveUpdate prev final);

  mkEnableOption' = default: description: mkEnableOption description // {
    inherit default;
  };
  mkTrueOption = description: self.mkEnableOption' true description;

  mkConfigOption' = default: description: mkOption {
    inherit description default;
    type = types.raw;
  };
  mkConfigOption = description: self.mkConfigOption' {} description;

  mkPortOption' = {
    default, # default port
    description ? "Port to listen on",
    ...
  }@extra: self.recursiveMkOption {
    inherit default description;
    type = types.port;
    example = 80;
  } extra;
  mkPortOption = default: description: self.mkPortOption' { inherit default description; };
  mkPortListOption = default: description: self.mkPortOption' { inherit default description; } // {
    type = types.listOf types.port;
  };

  mkStringOption' = {
    default ? null,
    description ? "String Value",
    nullable ? false,
    ...
  }@extra: mkOption ({
    default =
      if default != null then default # passthrough if set
      else if nullable then null      # null if nullable type string
      else "";                        # empty string otherwise
    inherit description;
    type = if nullable
      then types.nullOr types.str
      else types.str;
  } // (removeAttrs extra ["default" "description" "nullable"]));

  mkStringOption = default: description: self.mkStringOption' { inherit default description; };

  mkStringListOption = default: description: mkOption {
    type = with types; listOf str;
    inherit default description;
  };

  mkIntOption = {
    default,
    description ? "Int Value",
    nullable ? false
  }: mkOption {
    inherit default;
    inherit description;
    type = if nullable
      then types.nullOr types.int
      else types.int;
  };

  nestedAttrsType = with types; description: default:
    (attrsOf (oneOf [
      bool
      str
      int
      (listOf str)
      (attrsOf (oneOf [
        bool
        str
        int
        (listOf str)
      ]))
    ]));

  optionNestedAttrs = description: default: mkOption {
    inherit default description;
    type = self.nestedAttrsType description default;
  };

  optionStrsList = name: mkOption {
    type = with types; nullOr (oneOf [ str (listOf str) ]);
    default = null;
    description = "${name} option";
  };

})
