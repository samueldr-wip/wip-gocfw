{ config, lib, pkgs, ... }:

{
  imports = [
    ./vendor
  ];

  device = {
    name = "miyoo/mini";
  };

  hardware = {
    cpu = "sigmastar-ssd202d";
  };

  boot.cmdline = [
    "console=ttyS0,115200"

    # cannot be used with the vendor kernel
    # "root=mtd:rootfs"
    "root=/dev/mtdblock4"
    "rootfstype=squashfs"
    "ro"

    # Required here with this device vendor kernel config
    "init=/init"

    # Misc. kernel params from the vendor image.
    "mma_heap=mma_heap_name0,miu=0,sz=0x1500000"
    "mma_memblock_remove=1"
    "highres=off"
    "mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x7C00000,max_end_off=0x7F00000"
    "LX_MEM=0x7f00000"

    # Our overriden SPI flash partition map.
    "mtdparts=NOR_FLASH:${
      # Stock flash map:
      #mtd0: 00060000 00010000 "BOOT"
      #mtd1: 00200000 00010000 "KERNEL"
      #mtd2: 00010000 00010000 "KEY_CUST"
      #mtd3: 00020000 00010000 "LOGO"
      #mtd4: 001c0000 00010000 "rootfs"    
      #mtd5: 00370000 00010000 "miservice" 
      #mtd6: 00770000 00010000 "customer"  
      #mtd7: 000d0000 00010000 "appconfigs"

      # Amended flash map:
      # NOTE: U-Boot environment is read-only with this map.
      # TODO: Investigate making a discrete mtd partition for the environment.
      builtins.concatStringsSep "," [
        "0x00060000(BOOT)ro"
        "0x00200000(KERNEL)ro"
        "0x00010000(KEY_CUST)ro"
        "0x00020000(LOGO)" # Kept rw so user software can change logos
        "-(rootfs)"
      ]
    }"
  ];

  build.firmwareUpgrade = pkgs.callPackage ./firmware-upgrade.nix {
    rootfs = config.build.TEMProotfs;
    # TODO have version be an option of the games os thingy
    version = "games-os-20220701.001";
    bootargs = builtins.concatStringsSep " " config.boot.cmdline;
  };

  nixpkgs.overlays = [
    (self: super: {
      SDL = self.callPackage ./pkgs/SDL { inherit (super) SDL; };
      miyooMiniSDK = self.callPackage ./pkgs/miyooMiniSDK { };
      miyooMiniAdditionalKernelModules = self.callPackage ./pkgs/miyooMiniAdditionalKernelModules { };
      games-os = super.games-os // {
        dotAppToMiniUIPak = self.callPackage ./pkgs/dotAppToMiniUIPak { };
      };
    })
  ];
}
