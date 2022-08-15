{ config, pkgs, lib, ... }:

let
  inherit (config.device) dtbFiles nameForDerivation;
  kernel = config.wip.kernel.output;
  inherit (kernel) target;
  inherit (config.wip.stage-1.output) initramfs;
  rootfs = config.build.TEMProotfs;

  # GPIO a15 is the vibrator motor.
  bootini = pkgs.writeText "${nameForDerivation}-boot.ini" ''
    ODROIDGO2-UBOOT-CONFIG

    setenv dtb_name       "rk3326-rg351p-linux.dtb"
    setenv ramdisk_addr_r "0x01100000"
    setenv fdt_addr_r     "0x01f00000"
    setenv kernel_addr_r  "0x02008000"

    setenv dtb_name "rk3326-rg351p-linux.dtb"

    setenv bootargs "${lib.concatStringsSep " " config.boot.cmdline}"

    gpio toggle a15
    load mmc 1:1 ''${kernel_addr_r}   /.boot/kernel.img
    load mmc 1:1 ''${fdt_addr_r}      /.boot/dtbs/''${dtb_name}
    load mmc 1:1 ''${ramdisk_addr_r}  /.boot/initramfs.img
    setenv ramdisk_size ''${filesize}
    gpio toggle a15

    booti ''${kernel_addr_r} ''${ramdisk_addr_r}:''${ramdisk_size} ''${fdt_addr_r};

    sleep 0.5
    gpio toggle a15
    sleep 0.5
    gpio toggle a15
    sleep 0.5
    gpio toggle a15
    sleep 0.5
    gpio toggle a15
    sleep 0.5
  '';
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
         {
           name = "userdata";
           partitionLabel = "userdata";
           partitionType = "8DA63339-0007-60C0-C436-083AC8230908";
           bootable = true;
           filesystem = {
             filesystem = "fat32";
             label = "userdata";
             extraPadding = helpers.size.MiB 32;
             populateCommands = ''
               cp ${bootini} boot.ini

               mkdir -p .boot
               cp ${initramfs}        .boot/initramfs.img
               cp ${kernel}/${target} .boot/kernel.img

               # There might not be any DTBs to install; on ARM the DTB files
               # are built only if the proper ARCH_VENDOR config is set.
               if [ -e ${kernel}/dtbs ]; then
                 (
                 shopt -s globstar
                 mkdir .boot/dtbs/
                 cp -fvr ${kernel}/dtbs/**/rk3326*rg351*.dtb .boot/dtbs
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
