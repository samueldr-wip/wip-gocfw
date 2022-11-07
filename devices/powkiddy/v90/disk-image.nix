{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    optionalString
    mapAttrsToList
    mkOption
    types
  ;
  inherit (pkgs)
    stdenv
  ;
  inherit (stdenv) hostPlatform isAarch64;
  kernel = config.wip.kernel.output;
  inherit (kernel) target;
  inherit (config.wip.stage-1.output) initramfs;
  inherit (config.device) dtbFiles nameForDerivation;
  cfg = config.device.config.allwinner;

  bootscr = config.wip.u-boot.lib.mkScript "boot.scr" ''
    echo "Booting gofcw stub..."
    setenv bootargs ${concatStringsSep " " config.boot.cmdline}

    if test "$mmc_bootdev" != ""; then
      devtype="mmc"
    else
      exit
    fi

    if test "$devtype" = "mmc"; then
      devnum="$mmc_bootdev"
    fi

    bootpart="2"

    if load ''${devtype} ''${devnum}:''${bootpart} ''${kernel_addr_r} /.boot/kernel.img; then
      setenv boot_type boot
    else
      echo "!!! Failed to load kernel !!!"
      exit
    fi

    if load ''${devtype} ''${devnum}:''${bootpart} ''${fdt_addr_r} /.boot/dtbs/''${fdtfile}; then
      fdt addr ''${fdt_addr_r}
      fdt resize
    fi

    load ''${devtype} ''${devnum}:''${bootpart} ''${ramdisk_addr_r} /.boot/initramfs.img
    setenv ramdisk_size ''${filesize}

    bootz ''${kernel_addr_r} ''${ramdisk_addr_r}:''${ramdisk_size} ''${fdt_addr_r};
  '';

  rootfs = config.build.TEMProotfs;
in
{
  build.disk-image = (pkgs.celun.image-builder.evaluateDiskImage {
    config =
      { config, ... }:

      let inherit (config) helpers; in
      {
        name = "${nameForDerivation}-disk-image";
        partitioningScheme = "gpt";
        gpt.partitionEntriesCount = 48;

        partitions = [
          (lib.mkIf cfg.embedFirmware {
            name = "firmware";
            partitionLabel = "$FIRMWARE";
            partitionType = "67401509-72E7-4628-B1AF-EDD128E4316A";
            offset = 16 * 512 /* sectors */; # 8KiB from the start of the disk
            length = helpers.size.MiB 4;
            raw = cfg.firmwarePartition;
          })

          {
            name = "userdata";
            partitionLabel = "userdata";
            partitionType = "8DA63339-0007-60C0-C436-083AC8230908";
            bootable = true;
            filesystem = {
              filesystem = "ext4";
              label = "userdata";
              extraPadding = helpers.size.MiB 32;
              populateCommands = ''
                cp ${bootscr} boot.scr

                mkdir -p .boot
                cp ${initramfs} .boot/initramfs.img
                cp ${kernel}/${target} .boot/kernel.img

                # There might not be any DTBs to install; on ARM the DTB files
                # are built only if the proper ARCH_VENDOR config is set.
                if [ -e ${kernel}/dtbs ]; then
                  (
                  shopt -s globstar
                  mkdir .boot/dtbs/
                  cp -fvr ${kernel}/dtbs/**/*.dtb .boot/dtbs
                  )
                else
                  echo "Warning: no dtbs built on hostPlatform with DTB"
                fi

                mkdir -p system
                cp ${rootfs} system/rootfs.img
              '';
            };
          }
        ];
      }
    ;
  }).config.output;
}
