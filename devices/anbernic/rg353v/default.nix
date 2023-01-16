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
        name = "anbernic/rg353v";
        dtbFiles = [
          "rockchip/rk3566-rg353p-linux.dtb"
          "rockchip/rk3566-rg353v-linux.dtb"
        ];
      };

      hardware = {
        cpu = "rockchip-rk3566";
      };

      wip.gocfw.device-information = {
        display = { width = 640; height = 480; };
        input.buttons = {
          menu.available = true;
          reset.available = true;
          power.type = "soft";
          power.held-action = "userspace";
          volume.type = "buttons";
        };
        storage = {
          built-in = {
            type = "emmc";
            size = 16 * 1024 * 1024 * 1024;
          };
          external = {
            available = true;
            # See option documentation; technically bootable by SoC.
            bootable = true;
          };
          additional = {
            available = true;
          };
        };
      };

      # Target device uses initramfs.
      wip.stage-1.enable = true;
      wip.stage-1.cpio = config.games-os.stub.filesystem.output;

      wip.kernel.package = pkgs.callPackage ./kernel { };
      wip.kernel.defconfig = "rk3566_linux_defconfig";

      wip.kernel.isModular = true;
      wip.kernel.structuredConfig =
        with lib.kernel;
        let
          inherit (config.wip.kernel) features;
        in
        mkMerge [
          #{
          #  VT_CONSOLE = lib.mkForce yes;
          #}
          # TODO: define all required config options here.
        ]
      ;

      boot.cmdline = mkMerge [
        [
          # A high enough loglevel may be required for tty0 output
          # "loglevel=8"
          # XXX ttyUSB0 presence might be necessary to make tty0 output work
          "console=ttyUSB0,1500000"
          "console=tty0"
        ]
      ];

      # Partition three is forced, for now, by the vendor layout.
      games-os.stub.userdataPartition = "/dev/mmcblk1p3";
    }
  ];
}
