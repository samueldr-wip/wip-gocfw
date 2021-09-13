{ config, lib, pkgs, ... }:

let
  u-boot = pkgs.callPackage ./u-boot { };
in
{
  device = {
    name = "powkiddy/v90";
    dtbFiles = [
      "suniv-f1c100s-powkiddy-v90.dtb"
    ];
    config.allwinner = {
      embedFirmware = true;
      firmwarePartition = u-boot + "/u-boot-sunxi-with-spl.bin";

      # Unclear whether this is an allwinner-wide bug, or f1c100s only...
      # But FEL-booted systems don't see the environment set by the FEL tool.
      fel-firmware = (u-boot.overrideAttrs({preConfigure ? "", ...}: {
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

  wip.kernel.package = pkgs.callPackage ./kernel {};
  wip.kernel.defconfig = "miyoo_defconfig";

  wip.kernel.structuredConfig =
    with lib.kernel;
    let
      inherit (config.wip.kernel) features;
    in
    lib.mkMerge [
      {
        # Not available here
        SERIAL_AMBA_PL011 = no;
        SERIAL_AMBA_PL011_CONSOLE = no;

        MEMFD_CREATE = yes;

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
    ]
  ;

  # xz fails to uncompress due to lack of memory
  wip.stage-1.compression = "gzip";

  boot.cmdline = [
    # Ugh... :/
    "loglevel=0"
  ];
}
