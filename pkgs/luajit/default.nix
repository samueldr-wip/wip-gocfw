{ stdenv
, lib
, pkgs
, luajit }:

let
  isCross = (stdenv.hostPlatform != stdenv.buildPlatform);
  inherit (stdenv) is32bit;
in
luajit.overrideAttrs(
  { postPatch
  , makeFlags
  , ... }: {
    # Target devices will often have absolutely no
    # entropy, and absolutely no need for secure random.
    # This will make lj_prng_seed_secure fall back to
    # /dev/urandom, which is fine here.
    postPatch = postPatch + ''
      substituteInPlace src/lj_prng.c \
        --replace SYS_getrandom NO_GETRANDOM_THANK_YOU
    '';
    makeFlags =
      makeFlags
      ++ lib.optionals (isCross && is32bit) [
        # XXX this is the wrong solution
        # This will only work when cross-compiling from x86_64.
        # ¯\_(ツ)_/¯
        # I can't get a "non-cross" gcc_multi from the "crossed" Nixpkgs...
        # And even then, non pkgsi686Linux multi doesn't even work with -m32 ???
        "HOST_CC=${(import pkgs.path {}).pkgsi686Linux.gcc}/bin/gcc"
      ]
    ;
  }
)
