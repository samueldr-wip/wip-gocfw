{ config, lib, pkgs, ... }:

let
  mainline = {
    provenance = "mainline";
    u-boot = pkgs.callPackage ./mainline/u-boot { };
    kernel = pkgs.callPackage ./mainline/kernel { };
  };
  selected = mainline;
in
{
  device = {
    name = "powkiddy/v90";
    dtbFiles = [
      "suniv-f1c100s-powkiddy-v90.dtb"
    ];
    config.allwinner = {
      embedFirmware = true;
      firmwarePartition = selected.u-boot + "/u-boot-sunxi-with-spl.bin";

      # Unclear whether this is an allwinner-wide bug, or f1c100s only...
      # But FEL-booted systems don't see the environment set by the FEL tool.
      # NOTE: it's assumed that we'll use FEL only with mainline U-Boot...
      #       this is not the expected way to run anything really.
      fel-firmware = (mainline.u-boot.overrideAttrs({preConfigure ? "", ...}: {
        preConfigure = preConfigure + ''
          cat <<EOF >> configs/powkiddy_v90_defconfig
          CONFIG_BOOTCOMMAND="source \''${scriptaddr}"
          EOF
          cat configs/powkiddy_v90_defconfig
        '';
      })) + "/u-boot-sunxi-with-spl.bin";
    };
  };

  hardware = {
    cpu = "allwinner-f1c100s";
  };

  wip.kernel.package = selected.kernel;
  wip.kernel.defconfig = "miyoo_defconfig";

  wip.kernel.structuredConfig =
    with lib.kernel;
    let
      inherit (config.wip.kernel) features;
    in
    lib.mkMerge [
      {
        # Not available here
        SERIAL_AMBA_PL011 = lib.mkForce no;
        SERIAL_AMBA_PL011_CONSOLE = lib.mkForce no;
        MEMFD_CREATE = lib.mkForce (if selected.provenance == "mainline" then yes else no);
        LOCALVERSION = freeform ''""'';

        # ??
        VT_CONSOLE = option no;

        SERIAL_EARLYCON = yes;
        SERIAL_8250 = yes;
        SERIAL_8250_DEPRECATED_OPTIONS = yes;
        SERIAL_8250_CONSOLE = yes;
        SERIAL_8250_NR_UARTS = freeform "8";
        SERIAL_8250_RUNTIME_UARTS = freeform "8";
        SERIAL_8250_FSL = yes;
        SERIAL_8250_DW = yes;
        SERIAL_OF_PLATFORM = yes;
        SERIAL_CORE = yes;
        SERIAL_CORE_CONSOLE = yes;

      }

      /*
      # TODO: mainline USB support is iffy.
      # It will work only if booted from FEL
      # I assume FEL initializes USB, while no other component knows how to.
      {
        USB_ROLE_SWITCH = yes;
      }
      */

      (lib.mkIf (selected.provenance == "mainline") {
        DRM = yes;
        DRM_SUN4I = yes;
        DRM_PANEL_SIMPLE = yes;
      })
    ]
  ;

  # xz fails to uncompress due to lack of memory
  wip.stage-1.compression = lib.mkForce "gzip";

  boot.cmdline = [
    # Ugh... :/
    "loglevel=9"
    "drm.debug=0x7"
  ];
}
