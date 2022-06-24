{ config, lib, pkgs, ... }:

let
  #u-boot = pkgs.callPackage ./u-boot { };
in
{
  device = {
    name = "miyoo/mini";
  };

  hardware = {
    cpu = "sigmastar-ssd202d";
  };

  # ???
  wip.stage-1.compression = "none";

  boot.cmdline = [
    # Ugh... :/
    "loglevel=9"
    "drm.debug=0x7"
  ];

  build.bootscript =
    config.wip.u-boot.lib.mkScript "${config.device.nameForDerivation}-boot.scr"
    (
      let
        _initrd_offset = "0x22200000";
        _bootargs = builtins.concatStringsSep " " [
          "loglevel=8"
          "panic=1"

          "console=ttyS0,115200"
          "earlycon"
          #"earlycon=ms_uart,1F221000"
          "earlyprintk=serial,ttyS0,115200"

          #"root=/dev/mtdblock4"
          #"rootfstype=squashfs"
          #"ro"
          #"init=/linuxrcXXX"

          "root=/dev/mmcblk0p1"
          "rootfstype=vfat"
          "rootflags=rw,dirsync,relatime,fmask=0000,dmask=0000,allow_utime=0022,codepage=437,iocharset=utf8,shortname=mixed,tz=UTC,errors=remount-ro"
          "ro"
          "init=/init"

          "mma_heap=mma_heap_name0,miu=0,sz=0x1500000"
          "mma_memblock_remove=1"
          "highres=off"

          "mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x7C00000,max_end_off=0x7F00000"
          "LX_MEM=0x7f00000"

          # "powerkey=1"
        ];
        buzz = "gpio out 48 0; sleepms 100; gpio out 48 1; sleepms 150;";
      in
      # Note the vendor U-Boot fails on any comments left in the script :/
      builtins.concatStringsSep "\n"[
        "dcache on"

        # Load the logo in display memory
        "bootlogo 0 0 0 0 0"

        # Vendor init (needed?)
        "mw 1f001cc0 11"
        "gpio out 85 1"

        buzz

        # SF probe/read
        "mw 1f001cc0 11; gpio out 8 0; sf probe 0"
        # Read the vendor kernel
        ''sf read 0x22000000 ''${sf_kernel_start} ''${sf_kernel_size}''
        "gpio out 8 1"

        # Delay display on for at least 500ms for the display not to glitch out...
        # "sleepms 500"
        buzz
        buzz

        # Display on
        "gpio output 4 1"

        "dcache off"
        "fatinfo mmc 0"
        "fatload mmc 0 ${_initrd_offset} initrd"
        "dcache on"

        buzz
        buzz
        buzz
        buzz

        "env set bootargs ${_bootargs}"

        "bootm 0x22000000"

        buzz
        buzz
        buzz
        buzz
        buzz
        buzz
        buzz
        buzz

        "reset"

        #"bootm 0x22000000 ${_initrd_offset}"
      ]
    )
  ;
  build.testinit = pkgs.pkgsStatic.writeCBin "test" ''
    #include <stdlib.h>
    #include <unistd.h>

      int main() {
        sleep(10);
        exit(12);
      }
  '';

  build.hack = pkgs.runCommandNoCC "miyoomini" {} ''
    mkdir -vp $out
      cp -v ${config.build.bootscript} $out/boot.scr
      #cp -v ${config.build.initramfs}  $out/initrd
      cp -v ${config.build.testinit}/bin/*  $out/init
  '';

}
