{ stdenv
, pkgsCross
, lib
, pkgs
, luajit }:

let
  isCross = (stdenv.hostPlatform != stdenv.buildPlatform);
  inherit (stdenv) is32bit;
  # FIXME: fix cross-compilation to 32 bit from AArch64
  stdenv32 = pkgsCross.gnu32.stdenv;
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
        "HOST_CC=${stdenv32.cc}/bin/${stdenv32.cc.targetPrefix}gcc"
      ]
    ;
  }
)
