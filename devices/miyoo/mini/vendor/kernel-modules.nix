{ config, pkgs, ... }:

{
  examples.hello-wip-games-os.rootfs.contents = {
    "/lib/modules" = pkgs.runCommandNoCC "miyoo-mini-kernel-modules" {} ''
      mkdir -p $out/lib/modules
      cp -vr ${config.device.config.miyoo-mini.vendorBlobs}/modules/* $out/lib/modules/
    '';
    "/config" = pkgs.runCommandNoCC "miyoo-mini-vendor-config" {} ''
      mkdir -p $out/
      cp -vr ${config.device.config.miyoo-mini.vendorBlobs}/config $out/config
    '';
  };
  examples.hello-wip-games-os.extraUtils.packages = [
    # This script is mostly verbatim from the vendor image.
    (pkgs.writeScriptBin "vendor-kernel-modules" ''
      #!/bin/sh
      insmod /lib/modules/4.9.84/nls_utf8.ko
      insmod /lib/modules/4.9.84/mmc_core.ko
      insmod /lib/modules/4.9.84/mmc_block.ko
      insmod /lib/modules/4.9.84/kdrv_sdmmc.ko
      insmod /lib/modules/4.9.84/fat.ko
      insmod /lib/modules/4.9.84/msdos.ko
      insmod /lib/modules/4.9.84/vfat.ko
      insmod /lib/modules/4.9.84/ntfs.ko
      insmod /lib/modules/4.9.84/ehci-hcd.ko
      insmod /lib/modules/4.9.84/sd_mod.ko
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
      insmod /lib/modules/4.9.84/fbdev.ko

      # Refresh /dev
      mdev -s
    '')
  ];
}
