{ lib, ... }:
let
  inherit (builtins)
    concatStringsSep
    hasAttr
    typeOf
    ;
  inherit (lib)
    mkIf
    recursiveUpdate
    ;
in
{

  mkVlanNetdev = name: { vlan, priority ? 25, newmac ? "", ... }: {
    "${toString priority}-${name}" = {
      netdevConfig = {
        Name = name;
        Kind = "vlan";
      } // lib.optionalAttrs (newmac != "") {
        MACAddress = newmac;
      };
      vlanConfig.Id = vlan;
    };
  };
  mkVlanNetwork = name: { priority ? 30, metric ? 1050, extra ? {}, ... }: {
    "${toString priority}-${name}" = lib.recursiveUpdate {
      matchConfig.Name = name;
      networkConfig.DHCP = "ipv4";
      dhcpV4Config.RouteMetric = metric;
    } extra;
  };

}
