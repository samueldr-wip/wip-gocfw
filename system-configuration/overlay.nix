{ config, lib, ... }:

let
  inherit (lib)
    mkIf
  ;
  inherit (config.nixpkgs.crossSystem)
    is32bit
  ;
  isCross = config.nixpkgs.crossSystem != null;
in
{
  nixpkgs.overlays = [
    (self: super: {
      games-os = {
        hello = self.callPackage ../pkgs/hello { };
      };
      SDL_ttf = super.SDL_ttf.overrideAttrs({ patches ? [], ... }: {
        patches = patches ++ [
          ../pkgs/SDL_ttf/0001-Backport-Fixed-bug-3762-Can-t-render-characters-with.patch
        ];
      });
      SDL = super.SDL.override {
        pulseaudioSupport = false;
        libGLSupported = false;
        openglSupport = false;
        x11Support = false;
      };
      luajit = super.luajit.overrideAttrs(
        { postPatch
        , ... }:
        {
          # Target devices will often have absolutely no
          # entropy, and absolutely no need for secure random.
          # This will make lj_prng_seed_secure fall back to
          # /dev/urandom, which is fine here.
          postPatch = postPatch + ''
            substituteInPlace src/lj_prng.c \
              --replace SYS_getrandom NO_GETRANDOM_THANK_YOU
          '';
        }
      );
    })
    (mkIf (isCross && is32bit)
      (self: super: {
        luajit = super.luajit.overrideAttrs(
          { makeFlags, ... }:
          {
            makeFlags = makeFlags ++ [
              # XXX this is the wrong solution
              # This will only work when cross-compiling from x86_64.
              # ¯\_(ツ)_/¯
              # I can't get a "non-cross" gcc_multi from the "crossed" Nixpkgs...
              # And even then, non pkgsi686Linux multi doesn't even work with -m32 ???
              "HOST_CC=${(import self.pkgs.path {}).pkgsi686Linux.gcc}/bin/gcc"
            ];
          }
        );
      })
    )
  ];
}
