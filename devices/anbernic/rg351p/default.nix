{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkMerge
  ;
in
{
  imports = [
    ./disk-image.nix
  ];

  config = mkMerge [
    {
      device = {
        name = "anbernic/rg351p";
        dtbFiles = [
          "rockchip/rk3326-rg351p-linux.dtb"
        ];
      };

      hardware = {
        cpu = "rockchip-rk3326";
      };

      # Target device uses initramfs.
      wip.stage-1.enable = true;
      wip.stage-1.cpio = config.games-os.stub.filesystem.output;

      wip.kernel.package = pkgs.callPackage ./kernel { };
      wip.kernel.defconfig = "rg351p_defconfig";

      wip.kernel.isModular = true;
      wip.kernel.structuredConfig =
        with lib.kernel;
        let
          inherit (config.wip.kernel) features;
        in
        mkMerge [
          # Not available as options in the older kernel used here
          {
            MEMFD_CREATE = lib.mkForce no;
            POSIX_TIMERS = lib.mkForce no;
          }
          {
            # FIXME: re-test without those set, and figure out which caused the kernel not to boot.
            SERIAL_AMBA_PL011 = lib.mkForce no;
            SERIAL_AMBA_PL011_CONSOLE = lib.mkForce no;
            VT_CONSOLE = lib.mkForce yes;
            LOGO = lib.mkForce no;
            TTY_PRINTK = lib.mkForce no;
            PROC_CHILDREN = lib.mkForce no;
            RD_BZIP2 = lib.mkForce yes;
            RD_GZIP = lib.mkForce yes;
            RD_LZ4 = lib.mkForce yes;
            RD_LZMA = lib.mkForce yes;
            RD_LZO = lib.mkForce yes;
            RD_XZ = lib.mkForce yes;

          }
          # TODO: define all required config options here.
        ]
      ;

      boot.cmdline = mkMerge [
        [
          "fbcon=rotate:3"
          "console=tty0"
        ]
      ];

      # NOTE: we could store everything on the first partition, as long as FAT32 is fine.
      #       and having `boot.ini` at the root is fine too...
      games-os.stub.userdataPartition = "/dev/mmcblk0p1";
    }
    {
      nixpkgs.overlays = [
        (final: super: {
          librga = final.callPackage ./pkgs/librga { };
        })
      ];
    }
  ];
}
