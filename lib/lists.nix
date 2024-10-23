{ lib, ... }:
with lib;
{
  # Filters a list of attributes for duplicate paths
  # Returns attrSet of dup path values containing full duplicate attrSet
  getDuplicates = list: path:
    filterAttrs
      (n: v: (length v) > 1)
      (groupBy (el: el.${path}) list);

  # Filters a list of attributes for duplicate paths
  # Returns attrSet of dup path values containing full duplicate attrSet
  getDuplicates' = list: path:
    filterAttrs
      (n: v: (length v) > 1)
      (groupBy (attrByPath path "") list);

  allUniques = list: (length list) == (length (unique list));

  # flatMaps a list of attrSet, selecting a value `val`
  flatMap = val: list: flatten (map (cfg: cfg.${val}) list);
}
