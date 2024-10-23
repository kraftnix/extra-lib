{ lib, ... }:
with lib;
rec {
  # NOTE: Inefficient :/
  # truncates string by num characters
  truncateN = string: num: concatStrings (
    take ((stringLength string) - num) (stringToCharacters string)
  );
  # truncate string to num characters
  truncateTo = string: num: concatStrings (
    take num (stringToCharacters string)
  );

  # split string by /
  _splitPath = path: splitString "/" path;
  # drop last element from list
  _dropLast = l: sublist 0 ((builtins.length l) - 1) l;
  # get directory of file
  getParentDir = path: builtins.concatStringsSep "/" (_dropLast (_splitPath path));
  stringOrNull = val: (val == null) || (typeOf val == "string");
}
