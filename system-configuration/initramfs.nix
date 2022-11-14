{ config, lib, pkgs, ... }:

/*

For now the initramfs for the hello-wip-games-os example system is entirely bespoke.

At some point a *busybox init stage-1* module will be added, and this will be
changed to use that module.

*/

let
  inherit (lib)
    mkOption
    types
  ;

  inherit (pkgs)
    runCommandNoCC
    writeScript
    writeScriptBin
    writeText
    writeTextFile
    writeTextDir

    mkExtraUtils

    busybox
    glibc
  ;

  writeScriptDir = name: text: writeTextFile {inherit name text; executable = true; destination = "${name}";};

  cfg = config.examples.hello-wip-games-os;

  # Alias to `output.extraUtils` for internal usage.
  inherit (cfg.output) extraUtils;
in
{
  options.examples.hello-wip-games-os = {
    extraUtils = {
      packages = mkOption {
        # TODO: submodule instead of `attrs` when we extract this
        type = with types; listOf (oneOf [package attrs]);
      };
    };
    output = {
      extraUtils = mkOption {
        type = types.package;
        internal = true;
      };
    };
  };

  config = {
    # FIXME: build minimal initramfs that mounts the actual rootfs squashfs archive on the SD card FAT32 (for e.g. v90)
    # XXX: the initramfs module is currently temporarily tied-up into building the rootfs.
  };
}
