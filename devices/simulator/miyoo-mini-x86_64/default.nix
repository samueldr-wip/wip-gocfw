{ celunPath, config, lib, pkgs, ... }:

let
  inherit (config.device) nameForDerivation;
in
{
  imports = [
    (celunPath + "/devices/qemu/pc-x86_64")
  ];

  device = {
    name = lib.mkForce "simulator/miyoo-mini";
  };

  # Target device can't use an initramfs (currently)
  # Let's boot directly to rootfs then.
  wip.stage-1.enable = false;

  device.config.qemu = {
    memorySize = 128;
    qemuOptions = [
      # Resolution of the target device
      ''-device VGA,edid=on,xres=640,yres=480''

      ''-drive "file=${config.build.spiflash},format=raw,snapshot=on,index=0"''
      ''-drive "file=${config.build.sdcard  },format=raw,snapshot=on,index=1"''
    ];
  };

  boot.cmdline = [
    "root=/dev/sda" # ugh
    "rootfstype=squashfs"
    "ro"
  ];

  build.sdcard = (pkgs.celun.image-builder.evaluateDiskImage {
    config = {
      partitioningScheme = "gpt";
      partitions = [
        {
          name = "userdata";
          filesystem = {
            filesystem = "fat32";
            extraPadding = 1024 * 1024 * 10;
            populateCommands = ''
              mkdir -p system
              cp ${config.build.TEMProotfs} system/rootfs.img
            '';
          };
        }
      ];
    };
  }).config.output;

  build.spiflash = config.games-os.stub.output.squashfs;

  games-os.stub.userdataPartition = "/dev/sdb1";
}
