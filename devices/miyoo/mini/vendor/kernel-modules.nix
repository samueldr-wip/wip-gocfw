{ config, pkgs, ... }:

let
  writeScriptDir = name: text: pkgs.writeTextFile {
    inherit name text;
    executable = true;
    destination = "${name}";
  };
in
{
  games-os.stub.filesystem.contents = {
    "/lib/modules" = pkgs.runCommandNoCC "miyoo-mini-kernel-modules" {} ''
      mkdir -p $out/lib/modules/4.9.84
      cp -vr ${config.device.config.miyoo-mini.vendorBlobs}/modules/4.9.84/* $out/lib/modules/4.9.84/
      cp -vr ${pkgs.miyooMiniAdditionalKernelModules}/lib/modules/4.9.84/extra/* $out/lib/modules/4.9.84/
    '';
    # Files under `/config` are required at that location by the vendor kernel.
    "/config" = pkgs.runCommandNoCC "miyoo-mini-vendor-config" {} ''
      mkdir -p $out/
      cp -vr ${config.device.config.miyoo-mini.vendorBlobs}/config $out/config
    '';

    # This script is mostly verbatim from the vendor image.
    "/etc/init.d/10-vendor-modules" = writeScriptDir "/etc/init.d/10-vendor-modules" ''
      #!/bin/sh
      
      #
      # Assumed generic kernel modules
      #

      # Filesystems
      insmod /lib/modules/4.9.84/nls_utf8.ko
      insmod /lib/modules/4.9.84/fat.ko
      insmod /lib/modules/4.9.84/msdos.ko
      insmod /lib/modules/4.9.84/vfat.ko
      # Not supported, not recommended
      # insmod /lib/modules/4.9.84/ntfs.ko

      # Subsystems
      insmod /lib/modules/4.9.84/mmc_core.ko
      insmod /lib/modules/4.9.84/mmc_block.ko
      insmod /lib/modules/4.9.84/sd_mod.ko
      # Not used, does not provide USB functionality
      # insmod /lib/modules/4.9.84/ehci-hcd.ko

      #
      # Vendor modules
      #

      insmod /lib/modules/4.9.84/kdrv_sdmmc.ko
      insmod /lib/modules/4.9.84/mdrv_crypto.ko
      insmod /lib/modules/4.9.84/mhal.ko
      insmod /lib/modules/4.9.84/mi_common.ko

      major=`cat /proc/devices | busybox awk "\\$2==\""mi"\" {print \\$1}"\n`
      minor=0

      if insmod /lib/modules/4.9.84/mi_sys.ko cmdQBufSize=128 logBufSize=0; then
          busybox mknod /dev/mi_sys c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_gfx.ko; then
          busybox mknod /dev/mi_gfx c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_divp.ko; then
          busybox mknod /dev/mi_divp c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_vdec.ko; then
          busybox mknod /dev/mi_vdec c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_ao.ko; then
          busybox mknod /dev/mi_ao c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_disp.ko; then
          busybox mknod /dev/mi_disp c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_ipu.ko; then
          busybox mknod /dev/mi_ipu c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_ai.ko; then
          busybox mknod /dev/mi_ai c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_venc.ko; then
          busybox mknod /dev/mi_venc c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_panel.ko; then
          busybox mknod /dev/mi_panel c $major $minor
          let minor++
      fi

      if insmod /lib/modules/4.9.84/mi_alsa.ko; then
          busybox mknod /dev/mi_alsa c $major $minor
          let minor++
      fi

      major=`cat /proc/devices | busybox awk "\\$2==\""mi_poll"\" {print \\$1}"`
      busybox mknod /dev/mi_poll c $major 0

      # Added last, as it relies on previous modules
      insmod /lib/modules/4.9.84/fbdev.ko

      # Refresh /dev
      mdev -s
    '';

    # Additional modules
    "/etc/init.d/11-kernel-modules" = writeScriptDir "/etc/init.d/11-kernel-modules" ''
      #!/bin/sh

      insmod /lib/modules/4.9.84/loop.ko
    '';
  };
}
