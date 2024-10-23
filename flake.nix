{
  description = "a small collection of nix library functions";
  inputs.nixlib.url = "github:nix-community/nixpkgs.lib";
  outputs = { nixlib, ... }:
    let
      lib = nixlib.lib;
      internal = import ./lib { inherit lib; };
      finalLib = internal // {
        _nixlib = lib;
      };
    in
    {
      lib = finalLib;
      overlays.default = final: prev: {
        lib = prev.lib // {
          _extra = finalLib;
        };
      };
    };
}
