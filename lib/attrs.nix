{ lib, ... }:
let
  inherit (lib)
    all
    attrValues
    concatLists
    concatStringsSep
    flatten
    head
    isAttrs
    isList
    last
    listToAttrs
    mapAttrsToList
    nameValuePair
    tail
    unique
    zipAttrsWith
    zipListsWith
    ;
in {
  # remove attrs containg the provided `prefix`
  #   filterAttrsPrefix "__" { __test = 123; hello = 456; }
  #     => { hello = 456; }
  filterAttrsPrefix = prefix: lib.filterAttrs (name: _: !(lib.hasPrefix prefix name));

  # maps attrs to newline separated string
  # where toStr is name: value: function
  # toStr { "hello".bar = "world"; "good".bar = "bye"; } (name: value: "${name}-${config.bar}")
  #   -> "hello-world\ngood-bye"
  mapAttrsToString = attrs: toStr: concatStringsSep "\n" (mapAttrsToList toStr attrs);

  getNames = set: mapAttrsToList (name: _: name) set;

  /* SOURCE: https://stackoverflow.com/questions/54504685/nix-function-to-merge-attributes-records-recursively-and-concatenate-arrays
    Merges list of records, concatenates arrays, if two values can't be merged - the latter is preferred

    Example 1:
    recursiveMerge [
    { a = "x"; c = "m"; list = [1]; }
    { a = "y"; b = "z"; list = [2]; }
    ]

    returns

    { a = "y"; b = "z"; c="m"; list = [1 2] }

    Example 2:
    recursiveMerge [
    {
    a.a = [1];
    a.b = 1;
    a.c = [1 1];
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/hda";
    }
    {
    a.a = [2];
    a.b = 2;
    a.c = [1 2];
    boot.loader.grub.device = "";
    }
    ]

    returns

    { a = { a = [ 1 2 ]; b = 2; c = [ 1 2 ]; }; boot = { loader = { grub = { device = ""; enable = true; }; }; }; }

  */
  recursiveMerge = attrList:
    let
      f = attrPath:
        zipAttrsWith (n: values:
          if tail values == [ ]
          then head values
          else if all isList values
          then unique (concatLists values)
          else if all isAttrs values
          then f (attrPath ++ [ n ]) values
          else last values
        );
    in
    f [ ] attrList;

  /* flattens { a = { b = 1; }; } -> [ { b = 1; } ] */
  flattenNestedAttrs = attrs: flatten (map (x: attrValues x) (attrValues attrs));

  # flattens a nested attr set into a merge of its children
  # WARNING: may do weird stuff
  flattenAttrs = attrs: listToAttrs (flatten (map (mapAttrsToList nameValuePair) (attrValues attrs)));
  flattenAttrsList = list: listToAttrs (flatten (map (mapAttrsToList nameValuePair) (flatten (map attrValues list))));


  /* Generates an attribute set from an apply function and list.

     Example:
       x = [ "a" "bcd" ]
       mapNamesToAttrs stringLength x
       => { a = 1; bcd = 3; }
       mapNamesToAttrs (name: { inherit name; length = stringLength name; }) x
       => { a = { length = 1; name = "a"; }; bcd = { length = 3; name = "bcd"; }; }

     Type:
       mapNamesToAttrs :: (String -> AttrSet) -> [String] -> AttrSet
  */
  mapNamesToAttrs = f: names: listToAttrs (zipListsWith nameValuePair names (map f names));
}
