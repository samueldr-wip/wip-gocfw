{ config, lib, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      games-os = {
        hello = self.callPackage ../pkgs/hello { };
        mkDotApp = self.callPackage ../pkgs/mkDotApp { };
        ubiboot = self.callPackage ../pkgs/ubiboot { };
      };
      SDL = self.callPackage ../pkgs/SDL { inherit (super) SDL; };
      SDL_ttf = self.callPackage ../pkgs/SDL_ttf { };
      luajit = self.callPackage ../pkgs/luajit { inherit (super) luajit; };
    })
  ];
}
