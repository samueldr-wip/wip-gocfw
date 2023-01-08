{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
  ;
in
{
  nixpkgs.overlays = mkMerge [
    [
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
    ]

    # MIPS specific workarounds
    (mkIf config.nixpkgs.crossSystem.isMips [
      (self: super: {
        systemd = super.systemd.override({
          # On mips, clang 11, a dep for withLibBPF, doesn't build...
          withLibBPF = false;
        });
      })
    ])
  ];
}
