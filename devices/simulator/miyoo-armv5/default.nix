{ celunPath, config, lib, pkgs, ... }:

let
  inherit (config.device) nameForDerivation;
in
{
  imports = [
    (celunPath + "/devices/qemu/versatile-ARM9")
  ];

  device = {
    name = lib.mkForce "simulator/miyoo-armv5";
  };

  # Target device uses initramfs.
  wip.stage-1.enable = true;
  wip.stage-1.output.initramfs = config.games-os.stub.filesystem.output;

  device.config.qemu = {
    memorySize = 32;

    qemuOptions = [
      ''-drive if=scsi,driver=file,filename=${config.build.sdcard},snapshot=on''
    ];
  };

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

  games-os.stub.userdataPartition = "/dev/sda1";

  nixpkgs.overlays = [
    (self: super: {
      SDL = self.callPackage ../../powkiddy/v90/pkgs/SDL { inherit (super) SDL; };
    })
  ];
}
