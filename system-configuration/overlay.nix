{ config, lib, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      games-os = {
        hello = self.callPackage ../pkgs/hello { };
        mkDotApp = self.callPackage ../pkgs/mkDotApp { };
      };
      SDL = self.callPackage ../pkgs/SDL { inherit (super) SDL; };
      luajit = self.callPackage ../pkgs/luajit { inherit (super) luajit; };
    })
  ];
}
